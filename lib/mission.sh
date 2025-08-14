#!/bin/bash

# ============================================================================
# Mission Module - Gestion des missions et de leur cycle de vie
# ============================================================================

readonly DIFFICULTIES=("Easy" "Medium" "Hard")

# Thèmes par activité et difficulté
declare -A CVE_THEMES_EASY=(
  ["1"]="Analyser 1 CVE récente (score CVSS < 7)"
  ["2"]="Documenter une vulnérabilité web basique"
  ["3"]="Rechercher des CVE dans un logiciel spécifique"
)

declare -A CVE_THEMES_MEDIUM=(
  ["1"]="Analyser 2-3 CVE critiques (score CVSS > 7)"
  ["2"]="Créer un rapport détaillé d'une CVE avec POC"
  ["3"]="Comparer l'évolution d'une famille de vulnérabilités"
)

declare -A CVE_THEMES_HARD=(
  ["1"]="Analyser 3-5 CVE avec chaîne d'exploitation"
  ["2"]="Rédiger un guide de mitigation complet"
  ["3"]="Analyser l'impact d'une CVE sur plusieurs systèmes"
)

declare -A MALWARE_THEMES_EASY=(
  ["1"]="Analyse statique basique d'un malware connu"
  ["2"]="Identifier les IoC d'un échantillon simple"
  ["3"]="Documenter le comportement d'un adware"
)

declare -A MALWARE_THEMES_MEDIUM=(
  ["1"]="Reverse engineering d'un trojan"
  ["2"]="Analyse dynamique avec sandbox"
  ["3"]="Décrypter la communication C&C"
)

declare -A MALWARE_THEMES_HARD=(
  ["1"]="Analyse complète d'un APT sophistiqué"
  ["2"]="Désobfuscation et unpacking avancé"
  ["3"]="Développer des signatures de détection"
)

declare -A CTF_THEMES_EASY=(
  ["1"]="Résoudre 3-5 challenges Web faciles"
  ["2"]="Challenges de cryptographie basique"
  ["3"]="Forensics sur des fichiers simples"
)

declare -A CTF_THEMES_MEDIUM=(
  ["1"]="Résoudre 2-3 challenges de reverse engineering"
  ["2"]="Pwn de binaires avec protections basiques"
  ["3"]="Stéganographie et forensics avancés"
)

declare -A CTF_THEMES_HARD=(
  ["1"]="Exploitation de vulnérabilités 0-day"
  ["2"]="Reverse engineering de malware obfusqué"
  ["3"]="Challenges de cryptanalyse avancée"
)

declare -A VEILLE_THEMES_EASY=(
  ["1"]="Résumé des actualités cyber de la semaine"
  ["2"]="Analyser 3 nouvelles techniques d'attaque"
  ["3"]="Veille sur un secteur spécifique (santé, finance...)"
)

declare -A VEILLE_THEMES_MEDIUM=(
  ["1"]="Rapport détaillé sur une campagne APT récente"
  ["2"]="Analyse des tendances cyber du mois"
  ["3"]="Étude comparative d'outils de sécurité"
)

declare -A VEILLE_THEMES_HARD=(
  ["1"]="Analyse géopolitique des cybermenaces"
  ["2"]="Prédictions et prospective cybersécurité"
  ["3"]="Rapport stratégique pour décideurs"
)

# ============================================================================
# Vérification de mission unique
# ============================================================================

mission_check_unique() {
  local mission_data
  mission_data=$(config_get_current_mission)

  if [[ "$mission_data" != "null" ]] && [[ -n "$mission_data" ]]; then
    local activity difficulty start_time duration
    activity=$(echo "$mission_data" | jq -r '.activity')
    difficulty=$(echo "$mission_data" | jq -r '.difficulty // "Unknown"')
    start_time=$(echo "$mission_data" | jq -r '.start_time')
    duration=$(echo "$mission_data" | jq -r '.duration')

    local current_time elapsed remaining
    current_time=$(date +%s)
    elapsed=$((current_time - start_time))
    remaining=$((duration - elapsed))

    ui_error "Mission déjà en cours !"
    echo

    if [[ $remaining -gt 0 ]]; then
      local remaining_formatted
      remaining_formatted=$(format_time $remaining)
      ui_current_mission "$activity" "$difficulty" "$remaining_formatted"
    else
      ui_warning "⏰ Mission en cours (temps écoulé)"
      ui_current_mission "$activity" "$difficulty" "TEMPS ÉCOULÉ"
    fi

    echo
    ui_info "Terminez d'abord votre mission actuelle avec 'Terminer la mission'"
    ui_info "Ou annulez-la avec 'Urgence'"

    return 1
  fi

  return 0
}

