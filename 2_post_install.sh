#!/usr/bin/env bash
# =========================================================================
#  Fase 2 - Personalización de hardware (Post-Caelestia)
# =========================================================================
# CORRECCIÓN IMPORTANTE respecto a la versión anterior:
#   El archivo ~/.config/hypr/user/settings.lua y el módulo
#   require("caelestia.settings") NO EXISTEN en el proyecto actual.
#   Nunca se debe escribir dentro de ~/.config/hypr/: eso rompe
#   `caelestia update` (el README lo dice explícitamente).
#
#   Los archivos reales que SÍ debes tocar son:
#     ~/.config/caelestia/hypr-vars.lua   -> overrides de variables propias
#                                             de Caelestia (apps por defecto,
#                                             keybinds, blur, bordes, etc.)
#     ~/.config/caelestia/hypr-user.lua   -> config Hyprland "cruda" tuya,
#                                             cargada al final del arranque
#                                             (aquí van monitor/input/touchpad)
#
#   IMPORTANTE sobre hypr-user.lua:
#   Hyprland 0.55+ (mayo 2026) añadió configuración nativa en Lua. Es muy
#   reciente, así que la sintaxis exacta de los bloques monitor{}/input{}
#   puede variar según tu versión instalada. Si el bloque de abajo no
#   carga, revisa la wiki oficial de Hyprland (sección "Lua configuration")
#   o usa `hyprctl monitors`/`hyprctl reload` para depurar, y ajusta la
#   sintaxis según lo que tengas instalado.
# =========================================================================
set -euo pipefail

CAEL_DIR="$HOME/.config/caelestia"

echo "======================================================="
echo "   Fase 2: Ajustes de Hardware (Monitor y Teclado)     "
echo "======================================================="

if [ ! -d "$CAEL_DIR" ]; then
  echo "Error: no se encontró $CAEL_DIR."
  echo "Asegúrate de haber ejecutado 'caelestia install' antes de usar este script."
  exit 1
fi

# --- Detectar el nombre real del monitor (mejor que asumir eDP-1) ---
MONITOR_NAME="eDP-1"
if command -v hyprctl &> /dev/null; then
    DETECTED=$(hyprctl monitors -j 2>/dev/null | grep -o '"name": *"[^"]*"' | head -1 | sed 's/.*"\(.*\)"$/\1/')
    [ -n "${DETECTED:-}" ] && MONITOR_NAME="$DETECTED"
fi
echo "Usando monitor detectado: $MONITOR_NAME (revísalo con: hyprctl monitors)"

# --- hypr-vars.lua: overrides oficiales de Caelestia --------------------
# Solo se agregan/actualizan las claves de este script; si ya tienes el
# archivo con otras personalizaciones, se hace un backup antes de tocarlo.
if [ -f "$CAEL_DIR/hypr-vars.lua" ]; then
    cp "$CAEL_DIR/hypr-vars.lua" "$CAEL_DIR/hypr-vars.lua.bak.$(date +%s)"
    echo "Backup de hypr-vars.lua existente creado."
fi

cat > "$CAEL_DIR/hypr-vars.lua" <<'EOF'
-- Overrides de variables de Caelestia.
-- Referencia completa de claves disponibles: hypr/variables.lua del repo
-- https://github.com/caelestia-dots/caelestia/blob/main/hypr/variables.lua
return {
  -- Ejemplos de apps por defecto (descomenta y ajusta si quieres cambiarlas)
  -- browser = "zen-browser",
  -- editor  = "code",
}
EOF
echo "hypr-vars.lua escrito en $CAEL_DIR/hypr-vars.lua"

# --- hypr-user.lua: monitor, teclado físico y touchpad -------------------
if [ -f "$CAEL_DIR/hypr-user.lua" ]; then
    cp "$CAEL_DIR/hypr-user.lua" "$CAEL_DIR/hypr-user.lua.bak.$(date +%s)"
    echo "Backup de hypr-user.lua existente creado."
fi

cat > "$CAEL_DIR/hypr-user.lua" <<EOF
-- Configuración Hyprland cruda, cargada al final del arranque.
-- Sintaxis Lua nativa de Hyprland 0.55+: si tu versión no la soporta o
-- da error al recargar, usa la sintaxis clásica de hyprland.conf dentro
-- de un exec-line, o consulta la wiki de Hyprland para el formato vigente.

monitor = {
  {
    name    = "$MONITOR_NAME",
    -- resolución y refresco: ajusta "highres@highrr" al valor real que
    -- reporte 'hyprctl monitors' (ej. "1920x1080@144")
    mode    = "preferred",
    position = "0x0",
    scale   = 1.25,
  }
}

input = {
  kb_layout  = "us",
  kb_variant = "intl",
  touchpad = {
    natural_scroll   = true,
    tap-to-click     = true,
  },
}
EOF
echo "hypr-user.lua escrito en $CAEL_DIR/hypr-user.lua"

echo "======================================================="
echo " Listo. Antes de reiniciar:"
echo "   1) Revisa manualmente $CAEL_DIR/hypr-user.lua"
echo "      y confirma la resolución real con: hyprctl monitors"
echo "   2) Prueba en caliente sin reiniciar:"
echo "        hyprctl reload"
echo "      Si arroja un error de sintaxis Lua, es señal de que tu versión"
echo "      de Hyprland espera un formato distinto: revisa"
echo "      https://wiki.hyprland.org (sección Lua configuration)."
echo "   3) Reinicia el equipo para aplicar todo con normalidad."
echo "======================================================="
