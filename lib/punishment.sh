#!/bin/bash

# ============================================================================
# Punishment Module - Système de pénalités motivationnelles amélioré
# ============================================================================

readonly PUNISHMENT_TYPES=(
  "network_restriction"
  "website_block"
  "notification_spam"
  "mouse_sensitivity"
  "annoying_sound"
  "command_swap"
  "screen_distortion"
  "keyboard_delay"
  "fake_errors"
)

# ============================================================================
# Application des pénalités
# ============================================================================

punishment_apply_random() {
  # Récupérer les paramètres de pénalité
  local min_duration max_duration
  min_duration=$(config_get '.punishment_settings.min_duration')
  max_duration=$(config_get '.punishment_settings.max_duration')

  # Générer une durée aléatoire
  local duration=$((RANDOM % (max_duration - min_duration + 1) + min_duration))

  # Choisir un type de pénalité disponible selon l'environnement
  local available_punishments=()

  # Toujours disponibles
  available_punishments+=("notification_spam")
  available_punishments+=("annoying_sound")
  available_punishments+=("command_swap")
  available_punishments+=("fake_errors")

  # Selon les privilèges et outils
  if sudo -n true 2>/dev/null; then
    available_punishments+=("network_restriction")
    available_punishments+=("website_block")
  fi

  # Souris selon l'environnement
  if punishment_can_modify_mouse; then
    available_punishments+=("mouse_sensitivity")
  fi

  # Écran selon l'environnement
  if punishment_can_modify_screen; then
    available_punishments+=("screen_distortion")
  fi

  # Clavier selon l'environnement
  if punishment_can_modify_keyboard; then
    available_punishments+=("keyboard_delay")
  fi

  # Choisir un type de pénalité aléatoire parmi les disponibles
  local punishment_type
  punishment_type=${available_punishments[$((RANDOM % ${#available_punishments[@]}))]}

  punishment_apply "$punishment_type" "$duration"
}

punishment_apply() {
  local punishment_type=$1
  local duration=$2

  ui_punishment_warning "$punishment_type" "$duration"

  # Countdown avant application
  ui_countdown 5 "Application de la pénalité dans"

  case "$punishment_type" in
  "network_restriction")
    punishment_restrict_network "$duration"
    ;;
  "website_block")
    punishment_block_websites "$duration"
    ;;
  "notification_spam")
    punishment_notification_spam "$duration"
    ;;
  "mouse_sensitivity")
    punishment_reduce_mouse_sensitivity "$duration"
    ;;
  "annoying_sound")
    punishment_annoying_sound "$duration"
    ;;
  "command_swap")
    punishment_command_swap "$duration"
    ;;
  "screen_distortion")
    punishment_screen_distortion "$duration"
    ;;
  "keyboard_delay")
    punishment_keyboard_delay "$duration"
    ;;
  "fake_errors")
    punishment_fake_errors "$duration"
    ;;
  *)
    ui_error "Type de pénalité inconnu: $punishment_type"
    ;;
  esac
}

# ============================================================================
# Détection de l'environnement
# ============================================================================

punishment_detect_environment() {
  if [[ -n "${WAYLAND_DISPLAY:-}" ]]; then
    if [[ "$XDG_CURRENT_DESKTOP" == *"GNOME"* ]]; then
      echo "wayland_gnome"
    elif [[ "$XDG_CURRENT_DESKTOP" == *"KDE"* ]]; then
      echo "wayland_kde"
    elif command -v hyprctl &>/dev/null; then
      echo "wayland_hyprland"
    elif command -v swaymsg &>/dev/null; then
      echo "wayland_sway"
    else
      echo "wayland_other"
    fi
  elif [[ -n "${DISPLAY:-}" ]]; then
    echo "x11"
  else
    echo "unknown"
  fi
}

punishment_can_modify_mouse() {
  # Hyprland
  if command -v hyprctl &>/dev/null; then
    return 0
  fi
  # Wayland avec GNOME
  if [[ -n "${WAYLAND_DISPLAY:-}" ]] && command -v gsettings &>/dev/null && [[ "$XDG_CURRENT_DESKTOP" == *"GNOME"* ]]; then
    return 0
  fi
  # Wayland avec KDE
  if [[ -n "${WAYLAND_DISPLAY:-}" ]] && command -v kwriteconfig5 &>/dev/null && [[ "$XDG_CURRENT_DESKTOP" == *"KDE"* ]]; then
    return 0
  fi
  # Sway
  if command -v swaymsg &>/dev/null; then
    return 0
  fi
  # X11
  if [[ -n "${DISPLAY:-}" ]] && command -v xinput &>/dev/null; then
    return 0
  fi

  return 1
}

punishment_can_modify_screen() {
  # X11 avec xrandr
  if [[ -n "${DISPLAY:-}" ]] && command -v xrandr &>/dev/null; then
    return 0
  fi
  # Wayland avec wlr-randr
  if [[ -n "${WAYLAND_DISPLAY:-}" ]] && command -v wlr-randr &>/dev/null; then
    return 0
  fi
  # GNOME
  if command -v gsettings &>/dev/null && [[ "$XDG_CURRENT_DESKTOP" == *"GNOME"* ]]; then
    return 0
  fi

  return 1
}

