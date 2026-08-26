#!/usr/bin/env bash
# =========================================================================
#  Fase 1 - Preparación base para Caelestia dots (CachyOS, sin DE)
# =========================================================================
# Cambios vs versión anterior:
#  - Se añade hyprland (faltaba por completo)
#  - Se añade uwsm (las dots asumen sesión lanzada vía UWSM)
#  - Se añade stack de audio pipewire (CachyOS "solo base" no lo trae)
#  - Se añade papirus-icon-theme (antes solo se configuraba el sudoers
#    de papirus-folders, pero nunca se instalaba el tema que colorea)
#  - Se añade ttf-jetbrains-mono-nerd (requisito explícito del README)
#  - Se quita caelestia-sddm-minimalist-git: no se pudo confirmar que
#    exista actualmente en el AUR. Si quieres un theme de SDDM, instálalo
#    aparte tras verificarlo en aur.archlinux.org
#  - Se deja que `caelestia install` resuelva caelestia-shell/quickshell
#    y demás dependencias gráficas via manifest.toml, en vez de adivinarlas
#    a mano (evita conflictos de versión)
#  - Manejo de errores por paquete: si algo no existe/falla, el script
#    avisa y continúa en vez de abortar todo el flujo
# =========================================================================
set -uo pipefail

log()  { echo -e "\n\033[1;34m[*] $*\033[0m"; }
warn() { echo -e "\033[1;33m[!] $*\033[0m"; }
err()  { echo -e "\033[1;31m[x] $*\033[0m"; }

if [ "$EUID" -eq 0 ]; then
  err "Ejecuta este script sin sudo (te pedirá la contraseña cuando la necesite)."
  exit 1
fi

log "Autenticando permisos..."
sudo -v
( while true; do sudo -n true; sleep 60; kill -0 "$$" 2>/dev/null || exit; done ) &
KEEPALIVE_PID=$!
trap 'kill "$KEEPALIVE_PID" 2>/dev/null' EXIT

# --- función auxiliar: instalar con pacman sin tumbar el script si falla un paquete
pacman_install() {
  sudo pacman -S --needed --noconfirm "$@" || warn "Algún paquete de pacman falló: $*"
}

paru_install() {
  paru -S --needed --noconfirm "$@" || warn "Algún paquete AUR falló: $*"
}

log "[1/7] Actualizando el sistema..."
sudo pacman -Syu --noconfirm

log "[2/7] Instalando Hyprland, portales, UWSM y Qt..."
pacman_install \
    hyprland uwsm \
    xdg-desktop-portal-hyprland xdg-desktop-portal-gtk \
    qt5-wayland qt6-wayland qt6-5compat qt6-declarative qt6-svg \
    polkit-kde-agent wl-clipboard xorg-xwayland \
    ttf-jetbrains-mono-nerd papirus-icon-theme

log "[3/7] Instalando stack de audio (pipewire)..."
pacman_install pipewire wireplumber pipewire-pulse pipewire-alsa pipewire-jack pavucontrol

log "[4/7] Herramientas base + fish + git..."
pacman_install base-devel git curl wget fish unzip

log "[5/7] Verificando helper AUR (paru)..."
if ! command -v paru &> /dev/null; then
    log "Instalando paru..."
    tmpdir=$(mktemp -d)
    if git clone https://aur.archlinux.org/paru.git "$tmpdir/paru"; then
        (cd "$tmpdir/paru" && makepkg -si --noconfirm) || err "Falló compilación de paru"
    fi
    rm -rf "$tmpdir"
fi

log "[6/7] Ecosistema Dev / Gaming / Apps diarias (opcional, comenta lo que no quieras)..."
pacman_install python nodejs npm php postgresql sqlite docker podman android-tools scrcpy steam prismlauncher
if command -v paru &> /dev/null; then
    paru_install visual-studio-code-bin zen-browser-bin discord
else
    warn "paru no disponible, se omiten paquetes AUR (vscode/zen/discord)"
fi

log "Configurando servicios (Docker)..."
sudo systemctl enable --now docker.service || warn "No se pudo habilitar docker"
sudo usermod -aG docker "$USER"

log "[7/7] Login manager (SDDM) + CLI de Caelestia..."
pacman_install sddm
sudo systemctl enable sddm
if command -v paru &> /dev/null; then
    paru_install caelestia-cli
else
    err "paru no está disponible: no se pudo instalar caelestia-cli. Instálalo manualmente."
fi

# sudoers para papirus-folders (colorea iconos automáticamente según el tema)
if command -v papirus-folders &> /dev/null; then
    PF_PATH="$(command -v papirus-folders)"
    echo "$USER ALL=(ALL) NOPASSWD: $PF_PATH" | sudo tee /tmp/papirus-folders > /dev/null
    if sudo visudo -cf /tmp/papirus-folders &>/dev/null; then
        sudo mv /tmp/papirus-folders /etc/sudoers.d/papirus-folders
        sudo chmod 440 /etc/sudoers.d/papirus-folders
        log "Sudoers de papirus-folders configurado."
    else
        err "El archivo sudoers generado no es válido, no se aplicó."
        rm -f /tmp/papirus-folders
    fi
else
    warn "papirus-folders no encontrado (normalmente lo trae caelestia-cli o su AUR helper como dependencia; revisa después de instalar caelestia-cli)."
fi

echo -e "\n========================================================="
echo " Fase 1 terminada."
echo " Verifica manualmente antes de continuar:"
echo "   1) Que exista una sesión Wayland de Hyprland/UWSM en SDDM:"
echo "        ls /usr/share/wayland-sessions/"
echo "      (deberías ver algo como hyprland-uwsm.desktop; si NO aparece,"
echo "       instala también: sudo pacman -S hyprland-uwsm  # o similar según repos"
echo "       o usa greetd+tuigreet como recomienda el proyecto)"
echo "   2) Reinicia sesión (o el equipo) para que el grupo docker surta efecto."
echo " AHORA EJECUTA MANUALMENTE:  caelestia install"
echo "========================================================="
