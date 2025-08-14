#!/bin/bash

# ============================================================================
# Learning Challenge Manager
# A gamified task management system for cybersecurity training
# ============================================================================

set -euo pipefail

# Configuration globale
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly CONFIG_DIR="$HOME/.learning_challenge"
readonly LIB_DIR="$SCRIPT_DIR/lib"
readonly BIN_DIR="$SCRIPT_DIR/bin"

# Import des modules
source "$LIB_DIR/admin.sh"
source "$LIB_DIR/config.sh"
source "$LIB_DIR/ui.sh"
source "$LIB_DIR/mission.sh"
source "$LIB_DIR/stats.sh"
source "$LIB_DIR/timer.sh"
source "$LIB_DIR/punishment.sh"

# ============================================================================
# Fonctions principales
# ============================================================================

check_dependencies() {
  local missing_deps=()

  for dep in gum jq bc; do
    if ! command -v "$dep" &>/dev/null; then
      missing_deps+=("$dep")
    fi
  done

  if [[ ${#missing_deps[@]} -gt 0 ]]; then
    ui_error "Dépendances manquantes: ${missing_deps[*]}"
    ui_info "Installation: sudo pacman -S ${missing_deps[*]}"
    exit 1
  fi
}

# ============================================================================
# Menu principal unifié
# ============================================================================
show_main_menu() {
  local mission_data
  mission_data=$(config_get_current_mission)

  # Afficher les jokers de sauvetage avec plus d'infos
  local jokers_available jokers_total
  jokers_available=$(config_get_jokers_available)
  jokers_total=$(config_get_jokers_total)

  # Options de base
  local menu_options=("🎯 Challenges" "📊 Statistiques" "⚙️ Paramètres" "🚪 Quitter")

  # Si mission en cours, ajouter les options liées
  if [[ "$mission_data" != "null" ]] && [[ -n "$mission_data" ]]; then
    local activity difficulty start_time duration
    activity=$(echo "$mission_data" | jq -r '.activity')
    difficulty=$(echo "$mission_data" | jq -r '.difficulty')
    start_time=$(echo "$mission_data" | jq -r '.start_time')
    duration=$(echo "$mission_data" | jq -r '.duration')

    local current_time elapsed remaining
    current_time=$(date +%s)
    elapsed=$((current_time - start_time))
    remaining=$((duration - elapsed))

    # Insérer les options mission au début
    if [[ $remaining -gt 0 ]]; then
      local remaining_formatted
      remaining_formatted=$(format_time $remaining)
      menu_options=("📋 Mission en cours ($remaining_formatted)" "✅ Terminer la mission" "🚨 Urgence & Jokers" "💀 Peine encourue" "${menu_options[@]}")
    else
      menu_options=("📋 Mission en cours (TEMPS ÉCOULÉ)" "✅ Terminer la mission" "🚨 Urgence & Jokers" "💀 Peine encourue" "${menu_options[@]}")
    fi
  else
    # Même sans mission, garder l'accès aux jokers pour annuler pénalités
    if punishment_has_active_punishments &>/dev/null; then
      menu_options=("🚨 Urgence & Jokers" "${menu_options[@]}")
    fi
  fi

  echo
  echo -e "${CYAN}Menu Principal - Learning Challenge Manager${NC}"

  # Affichage amélioré des jokers
  if [[ $jokers_available -gt 0 ]]; then
    echo -e "${GREEN}🃏 Jokers de sauvetage: $jokers_available/$jokers_total disponibles${NC}"
    echo -e "${BLUE}💡 Annulez missions/pénalités sans conséquences${NC}"
  else
    echo -e "${RED}🃏 Jokers de sauvetage: $jokers_available/$jokers_total (épuisés)${NC}"
    echo -e "${YELLOW}⏰ Rechargement automatique demain${NC}"
  fi
  echo

  # Utiliser gum pour afficher le menu
  gum choose \
    --cursor="➤ " \
    --selected.foreground="#00ff00" \
    --cursor.foreground="#0099ff" \
    "${menu_options[@]}"
}

handle_main_menu() {
  local choice="$1"

  case "$choice" in
    *"Mission en cours"*)
      show_current_mission_details
      ;;
    *"Terminer la mission"*)
      mission_validate
      ;;
    *"Urgence & Jokers"*)
      show_emergency_menu
      ;;
    *"Peine encourue"*)
      show_punishment_info
      ;;
    *"Challenges"*)
      show_challenges_menu
      ;;
    *"Statistiques"*)
      stats_display
      ;;
    *"Paramètres"*)
      show_settings_menu
      ;;
    *"Quitter"*)
      ui_success "Au revoir ! Session fermée."
      exit 0
      ;;
    *)
      ui_warning "Option non reconnue"
      ;;
  esac
}

