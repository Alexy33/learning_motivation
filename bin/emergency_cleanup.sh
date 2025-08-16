#!/bin/bash

# ============================================================================
# SCRIPT D'URGENCE - NETTOYAGE COMPLET DU SYSTÈME DE PÉNALITÉS
# ============================================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

CONFIG_DIR="$HOME/.learning_challenge"

echo -e "${RED}🚨 NETTOYAGE D'URGENCE EN COURS...${NC}"
echo

# ============================================================================
# 1. ARRÊTER TOUS LES PROCESSUS
# ============================================================================

echo -e "${YELLOW}🔫 Arrêt de tous les processus...${NC}"

# Arrêter tous les processus liés
pkill -f "punishment" 2>/dev/null && echo "✓ Processus punishment arrêtés" || true
pkill -f "annoying_sound" 2>/dev/null && echo "✓ Processus sons arrêtés" || true
pkill -f "fake_errors" 2>/dev/null && echo "✓ Processus fausses erreurs arrêtés" || true
pkill -f "notification_spam" 2>/dev/null && echo "✓ Spam notifications arrêté" || true
pkill -f "learning.*timer" 2>/dev/null && echo "✓ Timers arrêtés" || true

# ============================================================================
# 2. NETTOYER LES FICHIERS DE CONFIGURATION SHELL
# ============================================================================

echo -e "${YELLOW}🧹 Nettoyage des fichiers shell...${NC}"

# Fonction pour nettoyer un fichier shell
cleanup_shell_file() {
  local file="$1"

  if [[ -f "$file" ]]; then
    echo "🔧 Nettoyage de $file..."

    # Créer une sauvegarde
    cp "$file" "${file}.backup.$(date +%Y%m%d_%H%M%S)"

    # Supprimer toutes les lignes liées au Learning Challenge
    sed -i '/# Learning Challenge/d' "$file"
    sed -i '/punishment_aliases/d' "$file"
    sed -i '/fake_errors/d' "$file"
    sed -i '/learning_challenge/d' "$file"
    sed -i '/punishment_end_time/d' "$file"

    # Supprimer les lignes avec des problèmes de quotes
    sed -i '/unmatched/d' "$file"

    # Supprimer les lignes vides en trop (plus de 2 consécutives)
    awk '/^$/ { if (++n <= 2) print; next }; { n=0; print }' "$file" >"${file}.tmp" && mv "${file}.tmp" "$file"

    echo "✓ $file nettoyé et sauvegardé"
  fi
}

# Nettoyer les fichiers shell courants
cleanup_shell_file "$HOME/.bashrc"
cleanup_shell_file "$HOME/.zshrc"
cleanup_shell_file "$HOME/.profile"

# ============================================================================
# 3. SUPPRIMER TOUS LES FICHIERS TEMPORAIRES
# ============================================================================

echo -e "${YELLOW}🗑️ Suppression des fichiers temporaires...${NC}"

# Fichiers de pénalités
rm -f "$CONFIG_DIR/punishment_aliases.sh" && echo "✓ Aliases supprimés"
rm -f "$CONFIG_DIR/fake_errors.sh" && echo "✓ Script fausses erreurs supprimé"
rm -f "$CONFIG_DIR/annoying_sound.sh" && echo "✓ Script son supprimé"
rm -f "$CONFIG_DIR/punishment_end_time" && echo "✓ Fichier fin pénalité supprimé"

