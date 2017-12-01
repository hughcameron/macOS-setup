#!/usr/bin/env bash
# Thanks to https://mths.be/macos

rm ~/Projects/initialise.sh

count=1

# Script's color palette
reset="\033[0m"
highlight="\033[41m\033[97m"
dot="\033[33m▸ $reset"
dim="\033[2m"
bold="\033[1m"

# Get full directory name of this script
cwd="$(cd "$(dirname "$0")" && pwd)"

# Keep-alive: update existing `sudo` time stamp until script has finished
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

headline() {
    printf "${highlight} %s ${reset}\n" "$@"
}

chapter() {
    echo -e "${highlight} $((count++)).) $@ ${reset}\n"
}

# Prints out a step, if last parameter is true then without an ending newline
step() {
    if [ $# -eq 1 ]
    then echo -e "${dot}$@"
    else echo -ne "${dot}$@"
    fi
}

run() {
    echo -e "${dim}▹ $@ $reset"
    eval $@
    echo ""
}

# Just a little welcome screen
echo ""
headline "                                                "
headline "        We are about to pimp your  Mac!        "
headline "     Follow the prompts and you’ll be fine.     "
headline "                                                "
echo ""

# Close any open System Preferences panes, to prevent them from overriding
# settings we’re about to change
osascript -e 'tell application "System Preferences" to quit'

# Ask for the administrator password upfront
if [ $(sudo -n uptime 2>&1|grep "load"|wc -l) -eq 0 ]
then
    step "Some of these settings are system-wide, therefore we need your permission."
    sudo -v
    echo ""
fi


###############################################################################
# PATH                                                                        #
###############################################################################

echo 'export PATH="/usr/local/bin:$PATH"' >> ~/.bash_profile
echo 'export PATH="/usr/local/bin:$PATH"' >> ~/.zshrc


###############################################################################
# General UI/UX                                                               #
###############################################################################

chapter "Adjusting general settings"

step "Setting your computer name (as done via System Preferences → Sharing)."
echo -ne "  What would you like it to be? $bold"
read computer_name
echo -e "$reset"
run sudo scutil --set ComputerName "'$computer_name'"
run sudo scutil --set HostName "'$computer_name'"
run sudo scutil --set LocalHostName "'$computer_name'"
run sudo defaults write /Library/Preferences/SystemConfiguration/com.apple.smb.server NetBIOSName -string "'$computer_name'"

# Disable OS X Gate Keeper - you’ll be able to install any app you want from here on, not just Mac App Store apps"
run sudo spctl --master-disable
run sudo defaults write /var/db/SystemPolicy-prefs.plist enabled -string no

# Disable the sudden motion sensor as it’s not useful for SSDs
run sudo pmset -a sms 0

# Increase window resize speed for Cocoa applications
run defaults write NSGlobalDomain NSWindowResizeTime -float 0.001

# Expand save panel by default
run defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true
run defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode2 -bool true

# Expand print panel by default
run defaults write NSGlobalDomain PMPrintingExpandedStateForPrint -bool true
run defaults write NSGlobalDomain PMPrintingExpandedStateForPrint2 -bool true

# Save to disk (not to iCloud) by default
run defaults write NSGlobalDomain NSDocumentSaveNewDocumentsToCloud -bool false

# Automatically quit printer app once the print jobs complete
run defaults write com.apple.print.PrintingPrefs "Quit When Finished" -bool true

# Disable the “Are you sure you want to open this application?” dialog
run defaults write com.apple.LaunchServices LSQuarantine -bool false

# Remove duplicates in the “Open With” menu (also see `lscleanup` alias)
run /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -kill -r -domain local -domain system -domain user

# Set Help Viewer windows to non-floating mode
run defaults write com.apple.helpviewer DevMode -bool true

# Enable full keyboard access for all controls? e.g. enable Tab in modal dialogs
run defaults write NSGlobalDomain AppleKeyboardUIMode -int 3

chapter "Adjusting Finder settings"

# Keep folders on top when sorting by name?
run defaults write com.apple.finder _FXSortFoldersFirst -bool true

# Disable the warning when changing a file extension?
run defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false

# Use list view in all Finder windows by default?
run defaults write com.apple.finder FXPreferredViewStyle -string '"Nlsv"'

# Finder: allow quitting via ⌘ + Q; doing so will also hide desktop icons
run defaults write com.apple.finder QuitMenuItem -bool true

# Set Desktop as the default location for new Finder windows
# For other paths, use `PfLo` and `file:///full/path/here/`
run defaults write com.apple.finder NewWindowTarget -string "PfDe"
run defaults write com.apple.finder NewWindowTargetPath -string "file://${HOME}/Desktop/"

# Finder: show status bar
run defaults write com.apple.finder ShowStatusBar -bool true

# Finder: show path bar
run defaults write com.apple.finder ShowPathbar -bool true

# Finder: allow text selection in Quick Look
run defaults write com.apple.finder QLEnableTextSelection -bool true

# When performing a search, search the current folder by default
run defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"

# Avoid creating .DS_Store files on network volumes
run defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true

# Use column view in all Finder windows by default
# Four-letter codes for the other view modes: `icnv`, `clmv`, `Flwv` `Nlsv`
run defaults write com.apple.finder FXPreferredViewStyle -string "clmv"

# Disable the warning before emptying the Trash
run defaults write com.apple.finder WarnOnEmptyTrash -bool false

# Empty Trash securely by default
run defaults write com.apple.finder EmptyTrashSecurely -bool true

# Enable highlight hover effect for the grid view of a stack (Dock)
run defaults write com.apple.dock mouse-over-hilite-stack -bool true

# Enable spring loading for all Dock items
run defaults write com.apple.dock enable-spring-load-actions-on-all-items -bool true

# Disable Dashboard
run defaults write com.apple.dashboard mcx-disabled -bool true

# Don’t show Dashboard as a Space
run defaults write com.apple.dock dashboard-in-overlay -bool true

chapter "Adjusting Mac App Store settings"

# Enable the automatic update check?
run defaults write com.apple.SoftwareUpdate AutomaticCheckEnabled -bool true

# Check for software updates daily, not just once per week?
run defaults write com.apple.SoftwareUpdate ScheduleFrequency -int 1

# Download newly available updates in background?
run defaults write com.apple.SoftwareUpdate AutomaticDownload -int 1

# Install System data files & security updates?
run defaults write com.apple.SoftwareUpdate CriticalUpdateInstall -int 1

# Turn on app auto-update?
run defaults write com.apple.commerce AutoUpdate -bool true

chapter "Installing…"

step "Homebrew\n"
which -s brew
if [[ $? != 0 ]] ; then
    run '/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"'
else
    run brew update
fi

step "Homebrew taps\n"

for repo in $(<$cwd/.stack/tap); do
    if ! brew tap -1 | grep -q "^${repo}\$"; then
run brew tap $repo
    fi
done

step "CLI apps\n"

for app in $(<$cwd/.stack/cli); do
    if ! brew list -1 | grep -q "^${app}\$"; then
run brew install $app
    fi
done

step "Desktop apps\n"

for app in $(<$cwd/.stack/desktop); do
    if ! brew cask list -1 | grep -q "^${app}\$"; then
run brew cask install $app
    fi
done

step "Apple Store apps\n"

for app in $(<$cwd/.stack/appstore); do
    if ! mas list -1 | grep -q "^${app}\$"; then
run mas install $app
    fi
done

step "Fonts\n"

for font in $(<$cwd/.stack/fonts); do
    if ! brew cask list -1 | grep -q "^${font}\$"; then
run brew cask install $font
    fi
done

step "Atom packages/themes\n"

for package in $(<$cwd/.stack/atom); do
    if [ ! -d ~/.atom/packages/$package ]; then
run apm install $package
    fi
done

step "Google Chrome Preferences\n"
run defaults write com.google.Chrome AppleEnableSwipeNavigateWithScrolls -bool false
run defaults write com.google.Chrome AppleEnableMouseSwipeNavigateWithScrolls -bool false

step "Prezto\n"

if [ ! -d ~/.zprezto ]; then
    run git clone --recursive https://github.com/sorin-ionescu/prezto.git ~/.zprezto
else
    run '(cd ~/.zprezto && git pull && git submodule update --init --recursive)'
fi

for rcfile in `find ~/.zprezto/runcoms ! -name "*.md" -type f`
do
  run ln -sfv $rcfile ~/.$(basename $rcfile)
done

run chsh -s /bin/zsh
run '(cd ~/.zprezto/modules/prompt/functions && curl -s -O https://raw.githubusercontent.com/chauncey-garrett/zsh-prompt-garrett/master/prompt_garrett_setup)'

chapter "Restoring…"

step "Dotfiles\n"
run ln -sfv $cwd/.zshrc ~
run ln -sfv $cwd/.zpreztorc ~
run ln -sfv $cwd/.gitconfig ~

step "Atom preferences\n"
run mkdir -pv ~/.atom
run ln -sfv $cwd/.atom/config.cson ~/.atom
run ln -sfv $cwd/.atom/keymap.cson ~/.atom
run ln -sfv $cwd/.atom/packages.cson ~/.atom
run ln -sfv $cwd/.atom/snippets.cson ~/.atom
run ln -sfv $cwd/.atom/toolbar.cson ~/.atom
run ln -sfv $cwd/.atom/styles.less ~/.atom

step "Set Dock Items\n"
for item in $(<$cwd/.stack/dock); do
    if ! dockutil list -1 | grep -q "^${item}\$"; then
run dockutil $item
    fi
done

step "iTerm2 preferences\n"
run ln -sfv $cwd/.iTerm2 ~
run defaults write com.googlecode.iterm2 LoadPrefsFromCustomFolder -int 1
run defaults write com.googlecode.iterm2 PrefsCustomFolder ~/.iTerm2

step "Set Dark Mode\n"
osascript <<EOF
tell application "System Events"
  tell appearance preferences
    set dark mode to true
  end tell
end tell
EOF

step "Set Profile Pic\n"
# Delete any Photo currently used.
run dscl . delete /Users/hugh jpegphoto
run sleep 1
# Delete File path
run dscl . delete /Users/hugh Picture
run sleep 1
# Set New Photo
run sudo dscl . create /Users/hugh Picture "$cwd/etc/phil.jpg"

step "Set wallpaper folder\n"
run sqlite3 "~/Library/Application\ Support/Dock/desktoppicture.db" "\"\
DELETE FROM data; \
DELETE FROM displays; \
DELETE FROM pictures; \
DELETE FROM preferences; \
DELETE FROM prefs; \
DELETE FROM spaces; \
INSERT INTO pictures (space_id, display_id) VALUES (null, null); \
INSERT INTO data (value) VALUES ('~/Library/Mobile Documents/com~apple~CloudDocs/Wallpaper'); \
INSERT INTO preferences (key, data_id, picture_id) VALUES (1, 1, 1); \
\""

osascript <<EOF
tell application "System Preferences"
    activate
    set the current pane to pane id "com.apple.preference.desktopscreeneffect"
end tell

delay 2

tell application "System Events" to tell process "System Preferences"
    click checkbox "Change picture:" of tab group 1 of window "Desktop & Screen Saver"
end tell
EOF

run killall Dock

###############################################################################
# Python Setup                                                                #
###############################################################################

# Removed user's cached credentials
# This script might be run with .dots, which uses elevated privileges
sudo -K

echo "------------------------------"
echo "Setting up pip."

# Install pip
easy_install pip

###############################################################################
# Virtual Enviroments                                                         #
###############################################################################

echo "------------------------------"
echo "Setting up virtual environments."

# Install virtual environments globally
# It fails to install virtualenv if PIP_REQUIRE_VIRTUALENV was true
export PIP_REQUIRE_VIRTUALENV=false
pip install virtualenv
pip install virtualenvwrapper

echo "------------------------------"
echo "Source virtualenvwrapper from ~/.extra"

EXTRA_PATH=~/.extra
echo $EXTRA_PATH
echo "" >> $EXTRA_PATH
echo "" >> $EXTRA_PATH
echo "# Source virtualenvwrapper, added by pydata.sh" >> $EXTRA_PATH
echo "export WORKON_HOME=~/.virtualenvs" >> $EXTRA_PATH
echo "source /usr/local/bin/virtualenvwrapper.sh" >> $EXTRA_PATH
echo "" >> $BASH_PROFILE_PATH
source $EXTRA_PATH

###############################################################################
# Python 2 Virtual Enviroment                                                 #
###############################################################################

echo "------------------------------"
echo "Setting up py2-data virtual environment."

# Create a Python2 data environment
mkvirtualenv py2-data
workon py2-data

# Install Python data modules
step "Install Python 2 Module\n"

for package in $(<$cwd/.stack/pip2); do
    if ! pip install list -1 | grep -q "^${package}\$"; then
run pip install install $package
    fi
done

###############################################################################
# Python 3 Virtual Enviroment                                                 #
###############################################################################

echo "------------------------------"
echo "Setting up py3-data virtual environment."

# Create a Python3 data environment
mkvirtualenv --python=/usr/local/bin/python3 py3-data
workon py3-data

# Install Python data modules
step "Install Python 3 Module\n"

for package in $(<$cwd/.stack/pip3); do
    if ! pip install list -1 | grep -q "^${package}\$"; then
run pip install install $package
    fi
done

###############################################################################
# Install IPython Profile
###############################################################################

echo "------------------------------"
echo "Installing IPython Notebook Default Profile"

# Add the IPython profile
mkdir -p ~/.ipython
cp -r init/profile_default/ ~/.ipython/profile_default

echo "------------------------------"
echo "Script completed."
echo "Usage: workon py2-data for Python2"
echo "Usage: workon py3-data for Python3"
