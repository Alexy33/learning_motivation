#!/bin/bash

# ============================================================================
# Learning Challenge Manager - Script d'installation
# ============================================================================

set -euo pipefail

# Couleurs pour l'affichage
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly BOLD='\033[1m'
readonly NC='\033[0m'

# Configuration
readonly INSTALL_DIR="$HOME/.local/bin"
readonly PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ============================================================================
# Fonctions utilitaires
# ============================================================================

log_info() {
  echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
  echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
  echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
  echo -e "${RED}❌ $1${NC}" >&2
}

show_header() {
  clear
  echo -e "${BLUE}${BOLD}"
  echo "╔══════════════════════════════════════════════════════════════╗"
  echo "║                LEARNING CHALLENGE MANAGER                   ║"
  echo "║                    Installation Script                      ║"
  echo "╚══════════════════════════════════════════════════════════════╝"
  echo -e "${NC}"
}

# ============================================================================
# Vérifications système
# ============================================================================

check_dependencies() {
  log_info "Vérification des dépendances..."

  local missing_deps=()
  local optional_deps=()

  # Dépendances obligatoires
  for dep in jq bc; do
    if ! command -v "$dep" &>/dev/null; then
      missing_deps+=("$dep")
    fi
  done

  # Dépendance principale (gum)
  if ! command -v gum &>/dev/null; then
    missing_deps+=("gum")
  fi

  # Dépendances optionnelles (pour les pénalités)
  for dep in notify-send convert; do
    if ! command -v "$dep" &>/dev/null; then
      optional_deps+=("$dep")
    fi
  done

  if [[ ${#missing_deps[@]} -gt 0 ]]; then
    log_error "Dépendances manquantes: ${missing_deps[*]}"
    echo
    suggest_installation "${missing_deps[@]}"
    return 1
  fi

  log_success "Toutes les dépendances obligatoires sont présentes"

  if [[ ${#optional_deps[@]} -gt 0 ]]; then
    log_warning "Dépendances optionnelles manquantes: ${optional_deps[*]}"
    log_info "Certaines fonctionnalités de pénalité pourraient être limitées"
  fi

  return 0
}

suggest_installation() {
  local deps=("$@")

  echo -e "${YELLOW}Suggestions d'installation :${NC}"
  echo

  # Détecter la distribution
  if [[ -f /etc/arch-release ]]; then
    echo "Arch Linux :"
    echo "  sudo pacman -S ${deps[*]}"
  elif [[ -f /etc/debian_version ]]; then
    echo "Ubuntu/Debian :"
    echo "  sudo apt update && sudo apt install ${deps[*]}"
    if [[ " ${deps[*]} " =~ " gum " ]]; then
      echo "  # Pour gum: https://github.com/charmbracelet/gum/releases"
    fi
  elif [[ -f /etc/fedora-release ]]; then
    echo "Fedora :"
    echo "  sudo dnf install ${deps[*]}"
    if [[ " ${deps[*]} " =~ " gum " ]]; then
      echo "  # Pour gum: https://github.com/charmbracelet/gum/releases"
    fi
  else
    echo "Distribution non reconnue. Consultez la documentation."
  fi

  echo
  echo "Relancez ce script après avoir installé les dépendances."
}

# ============================================================================
# Installation
# ============================================================================

setup_directories() {
  log_info "Création des dossiers d'installation..."

  mkdir -p "$INSTALL_DIR"

  if [[ ! -d "$INSTALL_DIR" ]]; then
    log_error "Impossible de créer $INSTALL_DIR"
    return 1
  fi

  log_success "Dossier d'installation créé: $INSTALL_DIR"
}

install_main_script() {
  log_info "Installation du script principal..."

  # Script principal
  local main_script="$INSTALL_DIR/learning"
  cp "$PROJECT_DIR/learning.sh" "$main_script"
  chmod +x "$main_script"

  # Mettre à jour les chemins dans le script principal
  sed -i "s|readonly LIB_DIR=\".*\"|readonly LIB_DIR=\"$PROJECT_DIR/lib\"|" "$main_script"

  log_success "Script principal installé: learning"
}

setup_shell_integration() {
  log_info "Configuration de l'intégration shell..."

  local shell_configs=("$HOME/.bashrc" "$HOME/.zshrc")
  local path_export="export PATH=\"\$PATH:$INSTALL_DIR\""
  local updated_files=()

  for config in "${shell_configs[@]}"; do
    if [[ -f "$config" ]]; then
      # Vérifier si le PATH est déjà configuré
      if ! grep -q "$INSTALL_DIR" "$config" 2>/dev/null; then
        echo "" >>"$config"
        echo "# Learning Challenge Manager" >>"$config"
        echo "$path_export" >>"$config"
        updated_files+=("$(basename "$config")")
      fi
    fi
  done

  if [[ ${#updated_files[@]} -gt 0 ]]; then
    log_success "Configuration shell mise à jour: ${updated_files[*]}"
    log_warning "Rechargez votre shell ou exécutez: source ~/.bashrc"
  else
    log_info "Configuration shell déjà présente"
  fi
}

create_desktop_entry() {
  log_info "Création de l'entrée bureau..."

  local desktop_dir="$HOME/.local/share/applications"
  local desktop_file="$desktop_dir/learning-challenge.desktop"

  mkdir -p "$desktop_dir"

  cat >"$desktop_file" <<EOF
[Desktop Entry]
Name=Learning Challenge Manager
Comment=Gestionnaire de défis d'apprentissage gamifié
Exec=gnome-terminal -- $INSTALL_DIR/learning
Icon=applications-education
Terminal=true
Type=Application
Categories=Education;Development;
StartupNotify=true
EOF

  chmod +x "$desktop_file"
  log_success "Entrée bureau créée"
}

# ============================================================================
# Post-installation
# ============================================================================

run_initial_setup() {
  log_info "Configuration initiale..."

  # Créer le dossier de configuration
  local config_dir="$HOME/.learning_challenge"
  mkdir -p "$config_dir"
  log_success "Dossier de configuration créé"

  # Test rapide des commandes
  if [[ -x "$INSTALL_DIR/learning" ]]; then
    log_success "Installation testée avec succès"
  else
    log_warning "Problème détecté dans l'installation"
  fi
}

show_completion_info() {
  echo
  echo -e "${GREEN}${BOLD}🎉 Installation terminée avec succès !${NC}"
  echo
  echo -e "${BLUE}Comment utiliser :${NC}"
  echo "  1. Rechargez votre shell: source ~/.bashrc (ou ~/.zshrc)"
  echo "  2. Lancez: learning"
  echo
  echo -e "${BLUE}Fonctionnalités principales :${NC}"
  echo "  🎯 Challenges: TryHackMe, CVE, Malware, CTF, Veille"
  echo "  💀 Pénalités motivationnelles en cas d'échec"
  echo "  📊 Statistiques complètes et badges"
  echo "  ⚙️ Configuration personnalisable"
  echo "  🚨 Mode urgence intégré"
  echo
  echo -e "${BLUE}Fichiers importants :${NC}"
  echo "  Script: $INSTALL_DIR/learning"
  echo "  Sources: $PROJECT_DIR/"
  echo "  Config: ~/.learning_challenge/"
  echo
  echo -e "${YELLOW}Interface unifiée :${NC}"
  echo "  Tout se fait depuis la commande 'learning'"
  echo "  Plus besoin de commandes séparées !"
  echo
  echo -e "${GREEN}Prêt à commencer ? Tapez: ${BOLD}learning${NC}"
}

# ============================================================================
# Menu interactif
# ============================================================================

show_installation_menu() {
  if command -v gum &>/dev/null; then
    echo -e "${BLUE}Choisissez le type d'installation :${NC}"
    echo

    local choice
    choice=$(gum choose \
      "🚀 Installation complète (recommandée)" \
      "📦 Installation basique (script seulement)" \
      "🔧 Installation personnalisée" \
      "❌ Annuler")

    case "$choice" in
    "🚀 Installation complète (recommandée)")
      return 0
      ;;
    "📦 Installation basique (script seulement)")
      return 1
      ;;
    "🔧 Installation personnalisée")
      return 2
      ;;
    "❌ Annuler")
      log_info "Installation annulée"
      exit 0
      ;;
    esac
  else
    # Fallback si gum n'est pas disponible
    echo -e "${BLUE}Types d'installation :${NC}"
    echo "1. Installation complète (recommandée)"
    echo "2. Installation basique (script seulement)"
    echo "3. Installation personnalisée"
    echo "4. Annuler"
    echo
    read -p "Votre choix (1-4): " choice

    case "$choice" in
    1) return 0 ;;
    2) return 1 ;;
    3) return 2 ;;
    4)
      log_info "Installation annulée"
      exit 0
      ;;
    *)
      log_error "Choix invalide"
      exit 1
      ;;
    esac
  fi
}

