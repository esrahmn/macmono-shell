import Quickshell

// Satu-satunya tempat menyimpan state kecil shell ke ~/.local/state/macmono/.
// Sebelumnya perintah shell-nya diduplikasi di core/Sys.qml dan services/WallpaperService.qml,
// jadi rawan berubah di satu tempat tapi ketinggalan di tempat lain.
//
// Ditulis lewat argv (bukan string yang dirangkai), jadi nama state maupun nilainya
// tidak pernah masuk ke teks perintah.
Scope {
    id: root

    readonly property string dir: Quickshell.env("HOME") + "/.local/state/macmono"

    function save(name, value) {
        Quickshell.execDetached(["sh", "-c",
            "mkdir -p \"$HOME/.local/state/macmono\" && printf '%s' \"$2\" > \"$HOME/.local/state/macmono/$1\"",
            "sh", name, String(value)]);
    }
}
