import QtQuick
import "../../../core"

// Pratinjau Night Light: dua potongan wallpaper, "Normal" dan "Night Light", diberi warna sesuai
// nilai Kelvin di draft. Hanya perkiraan warna; layar asli diatur hyprsunset.
// Dipasang tepat di atas grup "Night Light" lewat `preview: "night"` di SettingsSchema; tanpa judul sendiri,
// karena label grup sudah ada tepat di atasnya.
Column {
    id: root
    property int warmKelvin: 4200
    property int normalKelvin: 6500
    property bool active: false
    spacing: Theme.space8
    // Keterangan di bawah gambar bukan kartu (tanpa latar), jadi butuh jarak ekstra ke baris toggle di bawahnya.
    bottomPadding: Theme.space12

    // Perkiraan warna cahaya dari suhu Kelvin (rumus umum Tanner Helland)
    function tint(k, alpha) {
        const t = k / 100;
        const c = v => Math.max(0, Math.min(255, v)) / 255;
        const r = t <= 66 ? 255 : 329.698727446 * Math.pow(t - 60, -0.1332047592);
        const g = t <= 66 ? 99.4708025861 * Math.log(t) - 161.1195681661 : 288.1221695283 * Math.pow(t - 60, -0.0755148492);
        const b = t >= 66 ? 255 : (t <= 19 ? 0 : 138.5177312231 * Math.log(t - 10) - 305.0447927307);
        return Qt.rgba(c(r), c(g), c(b), alpha);
    }
    // Makin jauh dari 6500 K, makin kuat warnanya (maksimum 0.5)
    function strength(k) { return Math.min(0.5, Math.abs(6500 - k) / 4000 * 0.5); }

    Row {
        spacing: Theme.space10

        Repeater {
            model: [
                { label: "Normal", kelvin: root.normalKelvin, on: false },
                { label: "Night Light", kelvin: root.warmKelvin, on: true }
            ]
            delegate: Column {
                id: half
                required property var modelData
                readonly property bool lit: modelData.on === root.active
                width: (root.width - Theme.space10) / 2
                spacing: Theme.space6

                Item {
                    width: parent.width
                    height: Theme.settingsNightHeight
                    SettingsWallpaperImage { anchors.fill: parent; path: Sys.wallpaper; cornerRadius: Theme.radiusCard }
                    Rectangle { anchors.fill: parent; radius: Theme.radiusCard; color: root.tint(half.modelData.kelvin, root.strength(half.modelData.kelvin)) }
                    Rectangle {
                        anchors.fill: parent
                        radius: Theme.radiusCard
                        color: Theme.transparent
                        border.width: half.lit ? Theme.borderStrong : Theme.borderThin
                        border.color: half.lit ? Theme.text : Theme.cardStroke
                    }
                }
                SettingsText {
                    text: half.modelData.label + "  ·  " + half.modelData.kelvin + " K" + (half.lit ? "  ·  now" : "")
                    color: half.lit ? Theme.text : Theme.dim
                    font.pixelSize: Theme.fontBody
                    font.weight: half.lit ? Font.DemiBold : Font.Normal
                    leftPadding: Theme.space2
                }
            }
        }
    }
}
