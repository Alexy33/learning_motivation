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
    ui_info "Terminez d'abord votre mission actuelle avec 'learning-check'"
    ui_info "Ou annulez-la avec 'learning-emergency'"

    return 1
  fi

  return 0
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
  # Pour TryHackMe, on garde le système aléatoire
  local difficulty
  difficulty=$(mission_get_random_difficulty)

  local duration
  duration=$(config_get_duration "$difficulty")

  local time_formatted
  time_formatted=$(format_time "$duration")

  echo
  ui_mission_box "Challenge TryHackMe" "$difficulty" "$time_formatted"
  echo

  if ui_confirm "Accepter cette mission ?"; then
    mission_start "Challenge TryHackMe" "$difficulty" "$duration" ""
  else
    mission_handle_refusal "Challenge TryHackMe" "$difficulty" "$duration" ""
  fi
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
    "Hard (4h)")

  # Extraire juste la difficulté
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

  # Obtenir un thème aléatoire pour cette difficulté
  local theme
  theme=$(mission_get_random_theme "$theme_type" "$diff_level")

  local duration
  duration=$(config_get_duration "$diff_level")

  local time_formatted
  time_formatted=$(format_time "$duration")

  echo
  ui_themed_mission_box "$activity_name" "$diff_level" "$time_formatted" "$theme"
  echo

  if ui_confirm "Accepter cette mission ?"; then
    mission_start "$activity_name" "$diff_level" "$duration" "$theme"
  else
    mission_handle_themed_refusal "$activity_name" "$diff_level" "$duration" "$theme"
  fi
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
# Gestion des refus avec joker
# ============================================================================

mission_handle_refusal() {
  local activity=$1
  local difficulty=$2
  local duration=$3
  local theme=$4

  if [[ "$(config_is_joker_available)" == "true" ]]; then
    echo
    ui_joker_available
    echo

    if ui_confirm "Utiliser votre joker quotidien pour changer de mission ?"; then
      config_use_joker
      if [[ "$activity" == "Challenge TryHackMe" ]]; then
        mission_create_tryhackme
      else
        # Regénérer avec un nouveau thème
        case "$activity" in
        "Documentation CVE") mission_create_themed "CVE" "$activity" ;;
        "Analyse de malware") mission_create_themed "MALWARE" "$activity" ;;
        "CTF Practice") mission_create_themed "CTF" "$activity" ;;
        "Veille sécurité") mission_create_themed "VEILLE" "$activity" ;;
        esac
      fi
    else
      mission_force_accept "$activity" "$difficulty" "$duration" "$theme"
    fi
  else
    ui_error "Joker quotidien déjà utilisé !"
    ui_warning "Vous devez accepter cette mission ou quitter."
    echo

    if ui_confirm "Forcer l'acceptation de la mission ?"; then
      mission_start "$activity" "$difficulty" "$duration" "$theme"
    else
      ui_info "Mission annulée. Session fermée."
      exit 0
    fi
  fi
}

mission_handle_themed_refusal() {
  mission_handle_refusal "$@"
}

mission_force_accept() {
  local activity=$1
  local difficulty=$2
  local duration=$3
  local theme=$4

  ui_warning "Aucun joker disponible. Cette mission sera forcée."

  if ui_confirm "Continuer quand même ?"; then
    mission_start "$activity" "$difficulty" "$duration" "$theme"
  else
    ui_info "Session fermée."
    exit 0
  fi
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
  ui_info "Utilisez 'learning-check' pour valider ou 'learning-status' pour voir le statut."

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
# Validation et complétion
# ============================================================================

mission_validate() {
  local mission_data
  mission_data=$(config_get_current_mission)

  if [[ "$mission_data" == "null" ]] || [[ -z "$mission_data" ]]; then
    ui_error "Aucune mission active à valider"
    return 1
  fi

  local activity difficulty start_time duration theme
  activity=$(echo "$mission_data" | jq -r '.activity')
  difficulty=$(echo "$mission_data" | jq -r '.difficulty')
  start_time=$(echo "$mission_data" | jq -r '.start_time')
  duration=$(echo "$mission_data" | jq -r '.duration')
  theme=$(echo "$mission_data" | jq -r '.theme // ""')

  local current_time elapsed
  current_time=$(date +%s)
  elapsed=$((current_time - start_time))

  ui_header "Validation de Mission"

  local validation_content="Activité: $activity|Difficulté: $difficulty|Temps écoulé: $(format_time $elapsed)"
  if [[ -n "$theme" && "$theme" != "null" ]]; then
    validation_content+="|Thème: $theme"
  fi

  ui_box "📋 MISSION À VALIDER" "$validation_content" "#FFA500"

  echo
  if ui_confirm "Avez-vous terminé cette mission avec succès ?"; then
    mission_complete_success "$activity" "$difficulty" $elapsed
  else
    ui_info "Mission marquée comme non terminée."

    if [[ $elapsed -ge $duration ]]; then
      ui_warning "Temps imparti dépassé. Application des pénalités..."
      mission_complete_failure "$activity" "$difficulty"
    else
      ui_info "Mission annulée (dans les temps). Pas de pénalité."
      mission_cancel
    fi
  fi
}

mission_complete_success() {
  local activity=$1
  local difficulty=$2
  local elapsed=$3

  # Marquer comme complétée
  config_complete_mission

  # Mettre à jour les statistiques
  stats_record_completion "$activity" true "$difficulty"

  # Nettoyer
  config_clear_mission

  # Afficher le succès
  ui_success "🎉 Mission terminée avec succès !"

  local time_saved=""
  local mission_data
  mission_data=$(config_get_current_mission)
  local duration
  duration=$(echo "$mission_data" | jq -r '.duration // 0')

  if [[ $elapsed -lt $duration ]]; then
    local saved=$((duration - elapsed))
    time_saved=" ($(format_time $saved) d'avance !)"
  fi

  ui_box "✅ SUCCÈS" \
    "Mission: $activity|Difficulté: $difficulty|Temps: $(format_time $elapsed)$time_saved||🏆 Bien joué !" \
    "#00FF00"

  ui_wait
}

mission_complete_failure() {
  local activity=$1
  local difficulty=$2

  # Marquer comme échouée
  config_fail_mission

  # Mettre à jour les statistiques
  stats_record_completion "$activity" false "$difficulty"

  # Nettoyer la mission
  config_clear_mission

  # Appliquer une pénalité
  punishment_apply_random

  ui_wait
}

mission_cancel() {
  config_clear_mission
  ui_info "Mission annulée."
}

mission_get_random_difficulty() {
  local random_index=$((RANDOM % ${#DIFFICULTIES[@]}))
  echo "${DIFFICULTIES[$random_index]}"
}

mission_get_status() {
  local mission_data
  mission_data=$(config_get_current_mission)

  if [[ "$mission_data" == "null" ]] || [[ -z "$mission_data" ]]; then
    echo "no_mission"
    return 0
  fi

  local activity difficulty start_time duration status
  activity=$(echo "$mission_data" | jq -r '.activity')
  difficulty=$(echo "$mission_data" | jq -r '.difficulty')
  start_time=$(echo "$mission_data" | jq -r '.start_time')
  duration=$(echo "$mission_data" | jq -r '.duration')
  status=$(echo "$mission_data" | jq -r '.status // "active"')

  local current_time elapsed remaining
  current_time=$(date +%s)
  elapsed=$((current_time - start_time))
  remaining=$((duration - elapsed))

  echo "status:$status"
  echo "activity:$activity"
  echo "difficulty:$difficulty"
  echo "elapsed:$elapsed"
  echo "remaining:$remaining"
  echo "duration:$duration"
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