# ============================================================================
# FONCTION DE DEBUG pour tester Hyprland
# ============================================================================

debug_hyprland_support() {
  ui_header "🔍 Diagnostic Hyprland"
  
  echo "Environment:"
  echo "  WAYLAND_DISPLAY: ${WAYLAND_DISPLAY:-'non défini'}"
  echo "  XDG_CURRENT_DESKTOP: ${XDG_CURRENT_DESKTOP:-'non défini'}"
  echo "  HYPRLAND_INSTANCE_SIGNATURE: ${HYPRLAND_INSTANCE_SIGNATURE:-'non défini'}"
  echo ""
  
  echo "Outils Hyprland:"
  if command -v hyprctl &>/dev/null; then
    echo "  ✓ hyprctl disponible"
    echo "    Version: $(hyprctl version | head -n1)"
    echo "    Sensibilité actuelle: $(hyprctl getoption input:sensitivity | grep -oP 'float: \K[0-9.-]+' || echo 'N/A')"
  else
    echo "  ✗ hyprctl non trouvé"
  fi
  
  echo ""
  echo "Outils wallpaper:"
  command -v swww >/dev/null && echo "  ✓ swww (recommandé)" || echo "  ✗ swww"
  command -v hyprpaper >/dev/null && echo "  ✓ hyprpaper" || echo "  ✗ hyprpaper"  
  command -v swaybg >/dev/null && echo "  ✓ swaybg (fallback)" || echo "  ✗ swaybg"
  
  echo ""
  echo "Test sensibilité:"
  if command -v hyprctl &>/dev/null; then
    echo "  Test modification..."
    local original=$(hyprctl getoption input:sensitivity | grep -oP 'float: \K[0-9.-]+' || echo "0")
    hyprctl keyword input:sensitivity -0.5
    sleep 1
    local modified=$(hyprctl getoption input:sensitivity | grep -oP 'float: \K[0-9.-]+' || echo "0")
    hyprctl keyword input:sensitivity "$original"
    
    if [[ "$modified" != "$original" ]]; then
      echo "  ✅ Modification de sensibilité FONCTIONNE"
    else
      echo "  ❌ Modification de sensibilité ÉCHOUE"
    fi
  fi
}

# ============================================================================
# Menu des challenges
# ============================================================================

show_challenges_menu() {
  ui_header "Sélection des Challenges"

  # Vérifier s'il y a déjà une mission
  if ! mission_check_unique_silent; then
    echo
    ui_error "Une mission est déjà en cours !"
    ui_info "Terminez d'abord votre mission actuelle."
    echo
    ui_wait
    return
  fi

  echo
  echo -e "${CYAN}Choisissez votre type de challenge :${NC}"
  echo

  local challenge_choice
  challenge_choice=$(gum choose \
    --cursor="➤ " \
    --selected.foreground="#00ff00" \
    --cursor.foreground="#0099ff" \
    "🔥 Challenge TryHackMe" \
    "📚 Documentation CVE" \
    "🦠 Analyse de malware" \
    "🏴‍☠️ CTF Practice" \
    "🔍 Veille sécurité" \
    "↩️ Retour au menu principal")

  case "$challenge_choice" in
  *"Challenge TryHackMe"*)
    mission_create "Challenge TryHackMe"
    ;;
  *"Documentation CVE"*)
    mission_create "Documentation CVE"
    ;;
  *"Analyse de malware"*)
    mission_create "Analyse de malware"
    ;;
  *"CTF Practice"*)
    mission_create "CTF Practice"
    ;;
  *"Veille sécurité"*)
    mission_create "Veille sécurité"
    ;;
  *"Retour"*)
    return
    ;;
  esac
}

# ============================================================================
# Détails de la mission en cours
# ============================================================================

