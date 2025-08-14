#!/bin/bash

# ============================================================================
# Admin Module - Mode administrateur pour gestion d'urgence
# ============================================================================

readonly ADMIN_LOG="$CONFIG_DIR/admin_actions.log"

# Codes d'accès admin (peuvent être changés)
readonly ADMIN_CODES=("emergency123" "override456" "rescue789")
readonly ADMIN_SESSION_DURATION=300  # 5 minutes


# ============================================================================
# Interface principale du mode admin
# ============================================================================

admin_mode_main() {
  ui_clear
  echo -e "${RED}${BOLD}"
  echo "╔═══════════════════════════════════════════════════════════════╗"
  echo "║                        MODE ADMINISTRATEUR                   ║"
  echo "║                     ACCÈS RESTREINT - URGENCE                ║"
  echo "╚═══════════════════════════════════════════════════════════════╝"
  echo -e "${NC}"
  
  ui_warning "🚨 MODE ADMIN - Utilisation exceptionnelle uniquement"
  ui_info "Ce mode permet d'arrêter toutes les pénalités en cas de problème grave"
  echo

  # Authentification
  if ! admin_authenticate; then
    ui_error "Accès refusé"
    exit 1
  fi

  # Menu admin principal
  admin_main_menu
}

admin_authenticate() {
  ui_info "🔐 Authentification requise"
  echo

  local attempts=0
  local max_attempts=3

  while [[ $attempts -lt $max_attempts ]]; do
    local code
    code=$(gum input --password --placeholder "Code d'accès admin")
    
    # Vérifier le code
    local valid=false
    for valid_code in "${ADMIN_CODES[@]}"; do
      if [[ "$code" == "$valid_code" ]]; then
        valid=true
        break
      fi
    done

    if [[ "$valid" == "true" ]]; then
      ui_success "✅ Accès autorisé"
      admin_log "ADMIN_ACCESS_GRANTED" "Accès admin accordé"
      return 0
    else
      attempts=$((attempts + 1))
      local remaining=$((max_attempts - attempts))
      
      if [[ $remaining -gt 0 ]]; then
        ui_error "Code incorrect. $remaining tentative(s) restante(s)"
      fi
    fi
  done

  admin_log "ADMIN_ACCESS_DENIED" "Échec d'authentification après $max_attempts tentatives"
  ui_error "Trop de tentatives échouées"
  return 1
}

admin_main_menu() {
  while true; do
    ui_header "Mode Administrateur"
    
    # Diagnostiquer l'état actuel
    local penalties_active
    penalties_active=$(admin_count_active_penalties)
    
    ui_info "📊 État du système :"
    echo "  Pénalités actives : $penalties_active"
    echo "  Mission en cours : $(admin_has_mission && echo "OUI" || echo "NON")"
    echo

    local admin_choice
    admin_choice=$(gum choose \
      --cursor="➤ " \
      --selected.foreground="#ff0000" \
      --cursor.foreground="#ff0000" \
      "🚨 ARRÊT D'URGENCE - Stopper TOUTES les pénalités" \
      "🔍 Diagnostic complet du système" \
      "📋 Voir les pénalités actives détaillées" \
      "🗑️ Nettoyer tous les fichiers temporaires" \
      "📜 Voir le journal admin" \
      "🔄 Redémarrer en mode normal" \
      "🚪 Quitter le mode admin")

    case "$admin_choice" in
      *"ARRÊT D'URGENCE"*)
        admin_emergency_stop_all
        ;;
      *"Diagnostic complet"*)
        admin_full_diagnostic
        ;;
      *"pénalités actives"*)
        admin_show_active_penalties
        ;;
      *"Nettoyer tous"*)
        admin_cleanup_all
        ;;
      *"journal admin"*)
        admin_show_log
        ;;
      *"Redémarrer en mode normal"*)
        ui_success "Redémarrage en mode normal..."
        exec "$0"
        ;;
      *"Quitter"*)
        ui_success "Sortie du mode admin"
        exit 0
        ;;
    esac
    
    echo
    ui_wait "Appuyez sur Entrée pour continuer"
  done
}

# ============================================================================
# Fonctions d'arrêt d'urgence
# ============================================================================

