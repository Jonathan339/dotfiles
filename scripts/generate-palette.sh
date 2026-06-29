#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# generate-palette.sh
# Regenera config/colors/{kitty-colors.conf,alacritty-colors.toml}
# desde config/colors/palette.sh (fuente única).
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
PALETTE="$REPO_ROOT/config/colors/palette.sh"
KITTY_OUT="$REPO_ROOT/config/colors/kitty-colors.conf"
ALACRITTY_OUT="$REPO_ROOT/config/colors/alacritty-colors.toml"

[[ -f "$PALETTE" ]] || { echo "No existe: $PALETTE"; exit 1; }

source "$PALETTE"

cat > "$KITTY_OUT" <<EOF
# ==============================================================================
# Solo Leveling Palette — Kitty (generado por scripts/generate-palette.sh)
# Source of truth: config/colors/palette.sh
# ==============================================================================

foreground            $PALETTE_FG
background            $PALETTE_BG
cursor                $PALETTE_CURSOR
selection_background  $PALETTE_SEL_BG
selection_foreground  $PALETTE_SEL_FG

color0  $PALETTE_COLOR0
color1  $PALETTE_COLOR1
color2  $PALETTE_COLOR2
color3  $PALETTE_COLOR3
color4  $PALETTE_COLOR4
color5  $PALETTE_COLOR5
color6  $PALETTE_COLOR6
color7  $PALETTE_COLOR7
color8  $PALETTE_COLOR8
color9  $PALETTE_COLOR9
color10 $PALETTE_COLOR10
color11 $PALETTE_COLOR11
color12 $PALETTE_COLOR12
color13 $PALETTE_COLOR13
color14 $PALETTE_COLOR14
color15 $PALETTE_COLOR15
EOF

cat > "$ALACRITTY_OUT" <<EOF
# ==============================================================================
# Solo Leveling Palette — Alacritty (generado por scripts/generate-palette.sh)
# Source of truth: config/colors/palette.sh
# ==============================================================================

[colors.primary]
background = "$PALETTE_BG"
foreground = "$PALETTE_FG"

[colors.cursor]
text = "$PALETTE_BG"
cursor = "$PALETTE_CURSOR"

[colors.selection]
text = "$PALETTE_SEL_FG"
background = "$PALETTE_SEL_BG"

[colors.normal]
black = "$PALETTE_COLOR0"
red = "$PALETTE_COLOR1"
green = "$PALETTE_COLOR2"
yellow = "$PALETTE_COLOR3"
blue = "$PALETTE_COLOR4"
magenta = "$PALETTE_COLOR5"
cyan = "$PALETTE_COLOR6"
white = "$PALETTE_COLOR7"

[colors.bright]
black = "$PALETTE_COLOR8"
red = "$PALETTE_COLOR9"
green = "$PALETTE_COLOR10"
yellow = "$PALETTE_COLOR11"
blue = "$PALETTE_COLOR12"
magenta = "$PALETTE_COLOR13"
cyan = "$PALETTE_COLOR14"
white = "$PALETTE_COLOR15"
EOF

echo "Regenerado:"
echo "  $KITTY_OUT"
echo "  $ALACRITTY_OUT"
