#!/bin/bash

# ============================================================================
# Mission Module - Gestion des missions avec thèmes refactorisés
# ============================================================================

readonly DIFFICULTIES=("Easy" "Medium" "Hard")

# ============================================================================
# NOUVEAUX THÈMES REFACTORISÉS - Plus précis et concentrés
# ============================================================================

# =========================
# 📚 DOCUMENTATION CVE
# =========================
declare -A CVE_THEMES_EASY=(
  ["1"]="Documenter CVE-2024-4577 (RCE PHP-CGI)"
  ["2"]="Analyser CVE-2024-3094 (Backdoor XZ Utils)"
  ["3"]="Étudier CVE-2024-6387 (RegreSSHion OpenSSH)"
  ["4"]="Documenter CVE-2024-4323 (RCE Cacti)"
  ["5"]="Analyser CVE-2024-5535 (LFI OpenVPN)"
  ["6"]="Étudier CVE-2024-27348 (RCE Apache HugeGraph)"
  ["7"]="Documenter CVE-2024-6778 (SQLi WordPress)"
  ["8"]="Analyser CVE-2024-7029 (XXE Strapi CMS)"
  ["9"]="Étudier CVE-2024-8796 (CSRF Joomla)"
  ["10"]="Documenter CVE-2024-9143 (XSS Drupal)"
  ["11"]="Analyser CVE-2024-6923 (Directory Traversal NextCloud)"
  ["12"]="Étudier CVE-2024-8190 (Deserialization GitLab)"
)

declare -A CVE_THEMES_MEDIUM=(
  ["1"]="Créer un POC pour CVE-2024-21887 (Ivanti Connect)"
  ["2"]="Analyser la chaîne d'attaque CVE-2024-4040 (CrushFTP)"
  ["3"]="Documenter l'exploitation CVE-2024-5910 (Palo Alto)"
  ["4"]="Créer un script d'exploit pour CVE-2024-6670 (Atlassian)"
  ["5"]="Analyser l'impact CVE-2024-7593 (Zimbra RCE)"
  ["6"]="Documenter le bypass CVE-2024-8956 (SonicWall)"
  ["7"]="Créer un POC CVE-2024-9680 (Mozilla Firefox)"
  ["8"]="Analyser CVE-2024-43044 (Jenkins Pipeline)"
  ["9"]="Documenter CVE-2024-8963 (VMware vCenter)"
  ["10"]="Créer exploit CVE-2024-7348 (PostgreSQL RCE)"
  ["11"]="Analyser CVE-2024-6387 avec métasploit"
  ["12"]="Documenter CVE-2024-9014 (Fortinet FortiOS)"
  ["13"]="Créer POC CVE-2024-8698 (Apache Solr)"
  ["14"]="Analyser CVE-2024-7519 (Kubernetes escape)"
  ["15"]="Documenter CVE-2024-8872 (Docker breakout)"
)

declare -A CVE_THEMES_HARD=(
  ["1"]="Développer un exploit complet pour CVE-2024-4577"
  ["2"]="Créer un framework d'exploitation CVE-2024-3094"
  ["3"]="Analyser et reproduire la supply chain attack XZ"
  ["4"]="Développer un payload custom pour CVE-2024-6387"
  ["5"]="Créer un kit d'exploitation multi-OS CVE-2024-21887"
  ["6"]="Analyser les techniques d'évasion CVE-2024-4040"
  ["7"]="Développer un worm basé sur CVE-2024-5910"
  ["8"]="Créer un rootkit exploitant CVE-2024-6670"
  ["9"]="Analyser l'APT29 utilisant CVE-2024-7593"
  ["10"]="Développer un exploit 0-click CVE-2024-8956"
  ["11"]="Créer une backdoor persistante CVE-2024-9680"
  ["12"]="Analyser le groupe Lazarus et CVE-2024-43044"
  ["13"]="Développer un exploit de container escape"
  ["14"]="Créer un framework d'attaque cloud native"
  ["15"]="Analyser une campagne APT complète récente"
)