mission_check_unique_silent() {
  local mission_data
  mission_data=$(config_get_current_mission)

  if [[ "$mission_data" != "null" ]] && [[ -n "$mission_data" ]]; then
    return 1 # Mission en cours
  fi
  return 0 # Pas de mission
}

# ============================================================================
# Génération de missions par type
# ============================================================================

mission_create() {
  local activity=$1

  # Vérifier qu'aucune mission n'est en cours
  if ! mission_check_unique; then
    return 1
  fi

  case "$activity" in
  "Challenge TryHackMe")
    mission_create_tryhackme
    ;;
  "Documentation CVE")
    mission_create_themed "CVE" "Documentation CVE"
    ;;
  "Analyse de malware")
    mission_create_themed "MALWARE" "Analyse de malware"
    ;;
  "CTF Practice")
    mission_create_themed "CTF" "CTF Practice"
    ;;
  "Veille sécurité")
    mission_create_themed "VEILLE" "Veille sécurité"
    ;;
  *)
    ui_error "Type d'activité non supporté: $activity"
    return 1
    ;;
  esac
}

mission_create_tryhackme() {
  # Pour TryHackMe, système aléatoire classique
  local difficulty
  difficulty=$(mission_get_random_difficulty)

  local duration
  duration=$(config_get_duration "$difficulty")

  local time_formatted
  time_formatted=$(format_time "$duration")

  echo
  ui_mission_box "Challenge TryHackMe" "$difficulty" "$time_formatted"
  echo

  local choice
  choice=$(gum choose \
    --cursor="➤ " \
    --selected.foreground="#00ff00" \
    "✅ Accepter cette mission" \
    "🔄 Regénérer (aléatoire)" \
    "❌ Retour au menu")

  case "$choice" in
  *"Accepter"*)
    mission_start "Challenge TryHackMe" "$difficulty" "$duration" ""
    ;;
  *"Regénérer"*)
    ui_info "Nouvelle mission générée..."
    sleep 1
    # CORRECTION: revenir au menu de choix, pas auto-accepter
    mission_create_tryhackme
    ;;
  *"Retour"*)
    return 0
    ;;
  esac
}

# ============================================================================
# Fonctions utilitaires manquantes
# ============================================================================

mission_get_random_difficulty() {
  local random_index=$((RANDOM % ${#DIFFICULTIES[@]}))
  echo "${DIFFICULTIES[$random_index]}"
}

mission_get_random_theme() {
  local theme_type=$1
  local difficulty=$2

  local -n themes_ref="${theme_type}_THEMES_${difficulty^^}"
  local theme_keys=(${!themes_ref[@]})
  local random_key=${theme_keys[$((RANDOM % ${#theme_keys[@]}))]}

  echo "${themes_ref[$random_key]}"
}

mission_check_unique_silent() {
  local mission_data
  mission_data=$(config_get_current_mission)

  if [[ "$mission_data" != "null" ]] && [[ -n "$mission_data" ]]; then
    return 1
  fi
  return 0
}

mission_show_theme_choice() {
  local theme_type=$1
  local activity_name=$2
  local diff_level=$3

  # Obtenir un thème aléatoire
  local theme
  theme=$(mission_get_random_theme "$theme_type" "$diff_level")

  local duration
  duration=$(config_get_duration "$diff_level")

  local time_formatted
  time_formatted=$(format_time "$duration")

  echo
  ui_themed_mission_box "$activity_name" "$diff_level" "$time_formatted" "$theme"
  echo

  local choice
  choice=$(gum choose \
    --cursor="➤ " \
    --selected.foreground="#00ff00" \
    "✅ Accepter cette mission" \
    "🔄 Nouveau thème (même difficulté)" \
    "🔄 Changer de difficulté" \
    "❌ Retour au menu")

  case "$choice" in
  *"Accepter"*)
    mission_start "$activity_name" "$diff_level" "$duration" "$theme"
    ;;
  *"Nouveau thème"*)
    ui_info "Nouveau thème généré..."
    sleep 1
    # CORRECTION: revenir au menu de choix avec nouveau thème
    mission_show_theme_choice "$theme_type" "$activity_name" "$diff_level"
    ;;
  *"Changer de difficulté"*)
    mission_create_themed "$theme_type" "$activity_name"
    ;;
  *"Retour"*)
    return 0
    ;;
  esac
}

mission_create_themed() {
  local theme_type=$1
  local activity_name=$2

  echo
  echo -e "${CYAN}Choisissez la difficulté pour $activity_name :${NC}"
  echo

  local difficulty
  difficulty=$(gum choose \
    --cursor="➤ " \
    --selected.foreground="#00ff00" \
    "Easy (2h)" \
    "Medium (3h)" \
    "Hard (4h)" \
    "↩️ Retour au menu challenges")

  # Gérer le retour
  if [[ "$difficulty" == *"Retour"* ]]; then
    return 0
  fi

  # Extraire la difficulté
  local diff_level
  case "$difficulty" in
  "Easy (2h)") diff_level="Easy" ;;
  "Medium (3h)") diff_level="Medium" ;;
  "Hard (4h)") diff_level="Hard" ;;
  *)
    ui_error "Difficulté non reconnue"
    return 1
    ;;
  esac

  # Fonction pour afficher et choisir le thème
  mission_show_theme_choice "$theme_type" "$activity_name" "$diff_level"
}

