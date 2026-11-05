pragma Singleton

import QtQuick
import Quickshell

// Pengaturan cepat macmono. Edit sesuka lu, lalu Ctrl+Super+R.
Singleton {
    // ---- overview workspace di launcher ----
    readonly property int overviewRows: 2
    readonly property int overviewColumns: 5         // 2 x 5 = workspace 1-10 (ikut grup 10 end4)
    readonly property real overviewScale: 0.11        // ukuran workspace relatif ke layar (launcher desain A: overview ringkas)
    readonly property bool overviewLivePreview: true  // false = cuma ikon app (lebih ringan)

    // ---- launcher ----
    readonly property int launcherMaxResults: 9   // maks. app di daftar hasil (Windows, Actions, dan Top Hit nggak dibatasi)
    // app di baris "Pinned" launcher: nama file .desktop tanpa ".desktop" (atau nama app, ditebak otomatis)
    readonly property var pinnedApps: ["kitty", "google-chrome", "spotify", "org.kde.dolphin", "discord", "steam", "com.microsoft.VSCode", "com.obsproject.Studio"]

    // ---- clipboard ----
    readonly property int clipboardMaxItems: 200
}