show_current_mission_details() {
  local mission_data
  mission_data=$(config_get_current_mission)

  if [[ "$mission_data" == "null" ]] || [[ -z "$mission_data" ]]; then
    ui_error "Aucune mission en cours"
    ui_wait
    return
  fi

  ui_header "Mission en Cours"

  local activity difficulty start_time duration theme
  activity=$(echo "$mission_data" | jq -r '.activity')
  difficulty=$(echo "$mission_data" | jq -r '.difficulty')
  start_time=$(echo "$mission_data" | jq -r '.start_time')
  duration=$(echo "$mission_data" | jq -r '.duration')
  theme=$(echo "$mission_data" | jq -r '.theme // ""')

  local current_time elapsed remaining
  current_time=$(date +%s)
  elapsed=$((current_time - start_time))
  remaining=$((duration - elapsed))

  local status_color="#4A90E2"
  local status_text="EN COURS"

  if [[ $remaining -le 0 ]]; then
    status_color="#FF6B6B"
    status_text="TEMPS ÉCOULÉ"
    remaining=0
  elif [[ $remaining -le 300 ]]; then
    status_color="#FFA500"
    status_text="URGENT"
  fi

  local elapsed_formatted remaining_formatted duration_formatted
  elapsed_formatted=$(format_time $elapsed)
  remaining_formatted=$(format_time $remaining)
  duration_formatted=$(format_time $duration)

  local percentage
  if [[ $duration -gt 0 ]]; then
    percentage=$((elapsed * 100 / duration))
    if [[ $percentage -gt 100 ]]; then
      percentage=100
    fi
  else
    percentage=0
  fi

  # Construire le contenu
  local content="🎯 Activité: $activity|⚡ Difficulté: $difficulty|⏰ Temps total: $duration_formatted|⌛ Temps écoulé: $elapsed_formatted|⏳ Temps restant: $remaining_formatted|📊 Progression: $percentage%"

  if [[ -n "$theme" && "$theme" != "null" ]]; then
    content+="|🎨 Thème: $theme"
  fi

  ui_box "📋 MISSION ACTIVE: $status_text" "$content" "$status_color"

  echo
  ui_progress_bar $elapsed $duration "Avancement"
  echo

  if [[ $remaining -le 0 ]]; then
    ui_warning "⚠️ Le temps imparti est écoulé !"
    ui_info "Utilisez 'Terminer la mission' pour valider."
  elif [[ $remaining -le 300 ]]; then
    ui_warning "⚠️ Plus que 5 minutes ! Dépêchez-vous !"
  fi

  echo
  ui_wait
}

# ============================================================================
# Menu d'urgence
# ============================================================================
show_emergency_menu() {
  ui_header "🚨 MODE URGENCE"

  local jokers_available jokers_total
  jokers_available=$(config_get_jokers_available)
  jokers_total=$(config_get_jokers_total)

  ui_info "🃏 Jokers de sauvetage disponibles: $jokers_available/$jokers_total"
  ui_warning "⚡ Les jokers permettent d'annuler missions/pénalités SANS conséquences"
  echo

  local mission_data
  mission_data=$(config_get_current_mission)

  local emergency_options=()

  # Options selon l'état
  if [[ "$mission_data" != "null" ]] && [[ -n "$mission_data" ]]; then
    if [[ $jokers_available -gt 0 ]]; then
      emergency_options+=("🃏 Utiliser un joker - Annuler mission SANS pénalité")
    fi
    emergency_options+=("💀 Abandonner mission AVEC pénalités")
  fi

  # Vérifier pénalités actives
  if punishment_has_active_punishments; then
    if [[ $jokers_available -gt 0 ]]; then
      emergency_options+=("🃏 Utiliser un joker - Annuler toutes les pénalités")
    fi
    emergency_options+=("📋 Voir les pénalités en cours")
  fi

  # Options toujours disponibles
  emergency_options+=("🔧 Réinitialisation complète du système")
  emergency_options+=("📊 Diagnostic système")
  emergency_options+=("↩️ Retour au menu principal")

  # Afficher info sur les jokers selon la situation
  if [[ $jokers_available -eq 0 ]]; then
    ui_warning "⚠️ Plus de jokers ! Abandon = pénalités garanties"
    ui_info "💡 Les jokers se rechargent chaque jour (3 par jour)"
    echo
  else
    ui_info "💡 Utilisez vos jokers sagement - ils se rechargent quotidiennement"
    echo
  fi

  local emergency_choice
  emergency_choice=$(gum choose \
    --cursor="➤ " \
    --selected.foreground="#ff0000" \
    --cursor.foreground="#ff0000" \
    "${emergency_options[@]}")

  case "$emergency_choice" in
  *"Annuler mission SANS pénalité"*)
    emergency_cancel_mission_with_joker
    ;;
  *"Annuler toutes les pénalités"*)
    emergency_cancel_punishments_with_joker
    ;;
  *"Abandonner mission AVEC pénalités"*)
    emergency_force_cancel_mission
    ;;
  *"Voir les pénalités"*)
    punishment_list_active
    ui_wait
    ;;
  *"Réinitialisation complète"*)
    emergency_full_reset_with_confirmation
    ;;
  *"Diagnostic système"*)
    emergency_system_status
    ;;
  *"Retour"*)
    return
    ;;
  esac

  echo
  ui_wait
}

