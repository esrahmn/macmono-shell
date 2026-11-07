pragma Singleton

import QtQuick
import Quickshell   // `Singleton {}` (root object) berasal dari modul Quickshell, bukan QtQuick

// Satu-satunya sumber daftar pintasan keyboard macmono.
// Dipakai dua tempat: Cheatsheet (Super+/) dan halaman "Keyboard Shortcuts" di Pengaturan.
// Dulu tabelnya cuma hidup di Cheatsheet; kalau ditulis ulang di Pengaturan, dua daftar
// pasti mulai berbeda. Komentar keybind sebenarnya ada di config Hypr (keybinds.lua),
// jadi kalau menambah bind baru, tambahkan satu baris di sini juga.
//
// Format tiap baris: [ "Modifier + Tombol", "Keterangan" ]
Singleton {
    readonly property var groups: [
        { title: "Shell", items: [
            ["Super", "Launcher & overview"], ["Super + Tab", "Overview"], ["Super + V", "Clipboard"],
            ["Super + .", "Emoji"], ["Super + N", "Control Center"], ["Super + A", "Calendar & notifications"],
            ["Super + M", "Media controls"], ["Super + /", "This cheatsheet"], ["Super + J", "Toggle bar"],
            ["Ctrl + Alt + Del", "Power menu"], ["Ctrl + Super + T", "Wallpaper picker"],
            ["Ctrl + Super + Alt + T", "Random wallpaper"], ["Ctrl + Super + R", "Restart shell"] ] },
        { title: "Capture", items: [
            ["Super + Shift + S", "Screenshot area"], ["Print", "Screenshot full screen"],
            ["Super + Shift + X", "Copy text (OCR)"],
            ["Super + Shift + C", "Color picker"] ] },
        { title: "Windows", items: [
            ["Super + Q", "Close window"], ["Super + F", "Fullscreen"], ["Super + D", "Maximize"],
            ["Super + Alt + Space", "Float / tile"], ["Super + P", "Pin"], ["Super + Arrows", "Move focus"],
            ["Super + Shift + Arrows", "Move window"], ["Super + Drag", "Move (left) / resize (right)"] ] },
        { title: "Workspaces", items: [
            ["Super + 1…0", "Go to workspace"], ["Super + Alt + 1…0", "Send window to workspace"],
            ["Ctrl + Super + ← / →", "Previous / next workspace"], ["Super + S", "Scratchpad"] ] },
        { title: "Apps & session", items: [
            ["Super + Enter", "Terminal"], ["Super + E", "Files"], ["Super + W", "Browser"],
            ["Super + C", "Code editor"], ["Super + I", "Settings"], ["Ctrl + Shift + Esc", "Task manager"],
            ["Super + L", "Lock"], ["Super + Shift + L", "Sleep"] ] },
        { title: "Media", items: [
            ["Super + Shift + P", "Play / pause"], ["Super + Shift + N", "Next track"],
            ["Super + Shift + B", "Previous track"], ["Super + Shift + M", "Mute speaker"],
            ["Super + Alt + M", "Mute microphone"] ] }
    ]
}