admin_emergency_stop_all() {
  ui_header "🚨 ARRÊT D'URGENCE TOTAL"
  
  ui_error "ATTENTION: Cette action va immédiatement :"
  echo "  💀 Arrêter TOUTES les pénalités en cours"
  echo "  🔄 Restaurer tous les paramètres système"  
  echo "  🧹 Nettoyer tous les processus liés"
  echo "  📊 Mission actuelle sera PRÉSERVÉE"
  echo "  📈 Statistiques seront PRÉSERVÉES"
  echo

  if ui_confirm "CONFIRMER l'arrêt d'urgence total ?"; then
    ui_info "🚨 Début de l'arrêt d'urgence..."
    
    local stopped_count=0
    
    # 1. Arrêter les processus de pénalités
    if admin_stop_punishment_processes; then
      ui_success "✓ Processus de pénalités arrêtés"
      stopped_count=$((stopped_count + 1))
    fi

    # 2. Restaurer la souris
    if admin_restore_mouse_all; then
      ui_success "✓ Sensibilité souris restaurée"
      stopped_count=$((stopped_count + 1))
    fi

    # 3. Restaurer le wallpaper
    if admin_restore_wallpaper; then
      ui_success "✓ Wallpaper restauré"
      stopped_count=$((stopped_count + 1))
    fi

    # 4. Restaurer le réseau
    if admin_restore_network; then
      ui_success "✓ Réseau restauré"
      stopped_count=$((stopped_count + 1))
    fi

    # 5. Débloquer les sites
    if admin_restore_websites; then
      ui_success "✓ Sites web débloqués"
      stopped_count=$((stopped_count + 1))
    fi

    # 6. Nettoyer les fichiers temporaires
    if admin_cleanup_temp_files; then
      ui_success "✓ Fichiers temporaires nettoyés"
      stopped_count=$((stopped_count + 1))
    fi

    echo
    ui_success "🎉 ARRÊT D'URGENCE TERMINÉ"
    ui_info "Actions effectuées : $stopped_count"
    
    admin_log "EMERGENCY_STOP_ALL" "Arrêt d'urgence total - $stopped_count actions"
    
    # Notification système
    notify-send "🚨 Learning Challenge" "Arrêt d'urgence admin effectué - Toutes les pénalités stoppées" --urgency=critical
  else
    ui_info "Arrêt d'urgence annulé"
  fi
}

admin_stop_punishment_processes() {
  local stopped=false
  
  # Arrêter les processus de notification spam
  if pkill -f "punishment.*notification_spam" 2>/dev/null; then
    stopped=true
  fi
  
  # Arrêter les timers de pénalités
  if pkill -f "punishment.*timer" 2>/dev/null; then
    stopped=true
  fi
  
  # Supprimer les PID files
  rm -f "$CONFIG_DIR"/notification_spam.pid 2>/dev/null && stopped=true
  
  $stopped
}

admin_restore_mouse_all() {
  local restored=false
  
  # Hyprland
  if command -v hyprctl &>/dev/null && [[ -f "$CONFIG_DIR/mouse_hyprland_backup.conf" ]]; then
    source "$CONFIG_DIR/mouse_hyprland_backup.conf"
    hyprctl keyword input:sensitivity "${sensitivity:-0}"
    rm -f "$CONFIG_DIR/mouse_hyprland_backup.conf"
    restored=true
  fi
  
  # GNOME
  if [[ -f "$CONFIG_DIR/mouse_gnome_backup.conf" ]]; then
    source "$CONFIG_DIR/mouse_gnome_backup.conf"
    gsettings set org.gnome.desktop.peripherals.mouse speed "${speed//\'/}" 2>/dev/null || true
    gsettings set org.gnome.desktop.peripherals.mouse accel-profile "${accel_profile//\'/}" 2>/dev/null || true
    rm -f "$CONFIG_DIR/mouse_gnome_backup.conf"
    restored=true
  fi
  
  # KDE
  if [[ -f "$CONFIG_DIR/mouse_kde_backup.conf" ]]; then
    source "$CONFIG_DIR/mouse_kde_backup.conf"
    kwriteconfig5 --file kcminputrc --group Mouse --key Acceleration "$acceleration" 2>/dev/null || true
    kwriteconfig5 --file kcminputrc --group Mouse --key Threshold "$threshold" 2>/dev/null || true
    qdbus org.kde.KWin /KWin reconfigure 2>/dev/null || true
    rm -f "$CONFIG_DIR/mouse_kde_backup.conf"
    restored=true
  fi
  
  # X11
  if command -v xinput &>/dev/null && [[ -f "$CONFIG_DIR/mouse_devices.backup" ]]; then
    local mouse_ids
    mouse_ids=$(xinput list | grep -i mouse | grep -o 'id=[0-9]*' | cut -d= -f2)
    for id in $mouse_ids; do
      xinput set-prop "$id" "libinput Accel Speed" 0 2>/dev/null || true
    done
    rm -f "$CONFIG_DIR"/mouse_*.backup
    restored=true
  fi
  
  # Sway
  if command -v swaymsg &>/dev/null && [[ -f "$CONFIG_DIR/mouse_sway_backup.conf" ]]; then
    swaymsg input type:pointer accel_profile adaptive 2>/dev/null || true
    swaymsg input type:pointer pointer_accel 0 2>/dev/null || true
    rm -f "$CONFIG_DIR/mouse_sway_backup.conf"
    restored=true
  fi
  
  # Nettoyer fichier de simulation
  if [[ -f "$CONFIG_DIR/mouse_reduction_reminder.txt" ]]; then
    rm -f "$CONFIG_DIR/mouse_reduction_reminder.txt"
    restored=true
  fi
  
  $restored
}

