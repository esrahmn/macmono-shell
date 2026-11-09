import Quickshell

Scope {
    id: root

    readonly property string dir: Quickshell.env("HOME") + "/.local/state/macmono"

    function save(name, value) {
        Quickshell.execDetached(["sh", "-c",
            "mkdir -p \"$HOME/.local/state/macmono\" && printf '%s' \"$2\" > \"$HOME/.local/state/macmono/$1\"",
            "sh", name, String(value)]);
    }
}