emergency_force_cancel_mission() {
  ui_error "💀 ABANDON DE MISSION SANS JOKER"
  ui_warning "Cette action va appliquer immédiatement les pénalités d'échec !"
  echo

  local mission_data
  mission_data=$(config_get_current_mission)

  if [[ "$mission_data" != "null" ]] && [[ -n "$mission_data" ]]; then
    local activity difficulty
    activity=$(echo "$mission_data" | jq -r '.activity')
    difficulty=$(echo "$mission_data" | jq -r '.difficulty')

    ui_box "💀 CONSÉQUENCES DE L'ABANDON" \
      "Mission: $activity ($difficulty)|Statut: Sera marquée comme ÉCHOUÉE|Pénalité: Application IMMÉDIATE d'une pénalité|Durée: 30-60 minutes selon le type||Types possibles:|🔒 Verrouillage d'écran|🌐 Restriction réseau|🚫 Blocage de sites|🖼️ Wallpaper motivationnel|📢 Notifications de rappel|🖱️ Réduction sensibilité souris||⚠️ CETTE ACTION EST IRRÉVERSIBLE" \
      "#FF0000"

    echo
    ui_error "💡 SUGGESTION: Retournez terminer votre mission ou attendez d'avoir un joker !"
    echo
  fi

  # Double confirmation pour être sûr
  if ui_confirm "Êtes-vous ABSOLUMENT sûr de vouloir abandonner AVEC pénalités ?"; then
    ui_error "⚠️ DERNIÈRE CHANCE ! Voulez-vous vraiment subir une pénalité ?"

    local final_choice
    final_choice=$(gum choose \
      --cursor="➤ " \
      --selected.foreground="#ff0000" \
      "💀 OUI, appliquer les pénalités maintenant" \
      "🏃 NON, retourner à ma mission" \
      "🕐 ATTENDRE d'avoir un joker (retour menu)")

    case "$final_choice" in
    *"OUI, appliquer"*)
      if [[ "$mission_data" != "null" ]] && [[ -n "$mission_data" ]]; then
        local activity difficulty
        activity=$(echo "$mission_data" | jq -r '.activity')
        difficulty=$(echo "$mission_data" | jq -r '.difficulty')

        # Marquer comme échouée et appliquer pénalités
        config_fail_mission
        stats_record_completion "$activity" false "$difficulty"
        config_clear_mission

        ui_error "Mission abandonnée et marquée comme échouée."
        ui_warning "Application immédiate des pénalités..."

        # Appliquer la pénalité immédiatement
        punishment_apply_random
      fi
      ;;
    *"retourner à ma mission"*)
      ui_success "Sage décision ! Retournez terminer votre mission."
      ui_info "💪 Chaque effort compte pour progresser !"
      ;;
    *"ATTENDRE"*)
      ui_info "Vous retournez au menu. Mission toujours active."
      ui_info "💡 Revenez plus tard quand vous aurez récupéré un joker"
      ;;
    esac
  else
    ui_success "Abandon annulé. Votre mission reste active."
  fi
}