admin_restore_wallpaper() {
  local restored=false
  
  # Arrêter swaybg si en cours
  pkill swaybg 2>/dev/null && restored=true
  
  # Restaurer selon backup
  if [[ -f "$CONFIG_DIR/wallpaper_backup.info" ]]; then
    local original_wallpaper
    original_wallpaper=$(cat "$CONFIG_DIR/wallpaper_backup.info")

    if command -v gsettings &>/dev/null; then
      gsettings set org.gnome.desktop.background picture-uri "$original_wallpaper" 2>/dev/null || true
      restored=true
    elif command -v xfconf-query &>/dev/null; then
      xfconf-query -c xfce4-desktop -p /backdrop/screen0/monitor0/workspace0/last-image -s "$original_wallpaper" 2>/dev/null || true
      restored=true
    elif command -v kwriteconfig5 &>/dev/null; then
      kwriteconfig5 --file kdesktoprc --group Desktop0 --key Wallpaper "$original_wallpaper" 2>/dev/null || true
      restored=true
    fi

    rm -f "$CONFIG_DIR/wallpaper_backup.info"
  fi
  
  # Supprimer wallpaper de honte
  rm -f "$CONFIG_DIR/shame_wallpaper.png" "$CONFIG_DIR/shame_wallpaper.png.txt"
  
  $restored
}

admin_restore_network() {
  local restored=false
  
  # Vérifier si NetworkManager est arrêté
  if ! systemctl is-active --quiet NetworkManager; then
    if sudo -n systemctl start NetworkManager 2>/dev/null; then
      restored=true
    fi
  fi
  
  # Nettoyer fichiers de restriction
  if [[ -f "$CONFIG_DIR/network_restricted.txt" ]]; then
    rm -f "$CONFIG_DIR/network_restricted.txt"
    restored=true
  fi
  
  if [[ -f "$CONFIG_DIR/restore_network.sh" ]]; then
    rm -f "$CONFIG_DIR/restore_network.sh"
    restored=true
  fi
  
  $restored
}

admin_restore_websites() {
  local restored=false
  
  # Restaurer /etc/hosts
  if [[ -f "$CONFIG_DIR/blocked_hosts" ]] && sudo -n true 2>/dev/null; then
    sudo sed -i '/# Learning Challenge - Punishment Block/,/^$/d' /etc/hosts 2>/dev/null && restored=true
    rm -f "$CONFIG_DIR/blocked_hosts"
  elif [[ -f "$CONFIG_DIR/blocked_hosts" ]]; then
    rm -f "$CONFIG_DIR/blocked_hosts"
    restored=true
  fi
  
  $restored
}

admin_cleanup_temp_files() {
  local cleaned=false
  
  # Fichiers temporaires des pénalités
  local temp_files=(
    "$CONFIG_DIR/timer.pid"
    "$CONFIG_DIR/timer_status" 
    "$CONFIG_DIR/notifications.log"
    "$CONFIG_DIR/notification_spam.pid"
    "/tmp/hyprpaper_temp.conf"
  )
  
  for file in "${temp_files[@]}"; do
    if [[ -f "$file" ]]; then
      rm -f "$file" && cleaned=true
    fi
  done
  
  $cleaned
}

# ============================================================================
# Fonctions de diagnostic
# ============================================================================

admin_count_active_penalties() {
  local count=0
  
  [[ -f "$CONFIG_DIR/network_restricted.txt" ]] && count=$((count + 1))
  [[ -f "$CONFIG_DIR/wallpaper_backup.info" ]] && count=$((count + 1))
  [[ -f "$CONFIG_DIR/mouse_reduction_reminder.txt" ]] && count=$((count + 1))
  [[ -f "$CONFIG_DIR/blocked_hosts" ]] && count=$((count + 1))
  [[ -f "$CONFIG_DIR/mouse_gnome_backup.conf" ]] && count=$((count + 1))
  [[ -f "$CONFIG_DIR/mouse_kde_backup.conf" ]] && count=$((count + 1))
  [[ -f "$CONFIG_DIR/mouse_hyprland_backup.conf" ]] && count=$((count + 1))
  
  pgrep -f "punishment.*notification_spam" &>/dev/null && count=$((count + 1))
  
  echo "$count"
}