punishment_can_modify_keyboard() {
  # X11 avec xset ou setleds
  if [[ -n "${DISPLAY:-}" ]] && (command -v xset &>/dev/null || command -v setleds &>/dev/null); then
    return 0
  fi

  return 1
}

# ============================================================================
# NOUVELLES PÉNALITÉS CRÉATIVES
# ============================================================================

punishment_annoying_sound() {
  local duration=$1

  ui_error "🔊 Son strident activé pour $duration minutes"

  # Créer un script de son strident qui augmente progressivement
  cat >"$CONFIG_DIR/annoying_sound.sh" <<'EOF'
#!/bin/bash
duration=$1
end_time=$(($(date +%s) + duration * 60))

# Sauvegarder le volume actuel
if command -v pactl &>/dev/null; then
    current_volume=$(pactl get-sink-volume @DEFAULT_SINK@ | grep -o '[0-9]*%' | head -1 | tr -d '%')
    echo "$current_volume" > /tmp/learning_volume_backup
elif command -v amixer &>/dev/null; then
    current_volume=$(amixer get Master | grep -o '[0-9]*%' | head -1 | tr -d '%')
    echo "$current_volume" > /tmp/learning_volume_backup
fi

# Fonction de restauration du volume
restore_volume() {
    if [[ -f /tmp/learning_volume_backup ]]; then
        local original_volume=$(cat /tmp/learning_volume_backup)
        if command -v pactl &>/dev/null; then
            pactl set-sink-volume @DEFAULT_SINK@ "${original_volume}%"
        elif command -v amixer &>/dev/null; then
            amixer set Master "${original_volume}%"
        fi
        rm -f /tmp/learning_volume_backup
    fi
    
    # Arrêter tous les sons
    pkill -f "speaker-test\|aplay\|paplay" 2>/dev/null
    notify-send "🔇 Pénalité sonore terminée" "Le volume a été restauré et les sons arrêtés."
}

# Trap pour nettoyer en cas d'arrêt forcé
trap restore_volume EXIT

# Commencer avec un volume modéré et augmenter progressivement
initial_volume=30
max_volume=80
current_vol=$initial_volume

while [[ $(date +%s) -lt $end_time ]]; do
    # Augmenter progressivement le volume
    if [[ $current_vol -lt $max_volume ]]; then
        current_vol=$((current_vol + 5))
    fi
    
    # Appliquer le volume
    if command -v pactl &>/dev/null; then
        pactl set-sink-volume @DEFAULT_SINK@ "${current_vol}%"
    elif command -v amixer &>/dev/null; then
        amixer set Master "${current_vol}%"
    fi
    
    # Jouer des sons stridents alternés
    if command -v speaker-test &>/dev/null; then
        timeout 10 speaker-test -t sine -f $((800 + RANDOM % 1200)) -l 1 &>/dev/null &
    elif command -v paplay &>/dev/null && [[ -f /usr/share/sounds/alsa/Front_Left.wav ]]; then
        paplay /usr/share/sounds/alsa/Front_Left.wav &
    fi
    
    sleep 15
done

restore_volume
EOF

  chmod +x "$CONFIG_DIR/annoying_sound.sh"

  # Lancer le script en arrière-plan
  nohup bash "$CONFIG_DIR/annoying_sound.sh" "$duration" >/dev/null 2>&1 &
  local sound_pid=$!
  echo "$sound_pid" >"$CONFIG_DIR/annoying_sound.pid"

  ui_info "Le son sera arrêté automatiquement dans $duration minutes"
}

punishment_command_swap() {
  local duration=$1

  ui_error "🔄 Commandes inversées pour $duration minutes"

  # Créer les alias piégés dans un fichier temporaire
  local alias_file="$CONFIG_DIR/punishment_aliases.sh"
  cat >"$alias_file" <<'EOF'
# Pénalité: Commandes inversées
alias ls='echo "🚫 ls temporairement indisponible - Utilisez sl"; sl 2>/dev/null || echo "Installez sl: sudo pacman -S sl"'
alias sl='command ls'
alias cd='echo "🚫 Changement de répertoire bloqué pour $(cat ~/.learning_challenge/punishment_end_time 2>/dev/null || echo "quelques minutes")"'
alias vim='echo "🚫 vim est temporairement nano"; nano'
alias nano='echo "🚫 nano est temporairement vim"; vim'
alias cat='echo "🚫 cat inversé - contenu à l'\''envers:"; tac'
alias grep='echo "🚫 grep ne fonctionne plus comme avant"; grep -v'
alias cp='echo "🚫 cp nécessite confirmation:"; cp -i'
alias rm='echo "🚫 rm nécessite TRIPLE confirmation:"; rm -i -i -i'
alias clear='echo "🚫 Écran non nettoyable pendant la pénalité"; echo "Temps restant: $(cat ~/.learning_challenge/punishment_end_time 2>/dev/null || echo "Inconnu")"'
EOF

  # Calculer l'heure de fin
  local end_time
  end_time=$(date -d "+${duration} minutes" '+%Y-%m-%d %H:%M:%S')
  echo "$end_time" >"$CONFIG_DIR/punishment_end_time"

  # Ajouter aux profils shell
  local shells_modified=()
  for shell_config in "$HOME/.bashrc" "$HOME/.zshrc"; do
    if [[ -f "$shell_config" ]]; then
      echo "" >>"$shell_config"
      echo "# Learning Challenge - Pénalité temporaire" >>"$shell_config"
      echo "if [[ -f '$alias_file' ]] && [[ \$(date '+%s') -lt \$(date -d '\$(cat $CONFIG_DIR/punishment_end_time 2>/dev/null || echo \"1970-01-01\")' '+%s' 2>/dev/null || echo 0) ]]; then" >>"$shell_config"
      echo "  source '$alias_file'" >>"$shell_config"
      echo "  echo '🚫 Mode pénalité actif - Commandes perturbées jusqu'à $end_time'" >>"$shell_config"
      echo "fi" >>"$shell_config"
      shells_modified+=("$(basename "$shell_config")")
    fi
  done

  ui_success "✓ Commandes modifiées dans: ${shells_modified[*]}"
  ui_warning "Rechargez votre shell pour voir les effets"

  # Programmer la restauration
  (
    sleep $((duration * 60))
    punishment_restore_commands
  ) &
}