emergency_full_reset_with_confirmation() {
  ui_warning "🔧 RÉINITIALISATION COMPLÈTE DU SYSTÈME"
  ui_error "⚠️ ATTENTION: Cette action va tout arrêter et nettoyer"
  echo

  ui_box "🚨 ACTIONS DE LA RÉINITIALISATION" \
    "• Arrêter toutes les missions (SANS pénalité)|• Stopper toutes les pénalités en cours|• Nettoyer tous les processus système|• Restaurer les paramètres par défaut||✅ LES STATISTIQUES SERONT PRÉSERVÉES|⚠️ Cette action ne consomme PAS de joker" \
    "#FFA500"

  echo
  ui_info "🛡️ Cette fonction est réservée aux cas de dysfonctionnement grave"
  ui_warning "Elle ne doit PAS être utilisée pour éviter les pénalités normales"
  echo

  if ui_confirm "Effectuer une réinitialisation complète ?"; then
    if ui_confirm "Êtes-vous CERTAIN ? Cette action va tout nettoyer."; then
      echo
      ui_info "Début de la réinitialisation complète..."

      # Arrêter mission sans pénalité (cas exceptionnel)
      config_clear_mission
      ui_success "✓ Mission arrêtée"

      # Stopper pénalités
      punishment_emergency_stop >/dev/null 2>&1
      ui_success "✓ Pénalités stoppées"

      # Nettoyer processus
      pkill -f "learning.*timer" 2>/dev/null || true
      pkill -f "punishment" 2>/dev/null || true
      ui_success "✓ Processus nettoyés"

      # Nettoyer fichiers temporaires
      rm -f "$CONFIG_DIR"/timer.pid
      rm -f "$CONFIG_DIR"/current_mission.json
      rm -f "$CONFIG_DIR"/timer_status
      rm -f "$CONFIG_DIR"/notifications.log
      ui_success "✓ Fichiers temporaires supprimés"

      echo
      ui_success "🎉 Réinitialisation terminée !"
      ui_info "Le système est maintenant dans un état propre"
    else
      ui_info "Réinitialisation annulée"
    fi
  else
    ui_info "Réinitialisation annulée"
  fi
}

emergency_cancel_punishments_with_joker() {
  ui_warning "🃏 UTILISATION D'UN JOKER DE SAUVETAGE"
  ui_info "Cette action va annuler TOUTES les pénalités en cours."
  echo

  ui_box "📋 PÉNALITÉS ACTIVES" \
    "$(punishment_get_active_list)" \
    "#FF6B6B"

  echo

  local jokers_remaining
  jokers_remaining=$(($(config_get_jokers_available) - 1))

  ui_warning "Jokers restants après cette action: $jokers_remaining/3"
  echo

  if ui_confirm "Utiliser un joker pour annuler toutes les pénalités ?"; then
    config_use_joker
    punishment_emergency_stop

    ui_success "🎉 Toutes les pénalités ont été annulées grâce au joker !"
    ui_info "Votre joker a été consommé. Jokers restants: $jokers_remaining/3"
  else
    ui_info "Joker non utilisé."
  fi
}

emergency_full_reset() {
  ui_warning "ATTENTION: Cette action va:"
  echo "  • Arrêter toutes les missions"
  echo "  • Stopper toutes les pénalités"
  echo "  • Nettoyer tous les processus"
  echo "  • Restaurer les paramètres système"
  echo
  ui_info "LES STATISTIQUES SERONT PRÉSERVÉES"
  echo

  if ui_confirm "Êtes-vous ABSOLUMENT sûr ?"; then
    echo
    ui_info "Début de la réinitialisation..."

    config_clear_mission
    ui_success "✓ Mission arrêtée"

    punishment_emergency_stop >/dev/null 2>&1
    ui_success "✓ Pénalités stoppées"

    pkill -f "learning.*timer" 2>/dev/null || true
    pkill -f "punishment" 2>/dev/null || true
    ui_success "✓ Processus nettoyés"

    rm -f "$CONFIG_DIR"/timer.pid
    rm -f "$CONFIG_DIR"/current_mission.json
    rm -f "$CONFIG_DIR"/timer_status
    rm -f "$CONFIG_DIR"/notifications.log
    ui_success "✓ Fichiers temporaires supprimés"

    echo
    ui_success "🎉 Réinitialisation terminée !"
  fi
}