admin_has_mission() {
  local mission_data
  mission_data=$(config_get_current_mission)
  [[ "$mission_data" != "null" ]] && [[ -n "$mission_data" ]]
}

admin_show_active_penalties() {
  ui_header "📋 Pénalités Actives Détaillées"
  
  local found=false
  
  if [[ -f "$CONFIG_DIR/network_restricted.txt" ]]; then
    echo "🌐 RESTRICTION RÉSEAU :"
    cat "$CONFIG_DIR/network_restricted.txt" | head -5
    echo ""; found=true
  fi
  
  if [[ -f "$CONFIG_DIR/wallpaper_backup.info" ]]; then
    echo "🖼️ WALLPAPER DE LA HONTE : Actif"
    echo ""; found=true
  fi
  
  if [[ -f "$CONFIG_DIR/mouse_reduction_reminder.txt" ]]; then
    echo "🖱️ SOURIS (simulation) :"
    cat "$CONFIG_DIR/mouse_reduction_reminder.txt" | head -5
    echo ""; found=true
  fi
  
  if [[ -f "$CONFIG_DIR/mouse_hyprland_backup.conf" ]]; then
    echo "🖱️ SOURIS HYPRLAND : Sensibilité réduite"
    echo ""; found=true
  fi
  
  if [[ -f "$CONFIG_DIR/blocked_hosts" ]]; then
    echo "🚫 SITES BLOQUÉS :"
    wc -l "$CONFIG_DIR/blocked_hosts" | cut -d' ' -f1 | xargs echo "Sites bloqués :"
    echo ""; found=true
  fi
  
  if pgrep -f "punishment.*notification_spam" &>/dev/null; then
    echo "📢 NOTIFICATIONS SPAM : Actives"
    echo ""; found=true
  fi
  
  if [[ "$found" == "false" ]]; then
    ui_success "✅ Aucune pénalité active détectée"
  fi
}

admin_full_diagnostic() {
  ui_header "🔍 Diagnostic Complet"
  
  echo "=== ENVIRONNEMENT ==="
  echo "OS: $(uname -a)"
  echo "Desktop: ${XDG_CURRENT_DESKTOP:-'Inconnu'}"
  echo "Session: ${XDG_SESSION_TYPE:-'Inconnu'}"
  echo "Wayland: ${WAYLAND_DISPLAY:-'Non'}"
  echo "Display: ${DISPLAY:-'Non'}"
  echo ""
  
  echo "=== OUTILS DISPONIBLES ==="
  local tools=("hyprctl" "gsettings" "xinput" "notify-send" "systemctl" "sudo")
  for tool in "${tools[@]}"; do
    if command -v "$tool" &>/dev/null; then
      echo "✓ $tool"
    else
      echo "✗ $tool"
    fi
  done
  echo ""
  
  echo "=== FICHIERS DE CONFIGURATION ==="
  local files=("$CONFIG_FILE" "$STATS_FILE" "$MISSION_FILE")
  for file in "${files[@]}"; do
    if [[ -f "$file" ]]; then
      echo "✓ $(basename "$file") ($(stat -c%s "$file") octets)"
    else
      echo "✗ $(basename "$file") (manquant)"
    fi
  done
  echo ""
  
  echo "=== PROCESSUS ACTIFS ==="
  pgrep -f "learning" | head -10 | while read pid; do
    echo "PID $pid: $(ps -p $pid -o comm= 2>/dev/null || echo 'Process terminé')"
  done
  echo ""
  
  echo "=== UTILISATION DISQUE ==="
  if [[ -d "$CONFIG_DIR" ]]; then
    du -sh "$CONFIG_DIR" 2>/dev/null | cut -f1 | xargs echo "Configuration:"
  fi
}

# ============================================================================
# Logging admin
# ============================================================================

admin_log() {
  local action=$1
  local description=$2
  local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
  
  echo "[$timestamp] $action: $description" >> "$ADMIN_LOG"
}

admin_show_log() {
  ui_header "📜 Journal Administrateur"
  
  if [[ -f "$ADMIN_LOG" ]]; then
    echo "Dernières 20 actions :"
    echo ""
    tail -20 "$ADMIN_LOG"
  else
    ui_info "Aucun journal admin trouvé"
  fi
}