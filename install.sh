#!/usr/bin/env bash
# Salir inmediatamente si un comando falla
set -e

echo "======================================================="
echo "   Instalador Automático: CachyOS + Caelestia + SDDM   "
echo "======================================================="

# Verificación de seguridad: No ejecutar como root directamente
if [ "$EUID" -eq 0 ]; then
  echo "Por favor, no ejecutes este script como root. Ejecútalo como tu usuario normal."
  exit 1
fi

echo "[1/8] Actualizando el sistema e instalando herramientas base..."
sudo pacman -Syu --noconfirm
sudo pacman -S --needed --noconfirm base-devel git fish wget curl

echo "[2/8] Verificando helper de AUR (paru)..."
if ! command -v paru &> /dev/null; then
    echo "Instalando paru..."
    git clone https://aur.archlinux.org/paru.git /tmp/paru
    cd /tmp/paru
    makepkg -si --noconfirm
    cd ~
    rm -rf /tmp/paru
else
    echo "paru ya está instalado."
fi

echo "[3/8] Instalando y configurando Login Manager (SDDM)..."
# Instalamos SDDM y dependencias de Qt6 para la interfaz del tema
sudo pacman -S --needed --noconfirm sddm qt6-5compat qt6-declarative qt6-svg
sudo systemctl enable sddm

echo "[4/8] Instalando caelestia-cli, caelestia-shell y el tema SDDM Minimalist..."
# Descargamos los paquetes oficiales y el tema minimalist sincronizado desde el AUR
paru -S --needed --noconfirm caelestia-cli caelestia-shell caelestia-sddm-minimalist-git

echo "[5/8] Clonando los dotfiles de Caelestia..."
mkdir -p ~/.local/share
if [ -d "$HOME/.local/share/caelestia" ]; then
    echo "El directorio ya existe, actualizando repositorio..."
    cd ~/.local/share/caelestia
    git pull
else
    # Clonamos en la ruta recomendada para evitar romper los symlinks
    git clone https://github.com/caelestia-dots/caelestia.git ~/.local/share/caelestia
    cd ~/.local/share/caelestia
fi

echo "[6/8] Ejecutando el script de instalación de dotfiles con las apps..."
# Pasamos las banderas correspondientes omitiendo la de spotify
./install.fish --noconfirm --zen --vscode=code --discord

echo "[7/8] Configurando permisos sudoers para temas automáticos (CLI)..."
paru -S --needed --noconfirm papirus-folders

# Reglas de sudoers obligatorias para que el CLI maneje los colores sin pedir password
echo "$USER ALL=(ALL) NOPASSWD: $(which papirus-folders)" | sudo tee /etc/sudoers.d/papirus-folders > /dev/null
sudo chmod 440 /etc/sudoers.d/papirus-folders

# Permisos para aplicar las políticas de tematización dinámica en navegadores basados en Chromium
for dir in /etc/chromium/policies/managed /etc/brave/policies/managed /etc/opt/chrome/policies/managed; do
    echo "$USER ALL=(ALL) NOPASSWD: $(which mkdir) -p $dir" | sudo tee -a /etc/sudoers.d/caelestia-chromium > /dev/null
    echo "$USER ALL=(ALL) NOPASSWD: $(which tee) $dir/caelestia.json" | sudo tee -a /etc/sudoers.d/caelestia-chromium > /dev/null
done
sudo chmod 440 /etc/sudoers.d/caelestia-chromium

echo "[8/8] Sincronizando el tema Minimalist de SDDM..."
# Forzamos la primera sincronización del fondo de pantalla y colores actuales al login manager
sudo /usr/share/sddm/themes/caelestia/scripts/sync.sh

echo "======================================================="
echo " ¡Instalación Completada con Éxito!                    "
echo "======================================================="
echo "Por favor, REINICIA tu computadora."
echo "SDDM con el tema 'minimalist' e Hyprland están listos."
