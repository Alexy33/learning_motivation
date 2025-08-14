#!/bin/bash
# Script d'urgence admin - Version corrigée

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PARENT_DIR="$(dirname "$SCRIPT_DIR")"
CONFIG_DIR="$HOME/.learning_challenge"

# Couleurs basiques
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${RED}🚨 MODE ADMIN URGENCE${NC}"
echo ""

# Codes d'accès
ADMIN_CODES=("emergency123" "override456" "rescue789")

echo "🔐 Code d'accès requis:"
read -p "Code: " -s code
echo ""

# Vérification
valid=false
for valid_code in "${ADMIN_CODES[@]}"; do
    if [[ "$code" == "$valid_code" ]]; then
        valid=true
        break
    fi
done

if [[ "$valid" != "true" ]]; then
    echo -e "${RED}❌ Code incorrect${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Accès autorisé${NC}"
echo ""
echo -e "${YELLOW}🚨 Arrêt d'urgence en cours...${NC}"

# Arrêt des processus
pkill -f "punishment" 2>/dev/null && echo "✓ Processus punishment arrêtés"
pkill -f "notification_spam" 2>/dev/null && echo "✓ Notifications stoppées"

# Restauration Hyprland
if command -v hyprctl &>/dev/null; then
    hyprctl keyword input:sensitivity 0 2>/dev/null && echo "✓ Souris Hyprland restaurée"
fi

# Nettoyage fichiers
rm -f "$CONFIG_DIR"/mouse_*.backup 2>/dev/null && echo "✓ Backups souris supprimés"
rm -f "$CONFIG_DIR/wallpaper_backup.info" 2>/dev/null && echo "✓ Wallpaper backup supprimé"
rm -f "$CONFIG_DIR/network_restricted.txt" 2>/dev/null && echo "✓ Restriction réseau supprimée"
rm -f "$CONFIG_DIR/blocked_hosts" 2>/dev/null && echo "✓ Hosts bloqués supprimés"
rm -f "$CONFIG_DIR/mouse_reduction_reminder.txt" 2>/dev/null && echo "✓ Rappel souris supprimé"

# Restauration réseau
if sudo -n true 2>/dev/null; then
    sudo systemctl start NetworkManager 2>/dev/null && echo "✓ NetworkManager redémarré"
    sudo sed -i '/# Learning Challenge - Punishment Block/,/^$/d' /etc/hosts 2>/dev/null && echo "✓ Hosts restauré"
fi

echo ""
echo -e "${GREEN}✅ ARRÊT D'URGENCE TERMINÉ${NC}"
echo "🔄 Vous pouvez relancer: ./learning.sh"
