-- Hyprland 0.57 — configuración portada desde los dotfiles (adaptada de Omarchy)
-- Archivos de origen: monitors.conf, input.conf, bindings.conf, looknfeel.conf,
-- autostart.conf y windowrules.conf (se conservan como referencia).

------------------
---- MONITORES ----
------------------

hl.monitor({
    output   = "",
    mode     = "preferred",
    position = "auto",
    scale    = 1,
})

hl.env("GDK_SCALE", "1")

------------------
---- AUTOSTART ----
------------------

hl.on("hyprland.start", function()
    hl.exec_cmd("hyprctl setcursor default 24")
    hl.exec_cmd("systemctl --user import-environment DISPLAY WAYLAND_DISPLAY HYPRLAND_INSTANCE_SIGNATURE")
    hl.exec_cmd("dbus-update-activation-environment --systemd --all")

    -- Agente de autenticación (apagar, reiniciar, suspender)
    hl.exec_cmd([[sh -c 'systemctl --user import-environment DISPLAY WAYLAND_DISPLAY; systemctl --user start hyprpolkitagent']])

    -- Barra
    hl.exec_cmd("waybar")

    -- Fondo: el elegido con SUPER+CTRL+ESPACIO, o el primero de ~/Imágenes/wallpapers
    hl.exec_cmd([[sh -c 'if [ -f ~/.local/state/hypr/wallpaper ]; then swaybg -i "$(cat ~/.local/state/hypr/wallpaper)" -m fill; else f=$(find ~/Imágenes/wallpapers -type f \( -iname "*.jpg" -o -iname "*.png" -o -iname "*.webp" \) | head -1); [ -n "$f" ] && swaybg -i "$f" -m fill; fi']])

    -- Idle / lock
    hl.exec_cmd("hypridle")

    -- Portapapeles
    hl.exec_cmd("wl-paste --type text --watch cliphist store")

    -- Notificaciones
    hl.exec_cmd("dunst")

    -- Utilidades de los dotfiles
    hl.exec_cmd("hypr-compact")
    hl.exec_cmd("hypr-border")
end)

---------------------------
---- ASPECTO Y COMPORTAMIENTO ----
---------------------------

hl.config({
    general = {
        gaps_in     = 1,
        gaps_out    = 3,
        border_size = 2,
        col = {
            active_border   = "rgba(00000000)",
            inactive_border = "rgba(595959aa)",
        },
        layout           = "dwindle",
        resize_on_border = false,
    },

    decoration = {
        rounding = 0,
        shadow   = { enabled = true },
        blur     = { enabled = false },
    },

    group = {
        col = {
            border_active   = "rgba(00000000)",
            border_inactive = "rgba(595959aa)",
        },
        groupbar = {
            font_size       = 12,
            font_family     = "monospace",
            indicator_height = 1,
            indicator_gap   = 5,
            height          = 22,
            gaps_in         = 5,
            gaps_out        = 0,
            text_color         = "rgb(ffffff)",
            text_color_inactive = "rgba(ffffff90)",
            col = {
                active   = "rgba(00000040)",
                inactive = "rgba(00000020)",
            },
            gradients               = true,
            gradient_rounding       = 0,
            gradient_round_only_edges = false,
        },
    },

    animations = {
        enabled = true,
    },

    -- En 0.57 ya no existe dwindle.pseudotile global; SUPER+P togglea
    -- el seudotile por ventana con hl.dsp.window.pseudo().
    dwindle = {
        preserve_split = true,
    },

    misc = {
        disable_autoreload            = false,
        disable_hyprland_guiutils_check = true,
    },

    input = {
        kb_layout         = "latam",
        repeat_rate       = 40,
        repeat_delay      = 250,
        numlock_by_default = true,
        touchpad = {
            natural_scroll       = true,
            clickfinger_behavior = true,
            scroll_factor        = 0.4,
            disable_while_typing = false,
        },
    },

    gestures = {
        workspace_swipe_touch = true,
    },
})

-- Curvas y animaciones (equivalente a bezier/animation del config anterior)
hl.curve("easeOutQuint",   { type = "bezier", points = { {0.23, 1},   {0.32, 1} } })
hl.curve("easeInOutCubic", { type = "bezier", points = { {0.65, 0.05}, {0.36, 1} } })
hl.curve("almostLinear",   { type = "bezier", points = { {0.5, 0.5},   {0.75, 1.0} } })

hl.animation({ leaf = "global",     enabled = true, speed = 10, bezier = "default" })
hl.animation({ leaf = "windows",    enabled = true, speed = 5,  bezier = "easeOutQuint" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 5,  bezier = "easeOutQuint" })
hl.animation({ leaf = "fade",       enabled = true, speed = 5,  bezier = "almostLinear" })
hl.animation({ leaf = "border",     enabled = true, speed = 5,  bezier = "easeInOutCubic" })

----------------
---- ATAJOS  ----
----------------

local mainMod = "SUPER"

-- Aplicaciones
hl.bind(mainMod .. " + RETURN",           hl.dsp.exec_cmd("kitty"))
hl.bind(mainMod .. " + SHIFT + RETURN",   hl.dsp.exec_cmd("google-chrome"))
hl.bind(mainMod .. " + SHIFT + F",        hl.dsp.exec_cmd("dolphin"))
hl.bind(mainMod .. " + SHIFT + N",        hl.dsp.exec_cmd("kitty -e nvim"))
hl.bind(mainMod .. " + SPACE",            hl.dsp.exec_cmd("rofi -show drun"))
hl.bind("ALT + SPACE",                    hl.dsp.exec_cmd("rofi -show drun"))
hl.bind(mainMod .. " + CTRL + SPACE",     hl.dsp.exec_cmd("hypr-wallpaper"))