custom_installation() {
  echo -e "${BLUE}Installation personnalisée :${NC}"
  echo

  local install_shell=false
  local install_desktop=false

  if command -v gum &>/dev/null; then
    if gum confirm "Configurer l'intégration shell (PATH) ?"; then
      install_shell=true
    fi

    if gum confirm "Créer l'entrée bureau ?"; then
      install_desktop=true
    fi
  else
    read -p "Configurer l'intégration shell (PATH) ? [y/N]: " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
      install_shell=true
    fi

    read -p "Créer l'entrée bureau ? [y/N]: " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
      install_desktop=true
    fi
  fi

  # Installation de base
  setup_directories
  install_main_script

  # Options personnalisées
  if $install_shell; then
    setup_shell_integration
  fi

  if $install_desktop; then
    create_desktop_entry
  fi

  run_initial_setup
}

# ============================================================================
# Désinstallation
# ============================================================================

uninstall() {
  log_info "Début de la désinstallation..."

  # Supprimer le script principal
  if [[ -f "$INSTALL_DIR/learning" ]]; then
    rm "$INSTALL_DIR/learning"
    log_success "Script supprimé: learning"
  fi

  # Supprimer l'entrée bureau
  local desktop_file="$HOME/.local/share/applications/learning-challenge.desktop"
  if [[ -f "$desktop_file" ]]; then
    rm "$desktop_file"
    log_success "Entrée bureau supprimée"
  fi

  # Demander si on supprime la config
  local remove_config=false
  if command -v gum &>/dev/null; then
    if gum confirm "Supprimer aussi la configuration et les statistiques ?"; then
      remove_config=true
    fi
  else
    read -p "Supprimer aussi la configuration et les statistiques ? [y/N]: " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
      remove_config=true
    fi
  fi

  if $remove_config; then
    rm -rf "$HOME/.learning_challenge"
    log_success "Configuration supprimée"
  else
    log_info "Configuration préservée dans ~/.learning_challenge/"
  fi

  log_warning "N'oubliez pas de retirer '$INSTALL_DIR' de votre PATH si nécessaire"
  echo
  log_success "Désinstallation terminée"
}

