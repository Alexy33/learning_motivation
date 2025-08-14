#!/bin/bash

# ============================================================================
# Admin Module - Mode administrateur pour gestion d'urgence
# ============================================================================

readonly ADMIN_LOG="$CONFIG_DIR/admin_actions.log"

# Codes d'accès admin (peuvent être changés)
readonly ADMIN_CODES=("emergency123" "override456" "rescue789")

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
    local mission_active penalties_active
    mission_active=$(admin_has_mission && echo "OUI" || echo "NON")
    penalties_active=$(punishment_has_active_punishments && echo "OUI" || echo "NON")
    
    ui_info "📊 État du système :"
    echo "  Mission en cours : $mission_active"
    echo "  Pénalités actives : $penalties_active"
    echo

    local admin_choice
    admin_choice=$(gum choose \
      --cursor="➤ " \
      --selected.foreground="#ff0000" \
      --cursor.foreground="#ff0000" \
      "🚨 ARRÊT D'URGENCE - Stopper TOUTES les pénalités" \
      "📋 Voir les pénalités actives détaillées" \
      "🗑️ Nettoyer tous les fichiers temporaires" \
      "📜 Voir le journal admin" \
      "🔄 Redémarrer en mode normal" \
      "🚪 Quitter le mode admin")

    case "$admin_choice" in
      *"ARRÊT D'URGENCE"*)
        admin_emergency_stop_all
        ;;
      *"pénalités actives"*)
        punishment_list_active
        ui_wait
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

    # 2. Utiliser la fonction centralisée d'arrêt des pénalités
    punishment_emergency_stop
    ui_success "✓ Toutes les pénalités arrêtées"
    stopped_count=$((stopped_count + 1))

    # 3. Nettoyer les fichiers temporaires
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

admin_cleanup_all() {
  ui_header "🗑️ Nettoyage Complet"
  
  ui_warning "Cette action va supprimer :"
  echo "  📁 Fichiers temporaires"
  echo "  🗃️ Logs de notifications"  
  echo "  🔄 Processus orphelins"
  echo "  ⚠️ Fichiers de backup système"
  echo
  ui_info "Les statistiques et configuration seront PRÉSERVÉES"
  echo

  if ui_confirm "Effectuer le nettoyage complet ?"; then
    local cleaned_count=0

    # Nettoyer fichiers temporaires
    if admin_cleanup_temp_files; then
      ui_success "✓ Fichiers temporaires supprimés"
      cleaned_count=$((cleaned_count + 1))
    fi

    # Nettoyer processus orphelins
    if pkill -f "learning.*timer" 2>/dev/null; then
      ui_success "✓ Processus timer nettoyés"
      cleaned_count=$((cleaned_count + 1))
    fi

    # Nettoyer logs
    if [[ -f "$CONFIG_DIR/notifications.log" ]]; then
      rm -f "$CONFIG_DIR/notifications.log"
      ui_success "✓ Logs de notifications supprimés"
      cleaned_count=$((cleaned_count + 1))
    fi

    # Nettoyer backups système
    local backup_files=(
      "$CONFIG_DIR"/mouse_*_backup.conf
      "$CONFIG_DIR/wallpaper_backup.info"
      "$CONFIG_DIR/restore_network.sh"
    )
    
    local backup_cleaned=false
    for pattern in "${backup_files[@]}"; do
      if ls $pattern 2>/dev/null; then
        rm -f $pattern
        backup_cleaned=true
      fi
    done
    
    if $backup_cleaned; then
      ui_success "✓ Fichiers de backup supprimés"
      cleaned_count=$((cleaned_count + 1))
    fi

    echo
    ui_success "🎉 Nettoyage terminé - $cleaned_count catégories nettoyées"
    admin_log "CLEANUP_ALL" "Nettoyage complet effectué - $cleaned_count actions"
  else
    ui_info "Nettoyage annulé"
  fi
}

# ============================================================================
# Fonctions utilitaires
# ============================================================================

admin_has_mission() {
  local mission_data
  mission_data=$(config_get_current_mission)
  [[ "$mission_data" != "null" ]] && [[ -n "$mission_data" ]]
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
  
  echo
  ui_wait
}