#!/usr/bin/env python3
"""Turn Iconify icons into path data for Glyph.qml.

  python3 scripts/development/fetch-icons.py              # fetch from api.iconify.design
  python3 scripts/development/fetch-icons.py --file lucide=lucide.json   # use a downloaded IconifyJSON file

Reads scripts/development/icons.json and writes shared/components/GlyphPaths.js.
The API is only used here, never at runtime: the result is plain data kept in the repo.
Icons that are missing or use SVG features we do not convert (transforms, opacity, mixed
fill/stroke) are listed at the end and stay on the old canvas drawing.
Check the licence of every icon set you use (Iconify shows it on each set's page).
Python 3 standard library only.
"""
import argparse
import json
import math
import re
import sys
import urllib.error
import urllib.request
import xml.etree.ElementTree as ET
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
MAP_FILE = ROOT / "scripts/development/icons.json"
OUT_FILE = ROOT / "shared/components/GlyphPaths.js"
API = "https://api.iconify.design"
CHUNK = 40


class Unsupported(Exception):
    pass


def num(v):
    s = f"{v:.3f}".rstrip("0").rstrip(".")
    return "0" if s in ("", "-0") else s


def f(attr, default=0.0):
    if attr is None:
        return default
    m = re.match(r"\s*([-+]?(?:\d+\.?\d*|\.\d+)(?:[eE][-+]?\d+)?)", attr)
    if not m:
        raise Unsupported(f"bad number '{attr}'")
    return float(m.group(1))


def numbers(s):
    return [float(x) for x in re.findall(r"[-+]?(?:\d+\.?\d*|\.\d+)(?:[eE][-+]?\d+)?", s or "")]


def ellipse(cx, cy, rx, ry):
    return (f"M{num(cx - rx)} {num(cy)}"
            f"a{num(rx)} {num(ry)} 0 1 0 {num(2 * rx)} 0"
            f"a{num(rx)} {num(ry)} 0 1 0 {num(-2 * rx)} 0z")


def rect(a):
    x, y, w, h = f(a.get("x")), f(a.get("y")), f(a.get("width")), f(a.get("height"))
    rx = f(a.get("rx"), None) if a.get("rx") is not None else None
    ry = f(a.get("ry"), None) if a.get("ry") is not None else None
    if rx is None and ry is None:
        rx = ry = 0.0
    elif rx is None:
        rx = ry
    elif ry is None:
        ry = rx
    rx, ry = min(rx, w / 2), min(ry, h / 2)
    if rx <= 0 or ry <= 0:
        return f"M{num(x)} {num(y)}h{num(w)}v{num(h)}h{num(-w)}z"
    return (f"M{num(x + rx)} {num(y)}h{num(w - 2 * rx)}"
            f"a{num(rx)} {num(ry)} 0 0 1 {num(rx)} {num(ry)}v{num(h - 2 * ry)}"
            f"a{num(rx)} {num(ry)} 0 0 1 {num(-rx)} {num(ry)}h{num(-(w - 2 * rx))}"
            f"a{num(rx)} {num(ry)} 0 0 1 {num(-rx)} {num(-ry)}v{num(-(h - 2 * ry))}"
            f"a{num(rx)} {num(ry)} 0 0 1 {num(rx)} {num(-ry)}z")


def shape_to_path(tag, a):
    if tag == "path":
        d = a.get("d")
        if not d:
            raise Unsupported("empty path")
        return d.strip()
    if tag == "circle":
        r = f(a.get("r"))
        return ellipse(f(a.get("cx")), f(a.get("cy")), r, r)
    if tag == "ellipse":
        return ellipse(f(a.get("cx")), f(a.get("cy")), f(a.get("rx")), f(a.get("ry")))
    if tag == "rect":
        return rect(a)
    if tag == "line":
        return f"M{num(f(a.get('x1')))} {num(f(a.get('y1')))}L{num(f(a.get('x2')))} {num(f(a.get('y2')))}"
    if tag in ("polyline", "polygon"):
        p = numbers(a.get("points"))
        if len(p) < 4 or len(p) % 2:
            raise Unsupported("bad points")
        d = "M" + num(p[0]) + " " + num(p[1]) + "".join(f"L{num(p[i])} {num(p[i + 1])}" for i in range(2, len(p), 2))
        return d + ("z" if tag == "polygon" else "")
    raise Unsupported(f"<{tag}>")


