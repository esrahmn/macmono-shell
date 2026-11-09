import QtQuick
import "../../../core"
import "../../../shared/components"

// Pratinjau halaman Location & Weather: miniatur kartu cuaca di Calendar (ikon, suhu sekarang, kondisi).
// Data dari Sys.weather (WeatherService). Berubah ganti kota atau satuan, karena service mengambil ulang
// otomatis. Kartu cuma muncul kalau lokasi sudah dipilih (diatur lewat `visible` di SettingsPanel).
Rectangle {
    id: root
    readonly property var svc: Sys.weather
    readonly property bool ready: svc.available
    readonly property bool failed: !ready && !svc.loading && svc.error !== ""

    // Hari ini = indeks 0 (forecast_days=5, timezone=auto)
    readonly property var today: svc.daily.length > 0 ? svc.daily[0] : null
    readonly property string detail: {
        if (!ready) return "";
        let t = "Feels like " + Math.round(svc.current.feels) + "°";
        if (today) t += "  ·  H " + Math.round(today.max) + "°  L " + Math.round(today.min) + "°";
        return t;
    }
    readonly property string headline: ready ? svc.describe(svc.current.code)
        : (svc.loading ? "Updating…" : (failed ? svc.error : "No data yet"))

    height: Theme.settingsWeatherHeight
    radius: Theme.radiusCard
    color: Theme.tile
    border.width: Theme.borderThin
    border.color: Theme.cardStroke

    // Buka halaman -> pastikan data segar. ensureFresh() menghormati cache (cacheMin), jadi tidak
    // menembak jaringan berulang. Teks privasi di SettingsWeather menyebut ini.
    onVisibleChanged: if (visible) svc.ensureFresh()
    Component.onCompleted: if (visible) svc.ensureFresh()

    Row {
        x: Theme.settingsRowPadX
        anchors.verticalCenter: parent.verticalCenter
        spacing: Theme.space14

        Glyph {
            visible: root.ready
            anchors.verticalCenter: parent.verticalCenter
            width: Theme.settingsWeatherIcon
            height: width
            name: root.ready ? root.svc.iconFor(root.svc.current.code, root.svc.current.isDay) : ""
            color: Theme.text
        }

        SettingsText {
            anchors.verticalCenter: parent.verticalCenter
            text: root.ready ? Math.round(root.svc.current.temp) + "°" : "–"
            color: root.ready ? Theme.text : Theme.muted
            font.pixelSize: Theme.settingsWeatherTempSize
            font.weight: Font.DemiBold
            font.letterSpacing: Theme.settingsWeatherTempTracking
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter
            spacing: Theme.space2
            SettingsText {
                text: root.headline
                color: root.ready ? Theme.text : Theme.dim
                font.pixelSize: Theme.fontTitle
                font.weight: Font.Medium
            }
            SettingsText {
                visible: root.ready
                text: root.detail
                color: Theme.dim
                font.pixelSize: Theme.fontBody
            }
        }
    }

    // Gagal ambil data (offline / respons rusak): satu aksi, coba lagi.
    SettingsButton {
        visible: root.failed
        anchors { right: parent.right; rightMargin: Theme.settingsRowPadX; verticalCenter: parent.verticalCenter }
        label: "Retry"
        onClicked: root.svc.refresh()
    }
}
