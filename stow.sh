#!/usr/bin/env bash

blue='\033[1;94m'
green='\033[1;92m'
clear='\033[0m'

stow_apps() {
    local target_dir="$1"
    shift # removes first param & shifts others 1 to left, allowing use of "$@" to reference list of app names
    local apps=("$@")

    for app in "${apps[@]}"; do
        echo -e "Stowing ${green}${app}${clear} in ${blue}${target_dir}${clear}"
        stow -Rt "$target_dir" "$app"
    done
}

unstow_apps() {
    local apps=("$@")
    for app in "${apps[@]}"; do
        echo "Removing $app"
        stow -D "$app"
    done
}

packages=(
    bat
    curl
    fzf
    git
    htop
    jq
    neofetch
    ripgrep
    stow
    tmux
    vim
    wget
    zsh
)

install_packages() {
    echo "Updating required packages..."
    if [[ $(uname -s) == "Darwin" ]]; then
        brew update > /dev/null 2>&1
        brew upgrade > /dev/null 2>&1
        brew install "${packages[@]}" > /dev/null 2>&1
    else
        echo "Updating required packages..."
        sudo apt update > /dev/null 2>&1
        sudo apt upgrade -y > /dev/null 2>&1
        sudo apt install "${packages[@]}" -y > /dev/null 2>&1
    fi
}

base=(
    bat
    scripts
    #tmux
    vim
    zsh
)

personal=(
    devilspie2
    #i3
    rofi
)

windows=(
    pwsh
    vim # vim goes to both $HOME and $WIN_HOME
    vsvim
)

while [[ "$#" -gt 0 ]]; do
    case $1 in
        -d|-r|--delete|--remove)
            unstow_apps "${base[@]}" "${personal[@]}" "${windows[@]}"
            exit
            ;;
        -i|--init|--install)
            install_packages
            [[ $(uname -a) == *mint* ]] && sudo apt install xclip
            [[ $(uname -s) != "Darwin" ]] && sudo apt install openssh-server
            ;;
        -p|--personal)
            stow_apps "$HOME" "${personal[@]}"
            ;;
        -w|--windows)
            stow_apps "$WIN_HOME" "${windows[@]}"
            ;;
        *)
            echo "Unknown option: $1"
            exit
            ;;
    esac
    shift
done
 
stow_apps "$HOME" "${base[@]}"