mission_get_random_theme() {
  local theme_type=$1
  local difficulty=$2

  local -n themes_ref="${theme_type}_THEMES_${difficulty^^}"
  local theme_keys=(${!themes_ref[@]})
  local random_key=${theme_keys[$((RANDOM % ${#theme_keys[@]}))]}

  echo "${themes_ref[$random_key]}"
}

# ============================================================================
# Démarrage des missions
# ============================================================================

mission_start() {
  local activity=$1
  local difficulty=$2
  local duration=$3
  local theme=${4:-""}

  # Sauvegarder la mission avec le thème
  config_save_mission "$activity" "$difficulty" "$duration" "$theme"

  # Lancer le timer
  timer_start "$duration"

  # Affichage de confirmation
  ui_clear
  ui_header "Mission Lancée"

  local time_formatted
  time_formatted=$(format_time "$duration")

  if [[ -n "$theme" ]]; then
    ui_box "🚀 MISSION ACTIVE AVEC THÈME" \
      "📋 $activity|⚡ Difficulté: $difficulty|⏰ Temps: $time_formatted||🎯 Thème: $theme||💪 Bon travail !" \
      "#00FF00"
  else
    ui_box "🚀 MISSION ACTIVE" \
      "📋 $activity|⚡ Difficulté: $difficulty|⏰ Temps: $time_formatted||💪 Bon travail !" \
      "#00FF00"
  fi

  echo
  ui_success "Mission démarrée ! Timer en cours d'exécution."
  ui_info "Revenez au menu principal pour suivre votre progression."

  ui_wait
}

# ============================================================================
# Affichage des missions
# ============================================================================

mission_display_current() {
  local mission_data
  mission_data=$(config_get_current_mission)

  if [[ "$mission_data" == "null" ]] || [[ -z "$mission_data" ]]; then
    return 0
  fi

  local activity difficulty start_time duration status theme
  activity=$(echo "$mission_data" | jq -r '.activity')
  difficulty=$(echo "$mission_data" | jq -r '.difficulty')
  start_time=$(echo "$mission_data" | jq -r '.start_time')
  duration=$(echo "$mission_data" | jq -r '.duration')
  status=$(echo "$mission_data" | jq -r '.status // "active"')
  theme=$(echo "$mission_data" | jq -r '.theme // ""')

  if [[ "$status" == "active" ]]; then
    local current_time elapsed remaining
    current_time=$(date +%s)
    elapsed=$((current_time - start_time))
    remaining=$((duration - elapsed))

    if [[ $remaining -gt 0 ]]; then
      local remaining_formatted
      remaining_formatted=$(format_time $remaining)

      if [[ -n "$theme" && "$theme" != "null" ]]; then
        ui_current_mission_with_theme "$activity" "$difficulty" "$remaining_formatted" "$theme"
      else
        ui_current_mission "$activity" "$difficulty" "$remaining_formatted"
      fi
    else
      ui_warning "⏰ Temps écoulé ! Mission en attente de validation."
      echo
    fi
  fi
}

# ============================================================================
# Validation et complétion avec navigation améliorée
# ============================================================================

mission_validate() {
  local mission_data
  mission_data=$(config_get_current_mission)

  if [[ "$mission_data" == "null" ]] || [[ -z "$mission_data" ]]; then
    ui_error "Aucune mission active à valider"
    ui_wait
    return 1
  fi

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

  ui_header "Validation de Mission"

  local validation_content="Activité: $activity|Difficulté: $difficulty|Temps écoulé: $(format_time $elapsed)"
  if [[ -n "$theme" && "$theme" != "null" ]]; then
    validation_content+="|Thème: $theme"
  fi

  # Affichage avec statut selon le temps
  if [[ $remaining -le 0 ]]; then
    ui_box "⏰ MISSION EN RETARD" "$validation_content|Temps imparti: DÉPASSÉ de $(format_time $((elapsed - duration)))" "#FF0000"
  else
    ui_box "📋 MISSION À VALIDER" "$validation_content|Temps restant: $(format_time $remaining)" "#FFA500"
  fi

  echo

  # Menu de validation avec avertissement si en retard
  local validation_options=()
  
  if [[ $remaining -le 0 ]]; then
    validation_options+=("✅ Mission terminée avec succès (malgré le retard)")
    validation_options+=("❌ Mission échouée/non terminée + PÉNALITÉ")
  else
    validation_options+=("✅ Mission terminée avec succès")
    validation_options+=("❌ Mission échouée/non terminée + PÉNALITÉ")
  fi
  
  validation_options+=("↩️ Retour au menu principal (sans valider)")

  local validation_choice
  validation_choice=$(gum choose \
    --cursor="➤ " \
    --selected.foreground="#00ff00" \
    "${validation_options[@]}")

  case "$validation_choice" in
    *"terminée avec succès"*)
      mission_complete_success "$activity" "$difficulty" $elapsed $remaining
      ;;
    *"échouée/non terminée"*)
      mission_complete_failure "$activity" "$difficulty" true
      ;;
    *"Retour"*)
      ui_info "Validation annulée. Mission toujours active."
      return 0
      ;;
  esac
}

mission_complete_success() {
  local activity=$1
  local difficulty=$2
  local elapsed=$3
  local remaining=${4:-0}

  # Marquer comme complétée
  config_complete_mission

  # Mettre à jour les statistiques
  stats_record_completion "$activity" true "$difficulty"

  # Nettoyer
  config_clear_mission

  # Afficher le succès
  if [[ $remaining -le 0 ]]; then
    ui_warning "⚠️ Mission terminée en retard mais validée comme succès"
    ui_box "✅ SUCCÈS (EN RETARD)" \
      "Mission: $activity|Difficulté: $difficulty|Temps: $(format_time $elapsed)|Retard: $(format_time $((-remaining)))||🎯 Mission validée malgré le dépassement" \
      "#FFA500"
  else
    local time_saved=$((remaining))
    local time_saved_str=""
    if [[ $time_saved -gt 0 ]]; then
      time_saved_str=" ($(format_time $time_saved) d'avance !)"
    fi

    ui_success "🎉 Mission terminée avec succès !"
    ui_box "✅ SUCCÈS" \
      "Mission: $activity|Difficulté: $difficulty|Temps: $(format_time $elapsed)$time_saved_str||🏆 Excellent travail !" \
      "#00FF00"
  fi

  ui_wait
}


mission_complete_failure() {
  local activity=$1
  local difficulty=$2
  local force_penalty=${3:-false}

  # Marquer comme échouée
  config_fail_mission

  # Mettre à jour les statistiques
  stats_record_completion "$activity" false "$difficulty"

  # Nettoyer la mission
  config_clear_mission

  # TOUJOURS afficher l'avertissement de pénalité
  ui_error "💀 MISSION ÉCHOUÉE - APPLICATION DE PÉNALITÉ"
  
  ui_box "💀 ÉCHEC CONFIRMÉ" \
    "Mission: $activity ($difficulty)|Statut: ÉCHOUÉE|Conséquence: Pénalité IMMÉDIATE||⚡ Application en cours..." \
    "#FF0000"

  echo
  ui_warning "Une pénalité va être appliquée dans 3 secondes..."
  sleep 3

  # Appliquer une pénalité (TOUJOURS)
  punishment_apply_random

  ui_wait
}

mission_emergency_cancel() {
  local mission_data
  mission_data=$(config_get_current_mission)

  if [[ "$mission_data" == "null" ]] || [[ -z "$mission_data" ]]; then
    ui_error "Aucune mission active à annuler"
    return 1
  fi

  ui_warning "🚨 ANNULATION D'URGENCE"
  ui_warning "Cette action stoppera immédiatement la mission actuelle."
  echo

  if ui_confirm "Êtes-vous sûr ? Cette action ne peut pas être annulée."; then
    config_clear_mission
    ui_success "Mission annulée en urgence."
    ui_info "Aucune pénalité appliquée pour cette annulation d'urgence."
  else
    ui_info "Annulation d'urgence annulée."
  fi
}

# ============================================================================
# NOUVEAU : Menu d'urgence avec jokers
# ============================================================================
show_emergency_menu() {
  ui_header "🚨 MODE URGENCE"

  local jokers_available jokers_total
  jokers_available=$(config_get_jokers_available)
  jokers_total=$(config_get_jokers_total)

  ui_info "🃏 Jokers de sauvetage disponibles: $jokers_available/$jokers_total"
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

  # Afficher info sur les jokers
  if [[ $jokers_available -eq 0 ]]; then
    ui_warning "⚠️ Plus de jokers ! Abandon = pénalités garanties"
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
    emergency_full_reset
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

emergency_cancel_mission_with_joker() {
  ui_warning "🃏 UTILISATION D'UN JOKER DE SAUVETAGE"
  ui_info "Cette action va annuler votre mission actuelle SANS appliquer de pénalité."
  echo

  local jokers_remaining
  jokers_remaining=$(($(config_get_jokers_available) - 1))

  ui_warning "Jokers restants après cette action: $jokers_remaining/3"
  echo

  if ui_confirm "Utiliser un joker pour annuler la mission sans pénalité ?"; then
    config_use_joker
    config_clear_mission

    ui_success "🎉 Mission annulée sans pénalité grâce au joker !"
    ui_info "Votre joker a été consommé. Jokers restants: $jokers_remaining/3"
  else
    ui_info "Joker non utilisé."
  fi
}

emergency_cancel_punishments_with_joker() {
  ui_warning "🃏 UTILISATION D'UN JOKER DE SAUVETAGE"
  ui_info "Cette action va annuler TOUTES les pénalités en cours."
  echo

  punishment_list_active
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

emergency_force_cancel_mission() {
  ui_error "🛑 ABANDON DE MISSION SANS JOKER"
  ui_warning "Cette action va appliquer les pénalités d'échec de mission."
  echo

  local mission_data
  mission_data=$(config_get_current_mission)

  if [[ "$mission_data" != "null" ]] && [[ -n "$mission_data" ]]; then
    local activity difficulty
    activity=$(echo "$mission_data" | jq -r '.activity')
    difficulty=$(echo "$mission_data" | jq -r '.difficulty')

    ui_box "💀 CONSÉQUENCES DE L'ABANDON" \
      "Mission: $activity ($difficulty)|Status: Sera marquée comme échouée|Pénalité: Application d'une pénalité aléatoire|Durée: 30-60 minutes selon le type||Types possibles:|🔒 Verrouillage d'écran|🌐 Restriction réseau|🚫 Blocage de sites|🖼️ Wallpaper motivationnel|📢 Notifications de rappel|🖱️ Réduction sensibilité souris" \
      "#FF0000"

    echo
    ui_warning "⚠️ DERNIÈRE CHANCE: Vous pouvez retourner à votre mission !"
    echo
  fi

  local final_choice
  final_choice=$(gum choose \
    --cursor="➤ " \
    --selected.foreground="#ff0000" \
    "💀 Confirmer l'abandon AVEC pénalités" \
    "↩️ Retourner à ma mission (annuler abandon)")

  case "$final_choice" in
  *"Confirmer l'abandon"*)
    if [[ "$mission_data" != "null" ]] && [[ -n "$mission_data" ]]; then
      local activity difficulty
      activity=$(echo "$mission_data" | jq -r '.activity')
      difficulty=$(echo "$mission_data" | jq -r '.difficulty')

      # Marquer comme échouée et appliquer pénalités
      config_fail_mission
      stats_record_completion "$activity" false "$difficulty"
      config_clear_mission

      ui_error "Mission abandonnée et marquée comme échouée."

      # Appliquer la pénalité
      punishment_apply_random
    fi
    ;;
  *"Retourner"*)
    ui_success "Sage décision ! Retournez terminer votre mission."
    ;;
  esac
}

# ============================================================================
# Fonction utilitaire pour vérifier les pénalités actives
# ============================================================================

punishment_has_active_punishments() {
  # Vérifier s'il y a des pénalités en cours
  if [[ -f "$CONFIG_DIR/network_restricted.txt" ]] ||
    [[ -f "$CONFIG_DIR/wallpaper_backup.info" ]] ||
    pgrep -f "punishment.*notification_spam" &>/dev/null; then
    return 0 # Il y a des pénalités
  else
    return 1 # Pas de pénalités
  fi
}