# =========================
# 🔧 DÉVELOPPEMENT TOOLS
# =========================
declare -A TOOLS_THEMES_EASY=(
  ["1"]="Créer un script de scan de ports en Python"
  ["2"]="Développer un générateur de wordlists personnalisé"
  ["3"]="Coder un parser de logs Apache/Nginx"
  ["4"]="Créer un outil de vérification SSL/TLS"
  ["5"]="Développer un scanner de subdomain en Go"
  ["6"]="Coder un analyseur de headers HTTP"
  ["7"]="Créer un outil de détection de CMS"
  ["8"]="Développer un générateur de payloads XSS"
  ["9"]="Coder un scanner de vulnérabilités WordPress"
  ["10"]="Créer un outil d'extraction de métadonnées"
  ["11"]="Développer un parseur de certificats X.509"
  ["12"]="Coder un scanner de services SMB"
  ["13"]="Créer un outil de bruteforce SSH optimisé"
  ["14"]="Développer un analyseur de trafic DNS"
  ["15"]="Coder un détecteur de technologie web"
)

declare -A TOOLS_THEMES_MEDIUM=(
  ["1"]="Développer un fuzzer HTTP intelligent"
  ["2"]="Créer un outil de pivoting réseau automatisé"
  ["3"]="Coder un framework de post-exploitation"
  ["4"]="Développer un scanner de vulnérabilités Docker"
  ["5"]="Créer un outil d'analyse de firmware IoT"
  ["6"]="Coder un détecteur de malware statique"
  ["7"]="Développer un outil de OSINT automatisé"
  ["8"]="Créer un scanner de configuration cloud"
  ["9"]="Coder un analyseur de protocoles réseau"
  ["10"]="Développer un outil de détection d'intrusion"
  ["11"]="Créer un framework de social engineering"
  ["12"]="Coder un outil d'analyse de blockchain"
  ["13"]="Développer un scanner de vulnérabilités API"
  ["14"]="Créer un outil de reverse engineering automatisé"
  ["15"]="Coder un système de honeypot intelligent"
  ["16"]="Développer un outil d'évasion d'antivirus"
  ["17"]="Créer un analyseur de malware dynamique"
  ["18"]="Coder un outil de privilege escalation"
)

declare -A TOOLS_THEMES_HARD=(
  ["1"]="Développer un système d'exploitation dédié pentest"
  ["2"]="Créer un framework d'exploitation multi-plateforme"
  ["3"]="Coder un moteur de détection de 0-day"
  ["4"]="Développer un système de C2 furtif"
  ["5"]="Créer un outil d'analyse comportementale avancée"
  ["6"]="Coder un framework de machine learning pour la sécurité"
  ["7"]="Développer un système de threat hunting automatisé"
  ["8"]="Créer un outil de cryptanalyse moderne"
  ["9"]="Coder un système de détection d'APT"
  ["10"]="Développer un framework de red team automation"
  ["11"]="Créer un système d'intelligence artificielle défensive"
  ["12"]="Coder un outil d'analyse de supply chain"
  ["13"]="Développer un système de sandbox avancé"
  ["14"]="Créer un framework de bug bounty automatisé"
  ["15"]="Coder un système de corrélation de menaces"
  ["16"]="Développer un outil d'analyse de protocoles propriétaires"
  ["17"]="Créer un système de déception technology"
  ["18"]="Coder un framework d'analyse de comportement utilisateur"
)

# =========================
# 🎯 REVERSE ENGINEERING
# =========================
declare -A REVERSE_THEMES_EASY=(
  ["1"]="Analyser un crackme basique x86"
  ["2"]="Reverse d'un algorithme de chiffrement simple"
  ["3"]="Débugger un programme protégé par UPX"
  ["4"]="Analyser un keylogger Windows simple"
  ["5"]="Reverse d'une application Android basique"
  ["6"]="Débugger un driver Windows simple"
  ["7"]="Analyser un ransomware éducatif"
  ["8"]="Reverse d'un protocole réseau custom"
  ["9"]="Débugger un rootkit userland"
  ["10"]="Analyser un loader de malware basique"
  ["11"]="Reverse d'un firmware router simple"
  ["12"]="Débugger une application .NET obfusquée"
  ["13"]="Analyser un trojan bancaire simple"
  ["14"]="Reverse d'un challenge de CTF classique"
  ["15"]="Débugger une bibliothèque cryptographique"
)