punishment_screen_distortion() {
  local duration=$1

  ui_error "📺 Distorsion d'écran pour $duration minutes"

  local env
  env=$(punishment_detect_environment)

  # Sauvegarder la configuration actuelle
  punishment_backup_screen_settings

  case "$env" in
  "x11")
    punishment_distort_screen_x11 "$duration"
    ;;
  "wayland_gnome")
    punishment_distort_screen_gnome "$duration"
    ;;
  *)
    punishment_simulate_screen_distortion "$duration"
    ;;
  esac
}

punishment_keyboard_delay() {
  local duration=$1

  ui_error "⌨️ Délai clavier activé pour $duration minutes"

  if [[ -n "${DISPLAY:-}" ]] && command -v xset &>/dev/null; then
    # Sauvegarder les paramètres actuels
    xset q | grep "auto repeat delay" >"$CONFIG_DIR/keyboard_backup.txt"

    # Appliquer un délai très frustrant
    xset r rate 2000 1  # 2 secondes avant répétition, puis 1 par seconde

    ui_success "✓ Délai clavier appliqué via xset"

    # Programmer la restauration
    (
      sleep $((duration * 60))
      punishment_restore_keyboard
    ) &
  else
    punishment_simulate_keyboard_delay "$duration"
  fi
}

punishment_fake_errors() {
  local duration=$1

  ui_error "💥 Fausses erreurs activées pour $duration minutes"

  # Créer un script qui injecte de fausses erreurs
  cat >"$CONFIG_DIR/fake_errors.sh" <<'EOF'
#!/bin/bash
duration=$1
end_time=$(($(date +%s) + duration * 60))

fake_error_messages=(
  "bash: command not found: $(basename $0)"
  "Permission denied: Cannot access file"
  "Network unreachable: Connection timeout"
  "Disk full: No space left on device"
  "Memory error: Segmentation fault"
  "Warning: CPU temperature critical"
  "Error: Package manager lock detected"
  "Kernel panic: System will restart in 30s (just kidding)"
)

while [[ $(date +%s) -lt $end_time ]]; do
    if [[ $((RANDOM % 10)) -eq 0 ]]; then  # 10% de chance
        message=${fake_error_messages[$((RANDOM % ${#fake_error_messages[@]}))]}
        echo -e "\033[0;31m$message\033[0m" >&2
    fi
    sleep 1
done
EOF

  chmod +x "$CONFIG_DIR/fake_errors.sh"

  # Ajouter aux profils shell pour injection d'erreurs
  for shell_config in "$HOME/.bashrc" "$HOME/.zshrc"; do
    if [[ -f "$shell_config" ]]; then
      echo "" >>"$shell_config"
      echo "# Learning Challenge - Fausses erreurs" >>"$shell_config"
      echo "if [[ -f '$CONFIG_DIR/fake_errors.sh' ]]; then" >>"$shell_config"
      echo "  bash '$CONFIG_DIR/fake_errors.sh' '$duration' &" >>"$shell_config"
      echo "fi" >>"$shell_config"
    fi
  done

  ui_warning "Rechargez votre shell pour voir les fausses erreurs"

  # Programmer le nettoyage
  (
    sleep $((duration * 60))
    punishment_cleanup_fake_errors
  ) &
}

# ============================================================================
# Pénalités existantes (conservées et optimisées)
# ============================================================================

punishment_restrict_network() {
  local duration=$1

  ui_error "🌐 Réseau restreint pour $duration minutes"

  # Vérifier si on peut utiliser NetworkManager
  if systemctl is-active --quiet NetworkManager && sudo -n true 2>/dev/null; then
    # Créer un script de restauration
    cat >"$CONFIG_DIR/restore_network.sh" <<'EOF'
#!/bin/bash
sudo systemctl start NetworkManager
notify-send "🌐 Réseau restauré" "La restriction réseau a été levée."
EOF
    chmod +x "$CONFIG_DIR/restore_network.sh"

    # Couper le réseau
    sudo systemctl stop NetworkManager

    # Programmer la restauration
    (
      sleep $((duration * 60))
      bash "$CONFIG_DIR/restore_network.sh"
      rm -f "$CONFIG_DIR/restore_network.sh"
    ) &

    ui_info "Le réseau sera restauré automatiquement dans $duration minutes"
  else
    # Simulation de restriction
    punishment_simulate_network_restriction "$duration"
  fi
}

punishment_block_websites() {
  local duration=$1

  ui_error "🚫 Sites distractifs bloqués pour $duration minutes"

  # Sites à bloquer
  local blocked_sites=(
    "youtube.com"
    "www.youtube.com"
    "reddit.com"
    "www.reddit.com"
    "facebook.com"
    "www.facebook.com"
    "twitter.com"
    "www.twitter.com"
    "x.com"
    "www.x.com"
    "instagram.com"
    "www.instagram.com"
    "tiktok.com"
    "www.tiktok.com"
    "twitch.tv"
    "www.twitch.tv"
    "netflix.com"
    "www.netflix.com"
    "pornhub.com"
    "www.pornhub.com"
  )

  # Créer le fichier de blocage temporaire
  local block_file="$CONFIG_DIR/blocked_hosts"
  {
    echo "# Learning Challenge - Punishment Block"
    echo "# Applied on $(date)"
    for site in "${blocked_sites[@]}"; do
      echo "127.0.0.1 $site"
    done
  } >"$block_file"

  # Ajouter au hosts système (nécessite sudo)
  if sudo -n true 2>/dev/null; then
    sudo bash -c "cat '$block_file' >> /etc/hosts"

    # Programmer la restauration
    (
      sleep $((duration * 60))
      punishment_restore_websites "$block_file"
    ) &

    ui_info "Les sites seront débloqués automatiquement dans $duration minutes"
  else
    ui_warning "Privilèges sudo requis pour bloquer les sites"
    ui_info "Blocage symbolique appliqué (fichier: $block_file)"
    
    # Nettoyage symbolique
    (
      sleep $((duration * 60))
      rm -f "$block_file"
      notify-send "🌐 Sites débloqués" "Le blocage symbolique des sites est terminé."
    ) &
  fi
}

punishment_notification_spam() {
  local duration=$1

  ui_error "📢 Notifications de rappel activées pour $duration minutes"

  local end_time=$(($(date +%s) + duration * 60))

  # Messages motivationnels améliorés
  local messages=(
    "💀 Vous avez échoué à votre mission..."
    "📚 Il est temps de retourner étudier !"
    "⏰ La discipline mène au succès"
    "🎯 Prochain challenge : ne pas échouer !"
    "💪 L'échec est le début de la réussite"
    "🔥 Transformez cette défaite en victoire !"
    "🧠 Votre cerveau demande plus de challenge"
    "⚡ Chaque échec vous rapproche du succès"
    "🎓 Un expert était un débutant qui n'a jamais abandonné"
    "💡 Apprenez de vos erreurs et recommencez"
  )

  # Lancer le spam de notifications en arrière-plan
  (
    while [[ $(date +%s) -lt $end_time ]]; do
      local message=${messages[$((RANDOM % ${#messages[@]}))]}
      notify-send "🎯 Learning Challenge" "$message" --urgency=normal --icon=dialog-warning
      
      # Varier l'intervalle pour être plus imprévisible
      local interval=$((120 + RANDOM % 180))  # Entre 2-5 minutes
      sleep $interval
    done
    notify-send "✅ Pénalité terminée" "Les notifications de rappel sont désactivées." --urgency=low
  ) &

  local spam_pid=$!
  echo "$spam_pid" >"$CONFIG_DIR/notification_spam.pid"
}

punishment_reduce_mouse_sensitivity() {
  local duration=$1

  ui_error "🖱️ Sensibilité de souris réduite pour $duration minutes"

  local env
  env=$(punishment_detect_environment)

  case "$env" in
  "wayland_hyprland")
    punishment_reduce_mouse_hyprland "$duration"
    ;;
  "wayland_gnome")
    punishment_reduce_mouse_gnome_wayland "$duration"
    ;;
  "wayland_kde")
    punishment_reduce_mouse_kde_wayland "$duration"
    ;;
  "wayland_sway")
    punishment_reduce_mouse_sway "$duration"
    ;;
  "x11")
    punishment_reduce_mouse_x11 "$duration"
    ;;
  *)
    punishment_simulate_mouse_reduction "$duration"
    ;;
  esac
}

# ============================================================================
# Fonctions de restauration pour les nouvelles pénalités
# ============================================================================

punishment_restore_commands() {
  # Supprimer les alias des profils shell
  for shell_config in "$HOME/.bashrc" "$HOME/.zshrc"; do
    if [[ -f "$shell_config" ]]; then
      # Supprimer les lignes ajoutées pour la pénalité
      sed -i '/# Learning Challenge - Pénalité temporaire/,+4d' "$shell_config"
      sed -i '/# Learning Challenge - Fausses erreurs/,+3d' "$shell_config"
    fi
  done

  # Nettoyer les fichiers temporaires
  rm -f "$CONFIG_DIR/punishment_aliases.sh"
  rm -f "$CONFIG_DIR/punishment_end_time"
  rm -f "$CONFIG_DIR/fake_errors.sh"

  notify-send "🔄 Commandes restaurées" "Les commandes fonctionnent normalement à nouveau."
}

punishment_backup_screen_settings() {
  if [[ -n "${DISPLAY:-}" ]] && command -v xrandr &>/dev/null; then
    xrandr --current >"$CONFIG_DIR/screen_backup.txt" 2>/dev/null
  fi
}

punishment_distort_screen_x11() {
  local duration=$1

  if command -v xrandr &>/dev/null; then
    # Appliquer une rotation ou résolution bizarre
    local distortions=("left" "right" "inverted")
    local distortion=${distortions[$((RANDOM % ${#distortions[@]}))]}
    
    xrandr --output $(xrandr | grep " connected" | head -1 | cut -d' ' -f1) --rotate "$distortion"

    ui_success "✓ Écran tourné via xrandr"

    # Programmer la restauration
    (
      sleep $((duration * 60))
      punishment_restore_screen
    ) &
  else
    punishment_simulate_screen_distortion "$duration"
  fi
}

punishment_distort_screen_gnome() {
  local duration=$1

  if command -v gsettings &>/dev/null; then
    # Changer la résolution ou l'échelle
    gsettings set org.gnome.desktop.interface text-scaling-factor 2.0

    ui_success "✓ Interface agrandie via GNOME"

    # Programmer la restauration
    (
      sleep $((duration * 60))
      gsettings set org.gnome.desktop.interface text-scaling-factor 1.0
      notify-send "📺 Écran restauré" "L'affichage est revenu à la normale."
    ) &
  else
    punishment_simulate_screen_distortion "$duration"
  fi
}

punishment_simulate_screen_distortion() {
  local duration=$1

  ui_warning "⚠️ Impossible de modifier l'écran automatiquement"
  ui_info "📺 SIMULATION: Modifiez vos paramètres d'affichage manuellement"

  cat >"$CONFIG_DIR/screen_distortion_reminder.txt" <<EOF
📺 PÉNALITÉ: DISTORSION D'ÉCRAN

Durée: $duration minutes
Début: $(date)
Fin prévue: $(date -d "+${duration} minutes")

CONSIGNE:
Modifiez manuellement vos paramètres d'affichage :
- Tournez l'écran (si possible)
- Changez la résolution
- Modifiez l'échelle d'affichage
- Ou tout autre réglage gênant

Cette pénalité repose sur votre honnêteté !
EOF

  ui_info "📄 Rappel créé: $CONFIG_DIR/screen_distortion_reminder.txt"

  # Programmer le nettoyage
  (
    sleep $((duration * 60))
    rm -f "$CONFIG_DIR/screen_distortion_reminder.txt"
    notify-send "📺 Pénalité terminée" "Vous pouvez restaurer vos paramètres d'affichage normaux."
  ) &
}

punishment_restore_screen() {
  if [[ -f "$CONFIG_DIR/screen_backup.txt" ]] && command -v xrandr &>/dev/null; then
    # Restaurer l'orientation normale
    xrandr --output $(xrandr | grep " connected" | head -1 | cut -d' ' -f1) --rotate normal
    rm -f "$CONFIG_DIR/screen_backup.txt"
  fi

  notify-send "📺 Écran restauré" "L'affichage est revenu à la normale."
}

punishment_restore_keyboard() {
  if [[ -n "${DISPLAY:-}" ]] && command -v xset &>/dev/null; then
    # Restaurer les paramètres par défaut du clavier
    xset r rate 660 25  # Valeurs par défaut
    rm -f "$CONFIG_DIR/keyboard_backup.txt"
  fi

  notify-send "⌨️ Clavier restauré" "La répétition des touches est revenue à la normale."
}

punishment_simulate_keyboard_delay() {
  local duration=$1

  ui_warning "⚠️ Impossible de modifier le clavier automatiquement"
  ui_info "⌨️ SIMULATION: Tapez plus lentement volontairement"

  cat >"$CONFIG_DIR/keyboard_delay_reminder.txt" <<EOF
⌨️ PÉNALITÉ: DÉLAI CLAVIER

Durée: $duration minutes
Début: $(date)
Fin prévue: $(date -d "+${duration} minutes")

CONSIGNE:
Tapez volontairement 3x plus lentement que d'habitude.
Faites des pauses entre chaque mot.

Cette pénalité teste votre autodiscipline !
EOF

  # Programmer le nettoyage
  (
    sleep $((duration * 60))
    rm -f "$CONFIG_DIR/keyboard_delay_reminder.txt"
    notify-send "⌨️ Pénalité terminée" "Vous pouvez taper normalement à nouveau."
  ) &
}

punishment_cleanup_fake_errors() {
  # Arrêter le script de fausses erreurs
  pkill -f "fake_errors.sh" 2>/dev/null

  # Nettoyer les profils shell
  for shell_config in "$HOME/.bashrc" "$HOME/.zshrc"; do
    if [[ -f "$shell_config" ]]; then
      sed -i '/# Learning Challenge - Fausses erreurs/,+3d' "$shell_config"
    fi
  done

  rm -f "$CONFIG_DIR/fake_errors.sh"
  notify-send "💥 Fausses erreurs désactivées" "Le système fonctionne normalement."
}

# ============================================================================
# Fonctions utilitaires existantes (optimisées)
# ============================================================================

punishment_simulate_network_restriction() {
  local duration=$1

  # Créer un fichier de rappel visuel
  cat >"$CONFIG_DIR/network_restricted.txt" <<EOF
RÉSEAU SYMBOLIQUEMENT RESTREINT

Durée: $duration minutes
Début: $(date)
Fin prévue: $(date -d "+${duration} minutes")

Cette restriction est symbolique car les privilèges
administrateur ne sont pas disponibles.

Respectez cette restriction pour maintenir l'intégrité
du système de motivation !
EOF

  ui_info "Fichier de restriction créé: $CONFIG_DIR/network_restricted.txt"

  # Supprimer le fichier après la durée
  (
    sleep $((duration * 60))
    rm -f "$CONFIG_DIR/network_restricted.txt"
    notify-send "🌐 Restriction levée" "La restriction réseau symbolique est terminée."
  ) &
}

punishment_restore_websites() {
  local block_file=$1

  if [[ -f "$block_file" ]] && sudo -n true 2>/dev/null; then
    # Supprimer les lignes ajoutées du fichier hosts
    sudo sed -i '/# Learning Challenge - Punishment Block/,/^$/d' /etc/hosts
    rm -f "$block_file"
    notify-send "🌐 Sites débloqués" "L'accès aux sites web a été restauré."
  fi
}

# ============================================================================
# Gestion souris par environnement (inchangée)
# ============================================================================

punishment_reduce_mouse_hyprland() {
  local duration=$1

  ui_info "🌊 Configuration Hyprland détectée"

  # Sauvegarder la configuration actuelle
  local current_sensitivity
  current_sensitivity=$(hyprctl getoption input:sensitivity | grep -oP 'float: \K[0-9.-]+' || echo "0")

  echo "sensitivity=$current_sensitivity" >"$CONFIG_DIR/mouse_hyprland_backup.conf"

  # Réduire la sensibilité (valeurs négatives = moins sensible)
  hyprctl keyword input:sensitivity -0.7

  ui_success "✓ Sensibilité réduite via Hyprland"

  # Programmer la restauration
  (
    sleep $((duration * 60))
    punishment_restore_mouse_hyprland
  ) &
}

punishment_restore_mouse_hyprland() {
  if [[ -f "$CONFIG_DIR/mouse_hyprland_backup.conf" ]]; then
    source "$CONFIG_DIR/mouse_hyprland_backup.conf"
    hyprctl keyword input:sensitivity "$sensitivity"
    rm -f "$CONFIG_DIR/mouse_hyprland_backup.conf"
  else
    hyprctl keyword input:sensitivity 0
  fi

  notify-send "🖱️ Souris restaurée" "Sensibilité normale rétablie (Hyprland)"
}

punishment_reduce_mouse_gnome_wayland() {
  local duration=$1

  # Sauvegarder les paramètres actuels
  local current_speed
  current_speed=$(gsettings get org.gnome.desktop.peripherals.mouse speed 2>/dev/null || echo "0.0")

  cat >"$CONFIG_DIR/mouse_gnome_backup.conf" <<EOF
speed=$current_speed
EOF

  # Réduire la sensibilité
  gsettings set org.gnome.desktop.peripherals.mouse speed -0.7

  ui_success "✓ Sensibilité réduite via GNOME Settings"

  # Programmer la restauration
  (
    sleep $((duration * 60))
    punishment_restore_mouse_gnome_wayland
  ) &
}

punishment_restore_mouse_gnome_wayland() {
  if [[ -f "$CONFIG_DIR/mouse_gnome_backup.conf" ]]; then
    source "$CONFIG_DIR/mouse_gnome_backup.conf"
    gsettings set org.gnome.desktop.peripherals.mouse speed "${speed//\'/}" 2>/dev/null || true
    rm -f "$CONFIG_DIR/mouse_gnome_backup.conf"
  fi

  notify-send "🖱️ Souris restaurée" "La sensibilité normale a été rétablie (GNOME/Wayland)."
}

punishment_reduce_mouse_kde_wayland() {
  local duration=$1

  # Sauvegarder les paramètres KDE
  local current_accel
  current_accel=$(kreadconfig5 --file kcminputrc --group Mouse --key Acceleration 2>/dev/null || echo "2.0")

  cat >"$CONFIG_DIR/mouse_kde_backup.conf" <<EOF
acceleration=$current_accel
EOF

  # Réduire la sensibilité
  kwriteconfig5 --file kcminputrc --group Mouse --key Acceleration 0.5
  qdbus org.kde.KWin /KWin reconfigure 2>/dev/null || true

  ui_success "✓ Sensibilité réduite via KDE Settings"

  # Programmer la restauration
  (
    sleep $((duration * 60))
    punishment_restore_mouse_kde_wayland
  ) &
}

punishment_restore_mouse_kde_wayland() {
  if [[ -f "$CONFIG_DIR/mouse_kde_backup.conf" ]]; then
    source "$CONFIG_DIR/mouse_kde_backup.conf"
    kwriteconfig5 --file kcminputrc --group Mouse --key Acceleration "$acceleration"
    qdbus org.kde.KWin /KWin reconfigure 2>/dev/null || true
    rm -f "$CONFIG_DIR/mouse_kde_backup.conf"
  fi

  notify-send "🖱️ Souris restaurée" "La sensibilité normale a été rétablie (KDE/Wayland)."
}

punishment_reduce_mouse_sway() {
  local duration=$1

  # Appliquer une sensibilité réduite temporaire
  swaymsg input type:pointer accel_profile flat 2>/dev/null || true
  swaymsg input type:pointer pointer_accel -0.7 2>/dev/null || true

  ui_success "✓ Sensibilité réduite via Sway"

  # Programmer la restauration
  (
    sleep $((duration * 60))
    punishment_restore_mouse_sway
  ) &
}

punishment_restore_mouse_sway() {
  swaymsg input type:pointer accel_profile adaptive 2>/dev/null || true
  swaymsg input type:pointer pointer_accel 0 2>/dev/null || true
  notify-send "🖱️ Souris restaurée" "La sensibilité normale a été rétablie (Sway)."
}

punishment_reduce_mouse_x11() {
  local duration=$1

  ui_info "🖥️ Environnement X11 détecté"

  if command -v xinput &>/dev/null; then
    local mouse_ids
    mouse_ids=$(xinput list | grep -i mouse | grep -o 'id=[0-9]*' | cut -d= -f2)

    for id in $mouse_ids; do
      xinput set-prop "$id" "libinput Accel Speed" -0.7 2>/dev/null || true
    done

    ui_success "✓ Sensibilité réduite via xinput"

    # Programmer la restauration
    (
      sleep $((duration * 60))
      punishment_restore_mouse_x11
    ) &
  else
    punishment_simulate_mouse_reduction "$duration"
  fi
}

punishment_restore_mouse_x11() {
  if command -v xinput &>/dev/null; then
    local mouse_ids
    mouse_ids=$(xinput list | grep -i mouse | grep -o 'id=[0-9]*' | cut -d= -f2)

    for id in $mouse_ids; do
      xinput set-prop "$id" "libinput Accel Speed" 0 2>/dev/null || true
    done
  fi

  notify-send "🖱️ Souris restaurée" "La sensibilité normale a été rétablie (X11)."
}

punishment_simulate_mouse_reduction() {
  local duration=$1

  ui_warning "⚠️ Impossible de modifier la sensibilité automatiquement"
  ui_info "📝 SIMULATION: Réduisez manuellement votre sensibilité de souris"

  # Créer un fichier de rappel visuel
  cat >"$CONFIG_DIR/mouse_reduction_reminder.txt" <<EOF
🖱️ PÉNALITÉ: SENSIBILITÉ SOURIS RÉDUITE

Durée: $duration minutes
Début: $(date)
Fin prévue: $(date -d "+${duration} minutes")

CONSIGNE:
Réduisez manuellement la sensibilité de votre souris 
dans les paramètres système pendant cette durée.

Cette pénalité est basée sur l'honneur du système !
Respectez-la pour maintenir l'efficacité motivationnelle.

Instructions par environnement:
- GNOME: Paramètres > Souris > Vitesse du pointeur
- KDE: Paramètres système > Périphériques d'entrée > Souris
- XFCE: Paramètres > Souris et pavé tactile > Vitesse
EOF

  ui_info "📄 Fichier de rappel créé: $CONFIG_DIR/mouse_reduction_reminder.txt"

  if command -v notify-send &>/dev/null; then
    notify-send "🖱️ Pénalité Souris" "Réduisez manuellement votre sensibilité pendant $duration minutes" --urgency=critical
  fi

  # Programmer le nettoyage et la notification de fin
  (
    sleep $((duration * 60))
    rm -f "$CONFIG_DIR/mouse_reduction_reminder.txt"
    if command -v notify-send &>/dev/null; then
      notify-send "✅ Pénalité terminée" "Vous pouvez restaurer la sensibilité normale de votre souris"
    fi
  ) &
}

# ============================================================================
# Gestion des pénalités actives
# ============================================================================

punishment_has_active_punishments() {
  # Vérifier s'il y a des pénalités en cours
  if [[ -f "$CONFIG_DIR/network_restricted.txt" ]] ||
    [[ -f "$CONFIG_DIR/blocked_hosts" ]] ||
    [[ -f "$CONFIG_DIR/mouse_reduction_reminder.txt" ]] ||
    [[ -f "$CONFIG_DIR"/mouse_*_backup.conf ]] ||
    [[ -f "$CONFIG_DIR/punishment_aliases.sh" ]] ||
    [[ -f "$CONFIG_DIR/annoying_sound.pid" ]] ||
    [[ -f "$CONFIG_DIR/screen_distortion_reminder.txt" ]] ||
    [[ -f "$CONFIG_DIR/keyboard_delay_reminder.txt" ]] ||
    [[ -f "$CONFIG_DIR/fake_errors.sh" ]] ||
    pgrep -f "punishment.*notification_spam" &>/dev/null ||
    pgrep -f "annoying_sound.sh" &>/dev/null; then
    return 0 # Il y a des pénalités
  else
    return 1 # Pas de pénalités
  fi
}

punishment_list_active() {
  ui_info "Pénalités actives :"

  local found_any=false

  # Vérifier les différents types de pénalités
  if [[ -f "$CONFIG_DIR/network_restricted.txt" ]]; then
    echo "  🌐 Restriction réseau active"
    found_any=true
  fi

  if [[ -f "$CONFIG_DIR/blocked_hosts" ]]; then
    echo "  🚫 Sites web bloqués"
    found_any=true
  fi

  if [[ -f "$CONFIG_DIR"/mouse_*_backup.conf ]] || [[ -f "$CONFIG_DIR/mouse_reduction_reminder.txt" ]]; then
    echo "  🖱️ Sensibilité souris réduite"
    found_any=true
  fi

  if [[ -f "$CONFIG_DIR/punishment_aliases.sh" ]]; then
    echo "  🔄 Commandes inversées"
    found_any=true
  fi

  if [[ -f "$CONFIG_DIR/annoying_sound.pid" ]] || pgrep -f "annoying_sound.sh" &>/dev/null; then
    echo "  🔊 Son strident actif"
    found_any=true
  fi

  if [[ -f "$CONFIG_DIR/screen_distortion_reminder.txt" ]]; then
    echo "  📺 Distorsion d'écran"
    found_any=true
  fi

  if [[ -f "$CONFIG_DIR/keyboard_delay_reminder.txt" ]]; then
    echo "  ⌨️ Délai clavier actif"
    found_any=true
  fi

  if [[ -f "$CONFIG_DIR/fake_errors.sh" ]] || pgrep -f "fake_errors.sh" &>/dev/null; then
    echo "  💥 Fausses erreurs actives"
    found_any=true
  fi

  if pgrep -f "punishment.*notification_spam" &>/dev/null; then
    echo "  📢 Spam de notifications actif"
    found_any=true
  fi

  if [[ ! $found_any ]]; then
    echo "  Aucune pénalité active"
  fi
}

punishment_emergency_stop() {
  ui_warning "🚨 ARRÊT D'URGENCE DES PÉNALITÉS"

  # Arrêter tous les processus de pénalités
  pkill -f "punishment" 2>/dev/null || true
  pkill -f "annoying_sound.sh" 2>/dev/null || true
  pkill -f "fake_errors.sh" 2>/dev/null || true

  # Restaurer les paramètres souris selon environnement
  [[ -f "$CONFIG_DIR/mouse_hyprland_backup.conf" ]] && punishment_restore_mouse_hyprland
  [[ -f "$CONFIG_DIR/mouse_gnome_backup.conf" ]] && punishment_restore_mouse_gnome_wayland
  [[ -f "$CONFIG_DIR/mouse_kde_backup.conf" ]] && punishment_restore_mouse_kde_wayland
  command -v xinput &>/dev/null && punishment_restore_mouse_x11

  # Restaurer écran
  punishment_restore_screen 2>/dev/null || true

  # Restaurer clavier
  punishment_restore_keyboard 2>/dev/null || true

  # Restaurer commandes
  punishment_restore_commands 2>/dev/null || true

  # Nettoyer les fichiers temporaires
  rm -f "$CONFIG_DIR/network_restricted.txt"
  rm -f "$CONFIG_DIR/blocked_hosts"
  rm -f "$CONFIG_DIR/restore_network.sh"
  rm -f "$CONFIG_DIR/mouse_reduction_reminder.txt"
  rm -f "$CONFIG_DIR/punishment_aliases.sh"
  rm -f "$CONFIG_DIR/punishment_end_time"
  rm -f "$CONFIG_DIR/annoying_sound.sh"
  rm -f "$CONFIG_DIR/annoying_sound.pid"
  rm -f "$CONFIG_DIR/screen_distortion_reminder.txt"
  rm -f "$CONFIG_DIR/keyboard_delay_reminder.txt"
  rm -f "$CONFIG_DIR/fake_errors.sh"
  rm -f "$CONFIG_DIR/notification_spam.pid"
  rm -f /tmp/learning_volume_backup

  # Restaurer réseau si nécessaire
  if sudo -n true 2>/dev/null; then
    sudo systemctl start NetworkManager 2>/dev/null || true
    sudo sed -i '/# Learning Challenge - Punishment Block/,/^$/d' /etc/hosts 2>/dev/null || true
  fi

  # Restaurer volume si sauvegardé
  if [[ -f /tmp/learning_volume_backup ]]; then
    local original_volume=$(cat /tmp/learning_volume_backup)
    if command -v pactl &>/dev/null; then
      pactl set-sink-volume @DEFAULT_SINK@ "${original_volume}%" 2>/dev/null || true
    elif command -v amixer &>/dev/null; then
      amixer set Master "${original_volume}%" 2>/dev/null || true
    fi
    rm -f /tmp/learning_volume_backup
  fi

  ui_success "Toutes les pénalités ont été annulées."
}