emergency_system_status() {
  ui_header "État du système"

  echo
  ui_info "📁 Fichiers de configuration :"
  [[ -f "$CONFIG_DIR/config.json" ]] && echo "  ✓ config.json présent" || echo "  ❌ config.json manquant"
  [[ -f "$CONFIG_DIR/stats.json" ]] && echo "  ✓ stats.json présent" || echo "  ❌ stats.json manquant"
  [[ -f "$CONFIG_DIR/current_mission.json" ]] && echo "  ⚠️ Mission active détectée" || echo "  ✓ Aucune mission active"

  echo
  ui_info "🔧 Processus actifs :"
  local processes_found=false
  if pgrep -f "learning.*timer" >/dev/null 2>&1; then
    echo "  ⚠️ Timer en cours"
    processes_found=true
  fi
  if pgrep -f "punishment" >/dev/null 2>&1; then
    echo "  ⚠️ Pénalités actives"
    processes_found=true
  fi
  [[ "$processes_found" == false ]] && echo "  ✓ Aucun processus actif"

  echo
  ui_info "💾 Utilisation espace :"
  if [[ -d "$CONFIG_DIR" ]]; then
    local size
    size=$(du -sh "$CONFIG_DIR" 2>/dev/null | cut -f1 || echo "Inconnu")
    echo "  Configuration: $size"
  fi
}

# ============================================================================
# Informations sur les pénalités
# ============================================================================

show_punishment_info() {
  ui_header "💀 Informations sur les Pénalités"

  local min_duration max_duration
  min_duration=$(config_get '.punishment_settings.min_duration')
  max_duration=$(config_get '.punishment_settings.max_duration')

  ui_box "⚠️ PÉNALITÉS EN CAS D'ÉCHEC" \
    "En cas d'échec de mission, une pénalité aléatoire sera appliquée.|Durée: entre $min_duration et $max_duration minutes||Types de pénalités possibles:|🔒 Verrouillage d'écran temporaire|🌐 Restriction du réseau|🚫 Blocage de sites distractifs|🖼️ Changement de fond d'écran|📢 Notifications de rappel|🖱️ Réduction sensibilité souris||Ces pénalités sont motivationnelles et temporaires." \
    "#FF6B6B"

  echo
  ui_info "🎯 Pénalités actuellement actives :"
  punishment_list_active

  echo
  ui_wait
}

# ============================================================================
# Menu des paramètres
# ============================================================================

show_settings_menu() {
  ui_header "⚙️ Paramètres"

  echo
  local settings_choice
  settings_choice=$(gum choose \
    --cursor="➤ " \
    --selected.foreground="#00ff00" \
    --cursor.foreground="#0099ff" \
    "🎯 Modifier les durées par difficulté" \
    "💀 Configuration des pénalités" \
    "🔔 Paramètres de notifications" \
    "🔄 Réinitialiser les statistiques" \
    "📁 Voir dossier de configuration" \
    "📤 Exporter les statistiques" \
    "↩️ Retour au menu principal")

  case "$settings_choice" in
  *"durées par difficulté"*)
    config_modify_durations
    ;;
  *"Configuration des pénalités"*)
    show_punishment_settings
    ;;
  *"Paramètres de notifications"*)
    show_notification_settings
    ;;
  *"Réinitialiser les statistiques"*)
    if ui_confirm "Êtes-vous sûr de vouloir réinitialiser toutes les statistiques ?"; then
      stats_reset
      ui_success "Statistiques réinitialisées"
    fi
    ;;
  *"Voir dossier"*)
    ui_info "Dossier de configuration : $CONFIG_DIR"
    if command -v xdg-open &>/dev/null; then
      if ui_confirm "Ouvrir le dossier dans le gestionnaire de fichiers ?"; then
        xdg-open "$CONFIG_DIR"
      fi
    fi
    ;;
  *"Exporter"*)
    stats_export
    ;;
  *"Retour"*)
    return
    ;;
  esac

  echo
  ui_wait
}