declare -A REVERSE_THEMES_MEDIUM=(
  ["1"]="Analyser le malware Emotet récent"
  ["2"]="Reverse du ransomware LockBit"
  ["3"]="Débugger le rootkit Gootkit"
  ["4"]="Analyser le trojan QakBot"
  ["5"]="Reverse du loader Bumblebee"
  ["6"]="Débugger le stealer RedLine"
  ["7"]="Analyser le backdoor Cobalt Strike"
  ["8"]="Reverse du malware IcedID"
  ["9"]="Débugger le trojan TrickBot"
  ["10"]="Analyser le dropper Dridex"
  ["11"]="Reverse du ransomware BlackCat"
  ["12"]="Débugger le malware Formbook"
  ["13"]="Analyser le rootkit Zacinlo"
  ["14"]="Reverse du banking trojan Zeus"
  ["15"]="Débugger le malware Ursnif"
  ["16"]="Analyser le backdoor PlugX"
  ["17"]="Reverse du stealer AZORult"
  ["18"]="Débugger le trojan Hancitor"
)

declare -A REVERSE_THEMES_HARD=(
  ["1"]="Analyser une APT sophistiquée (Lazarus/APT29)"
  ["2"]="Reverse d'un implant nation-state"
  ["3"]="Débugger un hypervisor rootkit"
  ["4"]="Analyser un bootkit UEFI"
  ["5"]="Reverse d'un malware polymorphe avancé"
  ["6"]="Débugger un rootkit kernel mode avancé"
  ["7"]="Analyser un malware utilisant l'IA"
  ["8"]="Reverse d'un firmware compromis"
  ["9"]="Débugger un malware multi-architecture"
  ["10"]="Analyser une supply chain attack complexe"
  ["11"]="Reverse d'un malware cloud-native"
  ["12"]="Débugger un implant IoT sophistiqué"
  ["13"]="Analyser un malware utilisant la blockchain"
  ["14"]="Reverse d'un rootkit hyperviseur"
  ["15"]="Débugger un malware quantique-resistant"
  ["16"]="Analyser un APT utilisant l'OSINT"
  ["17"]="Reverse d'un malware memory-only"
  ["18"]="Débugger un living-off-the-land attack"
)

# =========================
# 🕵️ INVESTIGATION DIGITALE
# =========================
declare -A FORENSICS_THEMES_EASY=(
  ["1"]="Analyser un dump mémoire Windows suspect"
  ["2"]="Investiguer des logs de connexion SSH"
  ["3"]="Examiner un disque dur compromis"
  ["4"]="Analyser le trafic réseau d'une attaque"
  ["5"]="Investiguer des artéfacts de navigateur"
  ["6"]="Examiner des logs d'événements Windows"
  ["7"]="Analyser une image Docker suspecte"
  ["8"]="Investiguer des métadonnées de fichiers"
  ["9"]="Examiner des traces de malware Android"
  ["10"]="Analyser des logs de serveur web compromis"
  ["11"]="Investiguer une timeline d'attaque"
  ["12"]="Examiner des artéfacts de persistance"
  ["13"]="Analyser des dumps de processus malveillants"
  ["14"]="Investiguer des traces de lateral movement"
  ["15"]="Examiner des logs de base de données"
)

