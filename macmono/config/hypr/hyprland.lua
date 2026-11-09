-- Entry point config Hyprland (macmono).
-- Default ada di folder `hyprland/`. Tambahan pribadi taruh di `custom/` (opsional).

-- Internal --
require("hyprland.lib")

-- Environment variables --
require("hyprland.env")
if is_file_exists(HOME .. "/.config/hypr/custom/env.lua") then
    require("custom.env")
end

-- Default configurations --
require("hyprland.execs")
require("hyprland.general")
require("hyprland.rules")
require("hyprland.colors")
require("hyprland.keybinds")

-- Custom configurations --
if is_file_exists(HOME .. "/.config/hypr/custom/execs.lua") then
    require("custom.execs")
end
if is_file_exists(HOME .. "/.config/hypr/custom/general.lua") then
    require("custom.general")
end
if is_file_exists(HOME .. "/.config/hypr/custom/rules.lua") then
    require("custom.rules")
end
if is_file_exists(HOME .. "/.config/hypr/custom/keybinds.lua") then
    require("custom.keybinds")
end

-- HyprMod managed settings
require("hyprland-gui")

-- macmono Settings > Display menulis file ini (paling akhir supaya menimpa setelan monitor lain)
if is_file_exists(HOME .. "/.config/hypr/custom/macmono-generated.lua") then
    require("custom.macmono-generated")
end

-- macmono Settings > Input menulis blok "input" di file yang sama (macmono-generated.lua),
-- jadi nggak ada file generated kedua. Ini paling akhir: menimpa input lain termasuk HyprMod.
-- (Blok itu sudah ikut ke-load oleh require("custom.macmono-generated") di atas.)