# ============================================================================
# Main
# ============================================================================

show_help() {
  cat <<EOF
Usage: $0 [option]

Options:
  install     Installation normale (défaut)
  uninstall   Désinstaller le système
  help        Afficher cette aide

Exemples:
  $0          # Installation interactive
  $0 install  # Installation interactive
  $0 uninstall # Désinstallation
EOF
}

main() {
  case "${1:-install}" in
  "install" | "")
    show_header

    # Vérifications préliminaires
    if ! check_dependencies; then
      exit 1
    fi

    echo

    # Menu d'installation
    local install_type
    if show_installation_menu; then
      install_type="complete"
    elif [[ $? -eq 1 ]]; then
      install_type="basic"
    else
      install_type="custom"
    fi

    # Exécution de l'installation
    case "$install_type" in
    "complete")
      setup_directories
      install_main_script
      setup_shell_integration
      create_desktop_entry
      run_initial_setup
      ;;
    "basic")
      setup_directories
      install_main_script
      run_initial_setup
      ;;
    "custom")
      custom_installation
      ;;
    esac

    show_completion_info
    ;;

  "uninstall")
    show_header
    log_warning "Désinstallation du Learning Challenge Manager"
    echo
    uninstall
    ;;

  "help" | "-h" | "--help")
    show_help
    ;;

  *)
    log_error "Option inconnue: $1"
    show_help
    exit 1
    ;;
  esac
}

# Point d'entrée
main "$@"
