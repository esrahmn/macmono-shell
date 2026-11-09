#!/usr/bin/env bash
state="$HOME/.local/state/macmono"
mkdir -p "$state"

p() { playerctl "$@" 2>/dev/null; }
clip() { local s="$1" n="$2"; [ "${#s}" -gt "$n" ] && s="${s:0:$((n - 1))}…"; printf '%s' "$s"; }
esc() { local s="$1"; s="${s//&/&amp;}"; s="${s//</&lt;}"; printf '%s' "${s//>/&gt;}"; }
fmt() { printf '%d:%02d' $(($1 / 60)) $(($1 % 60)); }

case "${1:-title}" in
title)
    t="$(p metadata title)"
    [ -z "$t" ] && t="Nothing playing"
    echo "<span font_weight='700'>$(esc "$(clip "$t" 26)")</span>"
    ;;
artist)
    a="$(p metadata artist)"
    [ -z "$a" ] && a="$(p metadata album)"
    esc "$(clip "$a" 30)"
    echo
    ;;
bar)
    [ -z "$(p status)" ] && exit 0
    pos="$(p position)"; pos="${pos%.*}"; pos="${pos:-0}"
    len="$(p metadata mpris:length)"; len=$((${len:-0} / 1000000))
    n=16
    k=0
    [ "$len" -gt 0 ] && k=$((pos * n / len))
    [ "$k" -ge "$n" ] && k=$((n - 1))
    bar=""
    for ((i = 0; i < n; i++)); do
        if [ "$i" -lt "$k" ]; then bar+="━"
        elif [ "$i" -eq "$k" ]; then bar+="●"
        else bar+="─"
        fi
    done
    printf '%s  %s  %s\n' "$(fmt "$pos")" "$bar" "$(fmt "$len")"
    ;;
art)
    none="$state/lock-art-none.png"
    M="$(command -v magick || command -v convert)"
    if [ ! -s "$none" ] && [ -n "$M" ]; then
        "$M" -size 256x256 gradient:'#5c5c5c-#1c1c1c' "$none" 2>/dev/null
    fi

    url="$(p metadata mpris:artUrl)"
    [ -z "$url" ] && { echo "$none"; exit 0; }

    mono="${MACMONO_MONO:-1}"
    key="$(printf '%s|%s' "$url" "$mono" | md5sum | cut -c1-12)"
    out="$state/lock-art-$key.png"

    if [ ! -s "$out" ]; then
        raw="$state/lock-art-raw"
        rm -f "$raw" "$raw.part"
        case "$url" in
        file://*)
            path="${url#file://}"
            cp "$(printf '%b' "${path//%/\\x}")" "$raw" 2>/dev/null
            ;;
        http://* | https://*)
            curl -fsSL -m 4 -o "$raw.part" "$url" 2>/dev/null && mv "$raw.part" "$raw"
            ;;
        esac
        if [ -s "$raw" ]; then
            if [ -n "$M" ]; then
                gray=()
                [ "$mono" = 0 ] || gray=(-colorspace Gray)
                "$M" "$raw" -resize 256x256^ -gravity center -extent 256x256 "${gray[@]}" "png:$out.part" 2>/dev/null \
                    && mv "$out.part" "$out"
                rm -f "$out.part"
            else
                cp "$raw" "$out"
            fi
        fi
        rm -f "$raw"
    fi

    if [ -s "$out" ]; then
        find "$state" -maxdepth 1 -name 'lock-art-*.png' ! -name "lock-art-$key.png" ! -name 'lock-art-none.png' -delete 2>/dev/null
        echo "$out"
    else
        echo "$none"
    fi
    ;;
esac