# PIDs et processus
rm -f "$CONFIG_DIR"/*.pid && echo "✓ Fichiers PID supprimés"
rm -f "$CONFIG_DIR/annoying_sound.pid"
rm -f "$CONFIG_DIR/notification_spam.pid"

# Fichiers de backup et rappels
rm -f "$CONFIG_DIR"/mouse_*_backup.conf && echo "✓ Backups souris supprimés"
rm -f "$CONFIG_DIR/network_restricted.txt"
rm -f "$CONFIG_DIR/blocked_hosts"
rm -f "$CONFIG_DIR/restore_network.sh"
rm -f "$CONFIG_DIR/mouse_reduction_reminder.txt"
rm -f "$CONFIG_DIR/screen_distortion_reminder.txt"
rm -f "$CONFIG_DIR/keyboard_delay_reminder.txt"
rm -f "$CONFIG_DIR/screen_backup.txt"
rm -f "$CONFIG_DIR/keyboard_backup.txt"

# Fichiers temporaires système
rm -f /tmp/learning_volume_backup && echo "✓ Backup volume supprimé"
rm -f /tmp/hyprpaper_temp.conf

echo "✓ Tous les fichiers temporaires supprimés"

# ============================================================================
# 4. RESTAURER LES PARAMÈTRES SYSTÈME
# ============================================================================

echo -e "${YELLOW}🔄 Restauration des paramètres système...${NC}"

# Restaurer le volume si nécessaire
if command -v pactl &>/dev/null; then
  pactl set-sink-volume @DEFAULT_SINK@ 50% 2>/dev/null && echo "✓ Volume normalisé à 50%"
elif command -v amixer &>/dev/null; then
  amixer set Master 50% 2>/dev/null && echo "✓ Volume normalisé à 50%"
fi

# Restaurer la souris selon l'environnement
if command -v hyprctl &>/dev/null; then
  hyprctl keyword input:sensitivity 0 2>/dev/null && echo "✓ Souris Hyprland restaurée"
fi

if command -v gsettings &>/dev/null && [[ "$XDG_CURRENT_DESKTOP" == *"GNOME"* ]]; then
  gsettings set org.gnome.desktop.peripherals.mouse speed 0.0 2>/dev/null && echo "✓ Souris GNOME restaurée"
  gsettings set org.gnome.desktop.interface text-scaling-factor 1.0 2>/dev/null && echo "✓ Interface GNOME restaurée"
fi

if command -v xinput &>/dev/null && [[ -n "${DISPLAY:-}" ]]; then
  local mouse_ids=$(xinput list | grep -i mouse | grep -o 'id=[0-9]*' | cut -d= -f2)
  for id in $mouse_ids; do
    xinput set-prop "$id" "libinput Accel Speed" 0 2>/dev/null || true
  done
  echo "✓ Souris X11 restaurée"
fi

# Restaurer l'écran
if command -v xrandr &>/dev/null && [[ -n "${DISPLAY:-}" ]]; then
  xrandr --output $(xrandr | grep " connected" | head -1 | cut -d' ' -f1) --rotate normal 2>/dev/null && echo "✓ Rotation écran restaurée"
fi

# Restaurer le clavier
if command -v xset &>/dev/null && [[ -n "${DISPLAY:-}" ]]; then
  xset r rate 660 25 2>/dev/null && echo "✓ Clavier restauré"
fi

# ============================================================================
# 5. NETTOYER LE RÉSEAU ET HOSTS
# ============================================================================

echo -e "${YELLOW}🌐 Nettoyage réseau...${NC}"

# Restaurer NetworkManager si nécessaire
if sudo -n true 2>/dev/null; then
  sudo systemctl start NetworkManager 2>/dev/null && echo "✓ NetworkManager redémarré"

  # Nettoyer le fichier hosts
  if sudo sed -i '/# Learning Challenge/,/^$/d' /etc/hosts 2>/dev/null; then
    echo "✓ Fichier hosts nettoyé"
  fi
else
  echo "ℹ️ Privilèges sudo non disponibles pour le nettoyage réseau"
fi

# ============================================================================
# 6. FORCER L'ARRÊT DE TOUS LES JOBS EN ARRIÈRE-PLAN
# ============================================================================

echo -e "${YELLOW}⏹️ Arrêt des jobs en arrière-plan...${NC}"

# Lister et tuer tous les jobs
jobs -p | xargs -r kill 2>/dev/null && echo "✓ Jobs arrêtés"

# Force kill de processus spécifiques qui pourraient traîner
for process in "speaker-test" "paplay" "aplay"; do
  pkill -f "$process" 2>/dev/null && echo "✓ $process arrêté" || true
done

# ============================================================================
# 7. NETTOYER LA MISSION EN COURS
# ============================================================================

echo -e "${YELLOW}📋 Nettoyage mission...${NC}"

rm -f "$CONFIG_DIR/current_mission.json" && echo "✓ Mission en cours supprimée"
rm -f "$CONFIG_DIR/timer.pid"
rm -f "$CONFIG_DIR/timer_status"

# ============================================================================
# 8. VÉRIFICATIONS FINALES
# ============================================================================

echo
echo -e "${GREEN}🔍 VÉRIFICATIONS FINALES...${NC}"

# Vérifier qu'aucun processus suspect ne tourne
if pgrep -f "punishment\|fake_errors\|annoying_sound" >/dev/null 2>&1; then
  echo -e "${RED}⚠️ Des processus suspects tournent encore${NC}"
  pgrep -f "punishment\|fake_errors\|annoying_sound" | xargs -r kill -9
  echo "✓ Processus suspects éliminés avec SIGKILL"
else
  echo "✓ Aucun processus suspect détecté"
fi

# Vérifier les fichiers shell
for file in "$HOME/.bashrc" "$HOME/.zshrc"; do
  if [[ -f "$file" ]] && grep -q "Learning Challenge\|punishment\|fake_errors" "$file"; then
    echo -e "${RED}⚠️ $file contient encore des références au système${NC}"
    echo "📄 Ligne problématique :"
    grep -n "Learning Challenge\|punishment\|fake_errors" "$file" | head -3
  else
    echo "✓ $file propre"
  fi
done

# ============================================================================
# 9. INSTRUCTIONS FINALES
# ============================================================================

echo
echo -e "${GREEN}🎉 NETTOYAGE D'URGENCE TERMINÉ !${NC}"
echo
echo -e "${YELLOW}📋 ACTIONS RECOMMANDÉES :${NC}"
echo "1. 🔄 Rechargez votre shell : source ~/.zshrc"
echo "2. 🆕 Ouvrez un nouveau terminal pour vérifier"
echo "3. 🔍 Si des problèmes persistent, redémarrez votre session"
echo "4. 📁 Vos shells ont été sauvegardés dans *.backup.*"
echo
echo -e "${CYAN}🛡️ Le système est maintenant complètement nettoyé.${NC}"
echo -e "${CYAN}Vous pouvez relancer le Learning Challenge Manager en sécurité.${NC}"

# ============================================================================
# 10. REDÉMARRAGE AUTOMATIQUE DU SHELL
# ============================================================================

echo
if command -v gum &>/dev/null; then
  if gum confirm "Voulez-vous recharger votre shell maintenant ?"; then
    exec "$SHELL"
  fi
else
  read -p "Voulez-vous recharger votre shell maintenant ? [y/N]: " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    exec "$SHELL"
  fi
fi

echo "✅ Script de nettoyage terminé. Rechargez manuellement votre shell si nécessaire."