show_punishment_settings() {
  ui_header "Configuration des Pénalités"

  local enabled min_dur max_dur
  enabled=$(config_get '.punishment_settings.enabled')
  min_dur=$(config_get '.punishment_settings.min_duration')
  max_dur=$(config_get '.punishment_settings.max_duration')

  echo
  ui_info "Configuration actuelle :"
  echo "  Pénalités: $([ "$enabled" = "true" ] && echo "Activées" || echo "Désactivées")"
  echo "  Durée minimum: $min_dur minutes"
  echo "  Durée maximum: $max_dur minutes"
  echo

  local choice
  choice=$(gum choose \
    "$([ "$enabled" = "true" ] && echo "🔴 Désactiver" || echo "🟢 Activer") les pénalités" \
    "🕐 Modifier durée minimum" \
    "🕑 Modifier durée maximum" \
    "↩️ Retour")

  case "$choice" in
  *"Désactiver"*)
    config_set '.punishment_settings.enabled' false
    ui_success "Pénalités désactivées"
    ;;
  *"Activer"*)
    config_set '.punishment_settings.enabled' true
    ui_success "Pénalités activées"
    ;;
  *"durée minimum"*)
    local new_min
    new_min=$(ui_input "Nouvelle durée minimum (minutes)" "$min_dur")
    if [[ "$new_min" =~ ^[0-9]+$ ]] && [[ $new_min -gt 0 ]]; then
      config_set '.punishment_settings.min_duration' "$new_min"
      ui_success "Durée minimum mise à jour"
    else
      ui_error "Valeur invalide"
    fi
    ;;
  *"durée maximum"*)
    local new_max
    new_max=$(ui_input "Nouvelle durée maximum (minutes)" "$max_dur")
    if [[ "$new_max" =~ ^[0-9]+$ ]] && [[ $new_max -gt 0 ]]; then
      config_set '.punishment_settings.max_duration' "$new_max"
      ui_success "Durée maximum mise à jour"
    else
      ui_error "Valeur invalide"
    fi
    ;;
  esac
}

show_notification_settings() {
  ui_header "Paramètres de Notifications"

  local notif_enabled sound_enabled
  notif_enabled=$(config_get '.notifications.enabled')
  sound_enabled=$(config_get '.notifications.sound')

  echo
  ui_info "Configuration actuelle :"
  echo "  Notifications: $([ "$notif_enabled" = "true" ] && echo "Activées" || echo "Désactivées")"
  echo "  Sons d'alerte: $([ "$sound_enabled" = "true" ] && echo "Activés" || echo "Désactivés")"
  echo

  local choice
  choice=$(gum choose \
    "$([ "$notif_enabled" = "true" ] && echo "🔴 Désactiver" || echo "🟢 Activer") les notifications" \
    "$([ "$sound_enabled" = "true" ] && echo "🔇 Désactiver" || echo "🔊 Activer") les sons" \
    "↩️ Retour")

  case "$choice" in
  *"Désactiver les notifications"*)
    config_set '.notifications.enabled' false
    ui_success "Notifications désactivées"
    ;;
  *"Activer les notifications"*)
    config_set '.notifications.enabled' true
    ui_success "Notifications activées"
    ;;
  *"Désactiver les sons"*)
    config_set '.notifications.sound' false
    ui_success "Sons désactivés"
    ;;
  *"Activer les sons"*)
    config_set '.notifications.sound' true
    ui_success "Sons activés"
    ;;
  esac
}

# ============================================================================
# Fonctions utilitaires
# ============================================================================

mission_check_unique_silent() {
  local mission_data
  mission_data=$(config_get_current_mission)

  if [[ "$mission_data" != "null" ]] && [[ -n "$mission_data" ]]; then
    return 1
  fi
  return 0
}

# ============================================================================
# Boucle principale
# ============================================================================

main_loop() {
  while true; do
    ui_header "Learning Challenge Manager"

    # Afficher mission en cours si elle existe
    mission_display_current

    local choice
    if ! choice=$(show_main_menu); then
      ui_warning "Sélection annulée"
      continue
    fi

    handle_main_menu "$choice"

    echo
    sleep 0.5
  done
}

# ============================================================================
# Point d'entrée principal
# ============================================================================

main() {
  # Vérifier le mode admin avec gestion sécurisée des arguments
  local first_arg="${1:-}"
  if [[ "$first_arg" == "--admin" ]] || [[ "$first_arg" == "admin" ]]; then
    echo "Mode admin détecté mais module non encore implémenté"
    echo "Utilisez: ./bin/admin-emergency.sh"
    exit 0
  fi
  
  check_dependencies
  config_init

  mkdir -p "$CONFIG_DIR" "$BIN_DIR"

  echo
  ui_success "Learning Challenge Manager initialisé"
  echo

  main_loop
}