declare -A FORENSICS_THEMES_MEDIUM=(
  ["1"]="Reconstituer une attaque APT complète"
  ["2"]="Analyser un incident de ransomware"
  ["3"]="Investiguer une compromission cloud AWS"
  ["4"]="Examiner une attaque sur infrastructure critique"
  ["5"]="Analyser un vol de données massif"
  ["6"]="Investiguer une compromission de domaine AD"
  ["7"]="Examiner une attaque supply chain"
  ["8"]="Analyser un incident sur environnement Kubernetes"
  ["9"]="Investiguer une fraude financière cyber"
  ["10"]="Examiner une attaque sur système SCADA"
  ["11"]="Analyser un cas d'espionnage industriel"
  ["12"]="Investiguer une compromission mobile enterprise"
  ["13"]="Examiner une attaque sur blockchain"
  ["14"]="Analyser un incident IoT critique"
  ["15"]="Investiguer une manipulation d'IA/ML"
  ["16"]="Examiner une attaque sur 5G/Edge computing"
  ["17"]="Analyser un incident de deepfake malveillant"
  ["18"]="Investiguer une compromission de satellite"
)

declare -A FORENSICS_THEMES_HARD=(
  ["1"]="Analyser l'attribution d'une cyberattaque nation-state"
  ["2"]="Investiguer une opération de désinformation complexe"
  ["3"]="Examiner une attaque multi-vectorielle sophistiquée"
  ["4"]="Analyser une compromission de réseau air-gapped"
  ["5"]="Investiguer une manipulation d'élection"
  ["6"]="Examiner une attaque sur infrastructure spatiale"
  ["7"]="Analyser une compromission de véhicule autonome"
  ["8"]="Investiguer une attaque sur réseau électrique"
  ["9"]="Examiner une manipulation de marché financier"
  ["10"]="Analyser une attaque sur système médical critique"
  ["11"]="Investiguer une compromission d'usine intelligente"
  ["12"]="Examiner une attaque sur intelligence artificielle"
  ["13"]="Analyser une manipulation de données scientifiques"
  ["14"]="Investiguer une attaque sur réseau quantique"
  ["15"]="Examiner une compromission de smart city"
  ["16"]="Analyser une attaque sur infrastructure 6G"
  ["17"]="Investiguer une manipulation de réalité augmentée"
  ["18"]="Examiner une compromission de brain-computer interface"
)

# ============================================================================
# Vérification de mission unique (inchangé)
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
    ui_info "Ou utilisez un joker via 'Urgence & Jokers'"

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
# Génération de missions par type (REFACTORISÉ)
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
  "Développement Tools")
    mission_create_themed "TOOLS" "Développement Tools"
    ;;
  "Reverse Engineering")
    mission_create_themed "REVERSE" "Reverse Engineering"
    ;;
  "Investigation Digitale")
    mission_create_themed "FORENSICS" "Investigation Digitale"
    ;;
  *)
    ui_error "Type d'activité non supporté: $activity"
    return 1
    ;;
  esac
}

mission_create_tryhackme() {
  # Pour TryHackMe, système aléatoire classique sans thème
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
    mission_create_tryhackme
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

  # Afficher et choisir le thème
  mission_show_theme_choice "$theme_type" "$activity_name" "$diff_level"
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

# ============================================================================
# Fonctions utilitaires unifiées
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

# ============================================================================
# Démarrage des missions (inchangé)
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
# Affichage des missions (inchangé)
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
# Validation et complétion (inchangé)
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
      mission_complete_failure "$activity" "$difficulty"
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

  # Marquer comme échouée
  config_fail_mission

  # Mettre à jour les statistiques
  stats_record_completion "$activity" false "$difficulty"

  # Nettoyer la mission
  config_clear_mission

  # Affichage de l'échec avec pénalité
  ui_error "💀 MISSION ÉCHOUÉE - APPLICATION DE PÉNALITÉ"
  
  ui_box "💀 ÉCHEC CONFIRMÉ" \
    "Mission: $activity ($difficulty)|Statut: ÉCHOUÉE|Conséquence: Pénalité IMMÉDIATE||⚡ Application en cours..." \
    "#FF0000"

  echo
  ui_warning "Une pénalité va être appliquée dans 3 secondes..."
  sleep 3

  # Appliquer une pénalité
  punishment_apply_random

  ui_wait
}