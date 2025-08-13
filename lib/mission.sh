#!/bin/bash

# ============================================================================
# Mission Module - Gestion des missions et de leur cycle de vie
# ============================================================================

readonly DIFFICULTIES=("Easy" "Medium" "Hard")

# ============================================================================
# Génération de missions
# ============================================================================

mission_create() {
  local activity=$1

  # Générer aléatoirement la difficulté
  local difficulty
  difficulty=$(mission_get_random_difficulty)

  # Récupérer la durée configurée
  local duration
  duration=$(config_get_duration "$difficulty")

  local time_formatted
  time_formatted=$(format_time "$duration")

  echo
  ui_mission_box "$activity" "$difficulty" "$time_formatted"
  echo

  if ui_confirm "Accepter cette mission ?"; then
    mission_start "$activity" "$difficulty" "$duration"
  else
    mission_handle_refusal "$activity" "$difficulty" "$duration"
  fi
}

mission_get_random_difficulty() {
  local random_index=$((RANDOM % ${#DIFFICULTIES[@]}))
  echo "${DIFFICULTIES[$random_index]}"
}

mission_handle_refusal() {
  local activity=$1
  local difficulty=$2
  local duration=$3

  if [[ "$(config_is_joker_available)" == "true" ]]; then
    echo
    ui_joker_available
    echo

    if ui_confirm "Utiliser votre joker quotidien pour changer de mission ?"; then
      config_use_joker
      mission_create "$activity"
    else
      mission_force_accept "$activity" "$difficulty" "$duration"
    fi
  else
    ui_error "Joker quotidien déjà utilisé !"
    ui_warning "Vous devez accepter cette mission ou quitter."
    echo

    if ui_confirm "Forcer l'acceptation de la mission ?"; then
      mission_start "$activity" "$difficulty" "$duration"
    else
      ui_info "Mission annulée. Session fermée."
      exit 0
    fi
  fi
}

mission_force_accept() {
  local activity=$1
  local difficulty=$2
  local duration=$3

  ui_warning "Aucun joker disponible. Cette mission sera forcée."

  if ui_confirm "Continuer quand même ?"; then
    mission_start "$activity" "$difficulty" "$duration"
  else
    ui_info "Session fermée."
    exit 0
  fi
}

# ============================================================================
# Démarrage et gestion des missions
# ============================================================================

mission_start() {
  local activity=$1
  local difficulty=$2
  local duration=$3

  # Sauvegarder la mission
  config_save_mission "$activity" "$difficulty" "$duration"

  # Lancer le timer
  timer_start "$duration"

  # Affichage de confirmation
  ui_clear
  ui_header "Mission Lancée"

  local time_formatted
  time_formatted=$(format_time "$duration")

  ui_box "🚀 MISSION ACTIVE" \
    "📋 $activity\n⚡ Difficulté: $difficulty\n⏰ Temps: $time_formatted\n\n💪 Bon travail !" \
    "#00FF00"

  echo
  ui_success "Mission démarrée ! Timer en cours d'exécution."
  ui_info "Utilisez 'learning-check' pour valider ou 'learning-status' pour voir le statut."

  ui_wait
}

mission_display_current() {
  local mission_data
  mission_data=$(config_get_current_mission)

  if [[ "$mission_data" == "null" ]] || [[ -z "$mission_data" ]]; then
    return 0
  fi

  local activity
  local difficulty
  local start_time
  local duration
  local status

  activity=$(echo "$mission_data" | jq -r '.activity')
  difficulty=$(echo "$mission_data" | jq -r '.difficulty')
  start_time=$(echo "$mission_data" | jq -r '.start_time')
  duration=$(echo "$mission_data" | jq -r '.duration')
  status=$(echo "$mission_data" | jq -r '.status // "active"')

  if [[ "$status" == "active" ]]; then
    local current_time
    current_time=$(date +%s)
    local elapsed=$((current_time - start_time))
    local remaining=$((duration - elapsed))

    if [[ $remaining -gt 0 ]]; then
      local remaining_formatted
      remaining_formatted=$(format_time $remaining)
      ui_current_mission "$activity" "$difficulty" "$remaining_formatted"
    else
      ui_warning "⏰ Temps écoulé ! Mission en attente de validation."
      echo
    fi
  fi
}

mission_validate() {
  local mission_data
  mission_data=$(config_get_current_mission)

  if [[ "$mission_data" == "null" ]] || [[ -z "$mission_data" ]]; then
    ui_error "Aucune mission active à valider"
    return 1
  fi

  local activity
  local difficulty
  local start_time
  local duration

  activity=$(echo "$mission_data" | jq -r '.activity')
  difficulty=$(echo "$mission_data" | jq -r '.difficulty')
  start_time=$(echo "$mission_data" | jq -r '.start_time')
  duration=$(echo "$mission_data" | jq -r '.duration')

  local current_time
  current_time=$(date +%s)
  local elapsed=$((current_time - start_time))

  ui_header "Validation de Mission"

  ui_box "📋 MISSION À VALIDER" \
    "Activité: $activity\nDifficulté: $difficulty\nTemps écoulé: $(format_time $elapsed)" \
    "#FFA500"

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
  stats_record_completion "$activity" true

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
    "Mission: $activity\nDifficulté: $difficulty\nTemps: $(format_time $elapsed)$time_saved\n\n🏆 Bien joué !" \
    "#00FF00"

  ui_wait
}

mission_complete_failure() {
  local activity=$1
  local difficulty=$2

  # Marquer comme échouée
  config_fail_mission

  # Mettre à jour les statistiques
  stats_record_completion "$activity" false

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

mission_get_status() {
  local mission_data
  mission_data=$(config_get_current_mission)

  if [[ "$mission_data" == "null" ]] || [[ -z "$mission_data" ]]; then
    echo "no_mission"
    return 0
  fi

  local activity
  local difficulty
  local start_time
  local duration
  local status

  activity=$(echo "$mission_data" | jq -r '.activity')
  difficulty=$(echo "$mission_data" | jq -r '.difficulty')
  start_time=$(echo "$mission_data" | jq -r '.start_time')
  duration=$(echo "$mission_data" | jq -r '.duration')
  status=$(echo "$mission_data" | jq -r '.status // "active"')

  local current_time
  current_time=$(date +%s)
  local elapsed=$((current_time - start_time))
  local remaining=$((duration - elapsed))

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
