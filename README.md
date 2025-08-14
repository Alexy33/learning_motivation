# Learning Challenge Manager

Un système de gestion de défis d'apprentissage gamifié pour la cybersécurité, avec motivation par pénalités temporaires et système de jokers quotidiens.

## 🎯 Concept

Le Learning Challenge Manager génère des missions d'apprentissage thématiques avec des difficultés variables. En cas d'échec, des pénalités temporaires motivationnelles sont appliquées. Un système de **3 jokers quotidiens** permet d'annuler missions ou pénalités sans conséquences.

## ✨ Fonctionnalités

### 🎮 **Interface Unifiée**
- **Menu principal** adaptatif selon l'état
- **Navigation contextuelle** intelligente
- **Interface moderne** avec [gum](https://github.com/charmbracelet/gum)

### 🃏 **Système de Jokers**
- **3 jokers par jour** qui se rechargent automatiquement
- **Annulation mission** sans pénalité
- **Arrêt pénalités** actives instantané
- **Usage stratégique** recommandé

### 🎯 **Missions Thématiques**

#### 📚 **Documentation CVE**
- **Easy** : 1 CVE récente (score CVSS < 7)
- **Medium** : 2-3 CVE critiques avec POC
- **Hard** : 3-5 CVE avec chaîne d'exploitation

#### 🦠 **Analyse de malware**
- **Easy** : Analyse statique basique, IoC simples
- **Medium** : Reverse engineering, sandbox dynamique
- **Hard** : APT sophistiqué, unpacking avancé

#### 🏴‍☠️ **CTF Practice**
- **Easy** : 3-5 challenges Web faciles, crypto basique
- **Medium** : Reverse engineering, pwn avec protections
- **Hard** : Exploitation 0-day, cryptanalyse avancée

#### 📰 **Veille sécurité**
- **Easy** : Résumé hebdo, 3 nouvelles techniques
- **Medium** : Rapport APT détaillé, tendances mensuelles
- **Hard** : Analyse géopolitique, prospective stratégique

#### 🔥 **Challenge TryHackMe**
- **Système aléatoire** : Easy/Medium/Hard généré automatiquement
- **Pas de thème** : choix libre de machine

### ⏰ **Gestion du Temps**
- **Easy** : 2h | **Medium** : 3h | **Hard** : 4h (personnalisables)
- **Timer background** avec notifications intelligentes
- **Rappels automatiques** à 75%, 90% et 95%

### 💀 **Pénalités Motivationnelles**
- **Verrouillage écran** temporaire (30-60 min)
- **Restriction réseau** avec restauration auto
- **Blocage sites** distractifs (YouTube, Reddit...)
- **Wallpaper motivationnel** temporaire
- **Notifications rappel** périodiques
- **Réduction sensibilité souris** (Hyprland, GNOME, KDE, X11)

### 📊 **Statistiques Complètes**
- **Suivi global** : missions, taux de réussite, streaks
- **Par activité** : performance détaillée par type
- **Par difficulté** : analyse Easy/Medium/Hard
- **Badges de progression** automatiques

### 🚨 **Mode Urgence & Admin**
- **Menu urgence** avec gestion jokers
- **Arrêt d'urgence** toutes pénalités
- **Réinitialisation complète** sécurisée
- **Mode admin** pour dysfonctionnements graves

## 📋 Prérequis

### Obligatoires
```bash
# Arch Linux
sudo pacman -S gum jq bc

# Ubuntu/Debian
sudo apt install jq bc
# Installer gum: https://github.com/charmbracelet/gum/releases

# Fedora
sudo dnf install jq bc
```

### Optionnels (pour pénalités)
```bash
# Notifications
sudo pacman -S libnotify

# Wallpaper (selon environnement)
sudo pacman -S imagemagick  # Création wallpaper
```

## 🚀 Installation

### Installation complète (recommandée)
```bash
git clone <repo-url> learning-challenge
cd learning-challenge
chmod +x install.sh
./install.sh
```

Options d'installation :
- **Complète** : Script + intégration shell + entrée bureau
- **Basique** : Script seulement
- **Personnalisée** : Choix des composants

### Installation manuelle
```bash
git clone <repo-url> learning-challenge
cd learning-challenge
chmod +x learning.sh
./learning.sh
```

## 🎮 Utilisation

### Lancement
```bash
learning  # Si installé avec install.sh
# OU
./learning.sh  # Depuis le dossier du projet
```

### Interface principale

Le menu s'adapte automatiquement :

**💤 Sans mission active :**
```
🎯 Challenges
📊 Statistiques  
⚙️ Paramètres
🚪 Quitter
```

**⚡ Avec mission active :**
```
📋 Mission en cours (1h23m restant)
✅ Terminer la mission
🚨 Urgence & Jokers
💀 Peine encourue
🎯 Challenges (bloqué)
📊 Statistiques
⚙️ Paramètres
🚪 Quitter
```

**🃏 Jokers disponibles** : Affiché en permanence
```
🃏 Jokers de sauvetage: 2/3 disponibles
💡 Annulez missions/pénalités sans conséquences
```

### Workflow typique

1. **Lancer** `learning`
2. **Vérifier jokers** disponibles (2/3)
3. **Choisir** "🎯 Challenges"
4. **Sélectionner** type d'activité (ex: Documentation CVE)
5. **Choisir difficulté** (Easy/Medium/Hard)
6. **Accepter/regénérer** le thème proposé
7. **Travailler** sur le défi
8. **Valider** avec "✅ Terminer la mission"

### Gestion des échecs

**Avec jokers :**
- Menu "🚨 Urgence" → "🃏 Utiliser un joker"
- Mission annulée **sans pénalité**

**Sans jokers :**
- Pénalité **immédiate** appliquée
- Durée 30-60 minutes selon type

## 🎯 Types de Challenges Détaillés

### 📚 Documentation CVE

**Easy (2h)**
- Analyser 1 CVE récente (score CVSS < 7)
- Documenter une vulnérabilité web basique
- Rechercher des CVE dans un logiciel spécifique

**Medium (3h)**
- Analyser 2-3 CVE critiques (score CVSS > 7)
- Créer un rapport détaillé d'une CVE avec POC
- Comparer l'évolution d'une famille de vulnérabilités

**Hard (4h)**
- Analyser 3-5 CVE avec chaîne d'exploitation
- Rédiger un guide de mitigation complet
- Analyser l'impact d'une CVE sur plusieurs systèmes

### 🦠 Analyse de malware

**Easy (2h)**
- Analyse statique basique d'un malware connu
- Identifier les IoC d'un échantillon simple
- Documenter le comportement d'un adware

**Medium (3h)**
- Reverse engineering d'un trojan
- Analyse dynamique avec sandbox
- Décrypter la communication C&C

**Hard (4h)**
- Analyse complète d'un APT sophistiqué
- Désobfuscation et unpacking avancé
- Développer des signatures de détection

## ⚙️ Configuration

### Durées personnalisées
```
Menu → Paramètres → Modifier les durées par difficulté
- Easy: 1h-4h (défaut: 2h)
- Medium: 2h-6h (défaut: 3h)  
- Hard: 3h-8h (défaut: 4h)
```

### Pénalités
```
Menu → Paramètres → Configuration des pénalités
- Activer/désactiver pénalités
- Durée min/max (défaut: 30-60 min)
```

### Notifications
```
Menu → Paramètres → Paramètres de notifications
- Notifications système on/off
- Sons d'alerte on/off
```

## 📊 Système de Badges

### Par nombre de missions
- 🥉 **Apprenti** (10 missions complétées)
- 🥈 **Vétéran** (50 missions complétées)
- 🏆 **Centurion** (100 missions complétées)

### Par streaks
- 💪 **Constant** (7 jours consécutifs)
- ⚡ **Déterminé** (14 jours consécutifs)
- 🔥 **Légende** (30 jours consécutifs)

### Par spécialisation
- 💀 **Maître Hard** (10 missions Hard complétées)

## 🚨 Mode Urgence

Accessible même avec mission active :

### 🃏 Avec jokers disponibles
- **Annuler mission** sans pénalité
- **Stopper pénalités** actives immédiatement

### 💀 Sans jokers
- **Abandon forcé** avec pénalités garanties
- **Double confirmation** requise

### 🔧 Options système
- **Réinitialisation complète** (préserve stats)
- **Diagnostic système** détaillé

## 🛠️ Support Multi-environnements

### Environnements testés
- **Hyprland** (Wayland) - Support complet
- **GNOME** (Wayland/X11) - Support complet
- **KDE Plasma** (Wayland/X11) - Support complet
- **Sway** (Wayland) - Support partiel
- **XFCE/i3/autres** (X11) - Support basique

### Fonctionnalités par environnement

| Fonctionnalité | Hyprland | GNOME | KDE | Sway | X11 |
|----------------|----------|-------|-----|------|-----|
| Modification souris | ✅ | ✅ | ✅ | ✅ | ✅ |
| Changement wallpaper | ✅ | ✅ | ✅ | ✅ | ⚠️ |
| Verrouillage écran | ✅ | ✅ | ✅ | ✅ | ✅ |
| Restriction réseau | ✅ | ✅ | ✅ | ✅ | ✅ |
| Notifications | ✅ | ✅ | ✅ | ✅ | ✅ |

## 📁 Structure Projet

```
learning-challenge/
├── learning.sh              # Point d'entrée principal
├── install.sh               # Installation automatique
├── lib/                     # Modules fonctionnels
│   ├── config.sh           # Configuration & persistance
│   ├── ui.sh               # Interface utilisateur
│   ├── mission.sh          # Logique missions & thèmes
│   ├── stats.sh            # Statistiques & badges
│   ├── timer.sh            # Gestion temporelle
│   ├── punishment.sh       # Système pénalités
│   └── admin.sh            # Mode administrateur
└── README.md

# Données utilisateur
~/.learning_challenge/
├── config.json             # Configuration
├── stats.json              # Statistiques
├── current_mission.json    # Mission active
└── admin_actions.log       # Journal admin
```

## 🔧 Dépannage

### Problèmes fréquents

**Pénalités ne s'appliquent pas :**
```bash
# Vérifier privilèges sudo
sudo -n true && echo "OK" || echo "sudo requis"

# Test modification souris Hyprland
hyprctl keyword input:sensitivity -0.5
hyprctl keyword input:sensitivity 0
```

**Interface cassée :**
```bash
# Vérifier dépendances
which gum jq bc

# Réinitialisation
./learning.sh --admin  # Code: emergency123
```

**Réinstallation propre :**
```bash
rm -rf ~/.learning_challenge
./install.sh
```

### Codes d'accès admin
En cas de dysfonctionnement grave :
- `emergency123`
- `override456` 
- `rescue789`

## 🎯 Philosophie & Motivation

Le Learning Challenge Manager applique les principes de gamification pour transformer l'apprentissage cybersécurité :

- **🎲 Aléatoire contrôlé** : Thèmes variés mais pertinents
- **⏰ Contrainte temporelle** : Urgence motivante
- **💀 Conséquences** : Pénalités pour échecs
- **🃏 Échappatoires** : Jokers pour situations exceptionnelles
- **📊 Progression** : Badges et statistiques
- **🎯 Focus** : Une mission à la fois

*"La discipline est le pont entre les objectifs et l'accomplissement."*

## 📈 Roadmap

### Prochaines versions
- [ ] **Missions collaboratives** multi-utilisateurs
- [ ] **Intégrations API** (TryHackMe, CVE feeds)
- [ ] **Mode équipe** avec classements
- [ ] **Pénalités créatives** supplémentaires
- [ ] **Export rapports** missions complétées
- [ ] **Planification missions** à l'avance

### Contributions bienvenues
- Nouveaux thèmes de missions
- Support environnements supplémentaires
- Idées pénalités motivationnelles
- Améliorations UX

## 📜 License

MIT License - Voir fichier LICENSE

---

**🚀 Prêt à commencer ?** `./install.sh` puis `learning` !