# Gestion des signaux
trap 'echo; ui_warning "Interruption détectée. Session fermée."; exit 130' INT TERM

# Lancer le programme
main "$@"

# ============================================================================
# MODE ADMIN - Système d'arrêt d'urgence des pénalités
# ============================================================================

admin_mode_check() {
  local arg="${1:-}"  # Valeur par défaut vide si pas d'argument
  
  # Vérifier si l'argument --admin est passé
  if [[ "$arg" == "--admin" ]]; then
    admin_mode_main
    exit 0
  fi
  
  # Vérifier argument "admin"
  if [[ "$arg" == "admin" ]]; then
    admin_mode_main
    exit 0
  fi
}

# ============================================================================
# 3. VÉRIFICATION DE L'INSTALLATION
# ============================================================================

# Script de vérification - à exécuter pour diagnostiquer les problèmes

check_installation() {
    echo "🔍 Vérification de l'installation..."
    echo ""
    
    # Vérifier structure des dossiers
    local base_dir="$(pwd)"
    echo "📁 Répertoire actuel: $base_dir"
    
    local required_files=(
        "learning.sh"
        "lib/config.sh"
        "lib/ui.sh"
        "lib/mission.sh"
        "lib/stats.sh"
        "lib/timer.sh"
        "lib/punishment.sh"
    )
    
    echo ""
    echo "📋 Fichiers requis:"
    local missing_files=()
    
    for file in "${required_files[@]}"; do
        if [[ -f "$file" ]]; then
            echo "  ✅ $file"
        else
            echo "  ❌ $file (MANQUANT)"
            missing_files+=("$file")
        fi
    done
    
    # Vérifier lib/admin.sh
    echo ""
    if [[ -f "lib/admin.sh" ]]; then
        echo "✅ lib/admin.sh présent"
    else
        echo "⚠️ lib/admin.sh manquant (sera créé automatiquement)"
    fi
    
    # Vérifier bin/admin-emergency.sh
    echo ""
    if [[ -f "bin/admin-emergency.sh" ]]; then
        echo "✅ bin/admin-emergency.sh présent"
    else
        echo "⚠️ bin/admin-emergency.sh manquant"
    fi
    
    # Vérifier les permissions
    echo ""
    echo "🔐 Permissions:"
    if [[ -x "learning.sh" ]]; then
        echo "  ✅ learning.sh exécutable"
    else
        echo "  ⚠️ learning.sh non exécutable (chmod +x learning.sh)"
    fi
    
    if [[ -f "bin/admin-emergency.sh" ]] && [[ -x "bin/admin-emergency.sh" ]]; then
        echo "  ✅ admin-emergency.sh exécutable"
    elif [[ -f "bin/admin-emergency.sh" ]]; then
        echo "  ⚠️ admin-emergency.sh non exécutable (chmod +x bin/admin-emergency.sh)"
    fi
    
    # Résumé
    echo ""
    if [[ ${#missing_files[@]} -eq 0 ]]; then
        echo "🎉 Installation correcte !"
        echo ""
        echo "🚀 Utilisation:"
        echo "  Normal: ./learning.sh"
        echo "  Admin: ./learning.sh --admin"
        echo "  Urgence: ./bin/admin-emergency.sh"
    else
        echo "❌ Installation incomplète"
        echo "Fichiers manquants: ${missing_files[*]}"
    fi
}

repair_installation() {
    echo "🔧 Réparation automatique..."
    
    # Créer les dossiers manquants
    mkdir -p lib bin
    
    # Réparer les permissions
    chmod +x learning.sh 2>/dev/null || true
    
    # Créer admin-emergency.sh corrigé
    cat > bin/admin-emergency.sh << 'EMERGENCY_EOF'
#!/bin/bash
# Script d'urgence admin - Version corrigée

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PARENT_DIR="$(dirname "$SCRIPT_DIR")"
CONFIG_DIR="$HOME/.learning_challenge"
LIB_DIR="$PARENT_DIR/lib"

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
EMERGENCY_EOF

    chmod +x bin/admin-emergency.sh
    
    echo "✅ Réparation terminée"
}