def convert(body):
    """IconifyJSON body -> (path data, mode). mode: 'stroke' or 'fill'."""
    root = ET.fromstring('<svg xmlns="http://www.w3.org/2000/svg">' + body + "</svg>")
    parts, kinds = [], set()

    def walk(el, st):
        st = dict(st)
        a = el.attrib
        if "transform" in a:
            raise Unsupported("transform")
        for k in ("opacity", "fill-opacity", "stroke-opacity"):
            if k in a and f(a[k]) < 1:
                raise Unsupported("opacity")
        for k in ("fill", "stroke"):
            if k in a:
                st[k] = a[k]
        tag = el.tag.split("}")[-1]
        if tag == "g":
            for c in el:
                walk(c, st)
            return
        parts.append(shape_to_path(tag, a))
        stroked = st.get("stroke", "none") != "none"
        filled = st.get("fill", "currentColor" if not stroked else "none") != "none"
        kinds.add("stroke" if stroked and not filled else "fill" if filled and not stroked else "mixed")

    for el in root:
        walk(el, {})
    if not parts:
        raise Unsupported("empty")
    if kinds != {"stroke"} and kinds != {"fill"}:
        raise Unsupported("mixed fill and stroke")
    return "".join(parts), kinds.pop()


def load_set(prefix, ids, files):
    if prefix in files:
        return json.loads(Path(files[prefix]).read_text())
    icons, aliases, size = {}, {}, 24
    for i in range(0, len(ids), CHUNK):
        url = f"{API}/{prefix}.json?icons={','.join(ids[i:i + CHUNK])}"
        req = urllib.request.Request(url, headers={"User-Agent": "macmono-fetch-icons"})
        try:
            with urllib.request.urlopen(req, timeout=20) as r:
                data = json.load(r)
        except (urllib.error.URLError, OSError) as e:
            sys.exit(f"Could not reach {url}\n  {e}\n  (no internet? use --file {prefix}=<IconifyJSON file>)")
        icons.update(data.get("icons", {}))
        aliases.update(data.get("aliases", {}))
        size = data.get("width", size)
    return {"icons": icons, "aliases": aliases, "width": size, "height": size}


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--file", action="append", default=[], metavar="PREFIX=PATH",
                    help="use a local IconifyJSON file for a set instead of the API")
    args = ap.parse_args()
    files = dict(x.split("=", 1) for x in args.file)

    cfg = json.loads(MAP_FILE.read_text())
    default_set = cfg.get("set", "lucide")
    wanted = {}   # glyph -> (prefix, id, fill)
    for glyph, v in cfg["icons"].items():
        fill = False
        if isinstance(v, dict):
            fill, v = bool(v.get("fill")), v["id"]
        prefix, _, icon_id = v.rpartition(":")
        wanted[glyph] = (prefix or default_set, icon_id, fill)

    sets = {}
    for prefix in sorted({p for p, _, _ in wanted.values()}):
        ids = sorted({i for p, i, _ in wanted.values() if p == prefix})
        sets[prefix] = load_set(prefix, ids, files)

    out, missing, skipped = {}, [], []
    for glyph, (prefix, icon_id, fill) in sorted(wanted.items()):
        s = sets[prefix]
        entry = s.get("icons", {}).get(icon_id)
        if entry is None and icon_id in s.get("aliases", {}):
            al = s["aliases"][icon_id]
            if any(k in al for k in ("rotate", "hFlip", "vFlip", "body")):
                skipped.append((glyph, "alias with transform"))
                continue
            entry = s.get("icons", {}).get(al.get("parent"))
        if entry is None or "body" not in entry:
            missing.append(f"{glyph} ({prefix}:{icon_id})")
            continue
        try:
            d, mode = convert(entry["body"])
        except (Unsupported, ET.ParseError) as e:
            skipped.append((glyph, str(e)))
            continue
        w = entry.get("width", s.get("width", 24))
        h = entry.get("height", s.get("height", w))
        if w != h:
            skipped.append((glyph, f"not square ({w}x{h})"))
            continue
        if fill and mode == "stroke":
            mode = "both"
        out[glyph] = {"d": d, "w": w, "mode": mode}

    lines = [".pragma library",
             "// Vector icon data for Glyph.qml. Generated by scripts/development/fetch-icons.py: do not edit by hand.",
             "// While an icon is missing here, Glyph falls back to the old canvas drawing (GlyphLegacy.qml).",
             "// mode: stroke = outline drawn with Glyph.thickness, fill = solid shape, both = outline + fill.",
             "var paths = {"]
    items = sorted(out.items())
    for n, (glyph, e) in enumerate(items):
        comma = "," if n < len(items) - 1 else ""
        lines.append(f'    {json.dumps(glyph)}: {{ d: {json.dumps(e["d"])}, w: {e["w"]}, mode: "{e["mode"]}" }}{comma}')
    lines.append("}")
    OUT_FILE.write_text("\n".join(lines) + "\n")

    print(f"wrote {len(out)} icons to {OUT_FILE.relative_to(ROOT)}")
    if missing:
        print(f"not found in the set ({len(missing)}): " + ", ".join(missing))
    if skipped:
        print(f"not converted ({len(skipped)}): " + ", ".join(f"{g} [{why}]" for g, why in skipped))
    if missing or skipped:
        print("Those stay on the old canvas drawing. Fix the id in icons.json or leave them.")


if __name__ == "__main__":
    main()
