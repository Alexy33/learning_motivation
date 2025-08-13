#!/bin/bash

# ============================================================================
# Timer Module - Gestion du temps et des notifications
# ============================================================================

# ============================================================================
# Démarrage du timer
# ============================================================================

timer_start() {
  local duration=$1

  # Arrêter le timer précédent s'il existe
  timer_stop

  # Lancer le nouveau timer en arrière-plan
  (
    sleep "$duration"
    timer_timeout_handler
  ) &

  local timer_pid=$!
  config_save_timer_pid "$timer_pid"

  # Programmer des rappels intermédiaires
  timer_schedule_reminders "$duration" &
}

timer_timeout_handler() {
  local mission_data
  mission_data=$(config_get_current_mission)

  if [[ "$mission_data" != "null" ]] && [[ -n "$mission_data" ]]; then
    local activity
    activity=$(echo "$mission_data" | jq -r '.activity')

    # Notification de fin de temps
    timer_send_notification "⏰ TEMPS ÉCOULÉ !" \
      "Mission '$activity' - Temps imparti terminé !\nValidez votre mission avec 'learning-check'" \
      "critical"

    # Son d'alerte si activé
    timer_play_alert_sound

    # Marquer le timer comme fini
    echo "timeout" >"$CONFIG_DIR/timer_status"
  fi
}

timer_schedule_reminders() {
  local total_duration=$1

  # Rappels à 75%, 90% et 95% du temps
  local reminder_75=$((total_duration * 75 / 100))
  local reminder_90=$((total_duration * 90 / 100))
  local reminder_95=$((total_duration * 95 / 100))

  # Rappel à 75%
  (
    sleep "$reminder_75"
    if timer_is_mission_active; then
      timer_send_notification "⚠️ Attention" \
        "75% du temps écoulé pour votre mission" \
        "normal"
    fi
  ) &

  # Rappel à 90%
  (
    sleep "$reminder_90"
    if timer_is_mission_active; then
      timer_send_notification "🚨 Urgent" \
        "Plus que 10% du temps restant !" \
        "normal"
    fi
  ) &

  # Rappel à 95%
  (
    sleep "$reminder_95"
    if timer_is_mission_active; then
      timer_send_notification "⏰ Dernière ligne droite" \
        "Plus que 5% du temps ! Finalisez rapidement." \
        "normal"
    fi
  ) &
}

# ============================================================================
# Contrôle du timer
# ============================================================================

timer_stop() {
  config_stop_timer
  rm -f "$CONFIG_DIR/timer_status"
}

timer_is_running() {
  config_is_timer_running
}

timer_is_mission_active() {
  local mission_data
  mission_data=$(config_get_current_mission)

  if [[ "$mission_data" != "null" ]] && [[ -n "$mission_data" ]]; then
    local status
    status=$(echo "$mission_data" | jq -r '.status // "active"')
    [[ "$status" == "active" ]]
  else
    return 1
  fi
}

timer_get_remaining() {
  local mission_data
  mission_data=$(config_get_current_mission)

  if [[ "$mission_data" == "null" ]] || [[ -z "$mission_data" ]]; then
    echo "0"
    return 1
  fi

  local start_time duration current_time
  start_time=$(echo "$mission_data" | jq -r '.start_time')
  duration=$(echo "$mission_data" | jq -r '.duration')
  current_time=$(date +%s)

  local elapsed=$((current_time - start_time))
  local remaining=$((duration - elapsed))

  if [[ $remaining -lt 0 ]]; then
    echo "0"
  else
    echo "$remaining"
  fi
}

timer_get_elapsed() {
  local mission_data
  mission_data=$(config_get_current_mission)

  if [[ "$mission_data" == "null" ]] || [[ -z "$mission_data" ]]; then
    echo "0"
    return 1
  fi

  local start_time current_time
  start_time=$(echo "$mission_data" | jq -r '.start_time')
  current_time=$(date +%s)

  echo $((current_time - start_time))
}

timer_is_overtime() {
  local remaining
  remaining=$(timer_get_remaining)
  [[ $remaining -eq 0 ]]
}

# ============================================================================
# Notifications
# ============================================================================