-- Utilidades
hl.bind(mainMod .. " + ESCAPE", hl.dsp.exec_cmd("hypr-power"))
hl.bind(mainMod .. " + SHIFT + Q", hl.dsp.exec_cmd("hypr-power"))
hl.bind(mainMod .. " + K", hl.dsp.exec_cmd("rofi -show window"))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.exec_cmd([[mkdir -p ~/Imágenes/Screenshots && grim -g "$(slurp)" - | wl-copy && wl-paste > ~/Imágenes/Screenshots/$(date +%Y%m%d-%H%M%S).png]]))
hl.bind(mainMod .. " + SHIFT + V", hl.dsp.exec_cmd("cliphist list | rofi -dmenu | cliphist decode | wl-copy"))
hl.bind(mainMod .. " + SHIFT + C", hl.dsp.exec_cmd("cliphist wipe"))

-- Tiling
hl.bind(mainMod .. " + Q", hl.dsp.window.close())
hl.bind(mainMod .. " + J", hl.dsp.layout("togglesplit"))
hl.bind(mainMod .. " + P", hl.dsp.window.pseudo())
hl.bind(mainMod .. " + T", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + SHIFT + I", hl.dsp.exec_cmd("hypr-bar-island"))
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen({ action = "toggle" }))
hl.bind(mainMod .. " + ALT + F", hl.dsp.window.fullscreen({ action = "toggle", mode = "maximized" }))
hl.bind(mainMod .. " + O", hl.dsp.window.float({ action = "toggle" }))

-- Foco y ventanas
hl.bind(mainMod .. " + LEFT",  hl.dsp.focus({ workspace = "e-1" }))
hl.bind(mainMod .. " + RIGHT", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + UP",    hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + DOWN",  hl.dsp.focus({ direction = "down" }))
hl.bind(mainMod .. " + SHIFT + LEFT",  hl.dsp.window.move({ workspace = "e-1" }))
hl.bind(mainMod .. " + SHIFT + RIGHT", hl.dsp.window.move({ workspace = "e+1" }))
hl.bind(mainMod .. " + SHIFT + UP",    hl.dsp.window.move({ direction = "up" }))
hl.bind(mainMod .. " + SHIFT + DOWN",  hl.dsp.window.move({ direction = "down" }))

-- Navegación adicional con teclado
hl.bind(mainMod .. " + TAB",         hl.dsp.window.cycle_next({}))
hl.bind(mainMod .. " + SHIFT + TAB", hl.dsp.window.cycle_next({ next = false }))
hl.bind(mainMod .. " + ALT + LEFT",  hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + ALT + RIGHT", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + CTRL + LEFT",  hl.dsp.window.resize({ x = -40, y = 0, relative = true }))
hl.bind(mainMod .. " + CTRL + RIGHT", hl.dsp.window.resize({ x = 40, y = 0, relative = true }))
hl.bind(mainMod .. " + CTRL + UP",    hl.dsp.window.resize({ x = 0, y = -40, relative = true }))
hl.bind(mainMod .. " + CTRL + DOWN",  hl.dsp.window.resize({ x = 0, y = 40, relative = true }))

-- Workspaces
for i = 1, 9 do
    hl.bind(mainMod .. " + " .. i,             hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT + " .. i,     hl.dsp.window.move({ workspace = i }))
    hl.bind("ALT + " .. i,                     hl.dsp.window.move({ workspace = i }))
end
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

-- Multimedia
hl.bind("XF86AudioRaiseVolume",   hl.dsp.exec_cmd("wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+"))
hl.bind("XF86AudioLowerVolume",   hl.dsp.exec_cmd("wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%-"))
hl.bind("XF86AudioMute",          hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"))
hl.bind("XF86AudioMicMute",       hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"))
hl.bind("XF86AudioPlay",          hl.dsp.exec_cmd("playerctl play-pause"))
hl.bind("XF86AudioPause",         hl.dsp.exec_cmd("playerctl play-pause"))
hl.bind("XF86AudioNext",          hl.dsp.exec_cmd("playerctl next"))
hl.bind("XF86AudioPrev",          hl.dsp.exec_cmd("playerctl previous"))
hl.bind("XF86MonBrightnessUp",    hl.dsp.exec_cmd("brightnessctl s +5%"))
hl.bind("XF86MonBrightnessDown",  hl.dsp.exec_cmd("brightnessctl s 5%-"))
hl.bind("XF86TouchpadToggle",     hl.dsp.exec_cmd("hyprctl keyword input:touchpad:enabled toggle"))

-- Portapapeles universal
hl.bind(mainMod .. " + C", hl.dsp.send_shortcut({ mods = "CONTROL", key = "C" }))
hl.bind(mainMod .. " + V", hl.dsp.send_shortcut({ mods = "CONTROL", key = "V" }))
hl.bind(mainMod .. " + X", hl.dsp.send_shortcut({ mods = "CONTROL", key = "X" }))

-----------------------------
---- REGLAS DE VENTANA  ----
-----------------------------

hl.window_rule({
    name  = "pavucontrol-flotante",
    match = { class = "pavucontrol" },
    float  = true,
    center = true,
})

hl.window_rule({
    name  = "blueman-flotante",
    match = { class = "blueman-manager" },
    float  = true,
    center = true,
})

hl.window_rule({
    name  = "zenity-flotante",
    match = { class = "zenity" },
    float  = true,
})