timer_send_notification() {
  local title=$1
  local message=$2
  local urgency=${3:-"normal"}

  # Vérifier si les notifications sont activées
  local notifications_enabled
  notifications_enabled=$(config_get '.notifications.enabled')

  if [[ "$notifications_enabled" == "true" ]]; then
    # Notification système
    if command -v notify-send &>/dev/null; then
      notify-send \
        --urgency="$urgency" \
        --app-name="Learning Challenge" \
        --icon="dialog-information" \
        "$title" \
        "$message"
    fi

    # Notification dans le terminal (si dans une session)
    if [[ -n "${DISPLAY:-}" ]] || [[ -n "${WAYLAND_DISPLAY:-}" ]]; then
      echo -e "\n${YELLOW}🔔 $title${NC}: $message" >>"$CONFIG_DIR/notifications.log"
    fi
  fi
}

timer_play_alert_sound() {
  local sound_enabled
  sound_enabled=$(config_get '.notifications.sound')

  if [[ "$sound_enabled" == "true" ]]; then
    # Essayer différentes méthodes pour jouer un son
    if command -v paplay &>/dev/null; then
      paplay /usr/share/sounds/alsa/Front_Left.wav 2>/dev/null &
    elif command -v aplay &>/dev/null; then
      aplay /usr/share/sounds/alsa/Front_Left.wav 2>/dev/null &
    elif command -v speaker-test &>/dev/null; then
      timeout 2 speaker-test -t sine -f 1000 -l 1 &>/dev/null &
    fi
  fi
}

# ============================================================================
# Affichage du statut
# ============================================================================

timer_display_status() {
  local mission_data
  mission_data=$(config_get_current_mission)

  if [[ "$mission_data" == "null" ]] || [[ -z "$mission_data" ]]; then
    ui_info "Aucune mission active"
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

  ui_header "Statut de la Mission"

  local status_color="#4A90E2"
  local status_text="EN COURS"

  if [[ $remaining -le 0 ]]; then
    status_color="#FF6B6B"
    status_text="TEMPS ÉCOULÉ"
    remaining=0
  elif [[ $remaining -le 300 ]]; then # Moins de 5 minutes
    status_color="#FFA500"
    status_text="URGENT"
  fi

  local elapsed_formatted remaining_formatted duration_formatted
  elapsed_formatted=$(format_time $elapsed)
  remaining_formatted=$(format_time $remaining)
  duration_formatted=$(format_time $duration)

  # Calcul du pourcentage
  local percentage
  if [[ $duration -gt 0 ]]; then
    percentage=$((elapsed * 100 / duration))
    if [[ $percentage -gt 100 ]]; then
      percentage=100
    fi
  else
    percentage=0
  fi

  gum style \
    --border double \
    --margin "1 2" \
    --padding "1 2" \
    --border.foreground "$status_color" \
    "📋 MISSION ACTIVE: $status_text" \
    "" \
    "🎯 Activité: $activity" \
    "⚡ Difficulté: $difficulty" \
    "⏰ Temps total: $duration_formatted" \
    "⌛ Temps écoulé: $elapsed_formatted" \
    "⏳ Temps restant: $remaining_formatted" \
    "📊 Progression: $percentage%"

  echo
  ui_progress_bar $elapsed $duration "Avancement"
  echo

  if [[ $remaining -le 0 ]]; then
    ui_warning "⚠️  Le temps imparti est écoulé !"
    ui_info "Utilisez 'learning-check' pour valider votre mission."
  elif [[ $remaining -le 300 ]]; then
    ui_warning "⚠️  Plus que 5 minutes ! Dépêchez-vous !"
  fi
}

# ============================================================================
# Utilitaires de formatage
# ============================================================================

timer_format_duration() {
  local seconds=$1
  local hours=$((seconds / 3600))
  local minutes=$(((seconds % 3600) / 60))
  local secs=$((seconds % 60))

  if [[ $hours -gt 0 ]]; then
    printf "%dh%02dm%02ds" $hours $minutes $secs
  elif [[ $minutes -gt 0 ]]; then
    printf "%dm%02ds" $minutes $secs
  else
    printf "%ds" $secs
  fi
}

timer_parse_duration() {
  local input=$1

  # Format: 2h30m, 90m, 45, etc.
  if [[ "$input" =~ ^([0-9]+)h([0-9]+)m?$ ]]; then
    local hours=${BASH_REMATCH[1]}
    local minutes=${BASH_REMATCH[2]}
    echo $((hours * 3600 + minutes * 60))
  elif [[ "$input" =~ ^([0-9]+)m$ ]]; then
    local minutes=${BASH_REMATCH[1]}
    echo $((minutes * 60))
  elif [[ "$input" =~ ^([0-9]+)$ ]]; then
    # Assume minutes si pas d'unité
    echo $(($1 * 60))
  else
    echo "0"
  fi
}
