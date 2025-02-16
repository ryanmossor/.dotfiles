zsh_dir="$HOME/.zsh"

function github_latest_tag() {
    local repo="$1"
    curl -s "https://api.github.com/repos/${repo}/releases/latest" | jq -r '.tag_name' | sed 's/v//'
}

function source_file() {
    [[ -f "$1" ]] && source "$1"
}

function plug() {
    plugin_name=$(echo "$1" | cut -d "/" -f 2)
    if [[ -d "$zsh_dir/plugins/$plugin_name" ]]; then 
        source_file "$zsh_dir/plugins/$plugin_name/$plugin_name.plugin.zsh" || \
        source_file "$zsh_dir/plugins/$plugin_name/$plugin_name.zsh"
    else
        git clone "https://github.com/$1.git" "$zsh_dir/plugins/$plugin_name"
        source_file "$zsh_dir/plugins/$plugin_name/$plugin_name.plugin.zsh" || \
        source_file "$zsh_dir/plugins/$plugin_name/$plugin_name.zsh"
    fi
}

function add_completion() {
    plugin_name=$(echo "$1" | cut -d "/" -f 2)
    if [[ -d "$zsh_dir/plugins/$plugin_name" ]]; then 
		completion_file_path=$(ls "$zsh_dir/plugins/$plugin_name/_*")
		fpath+="$(dirname "${completion_file_path}")"
        source_file "$zsh_dir/plugins/$plugin_name/$plugin_name.plugin.zsh"
    else
        git clone "https://github.com/$1.git" "$zsh_dir/plugins/$plugin_name"
		fpath+=$(ls "$zsh_dir/plugins/$plugin_name/_*")
        [[ -f $zsh_dir/.zccompdump ]] && "$zsh_dir/.zccompdump"
    fi
	completion_file="$(basename "${completion_file_path}")"
	[[ "$2" = true ]] && compinit "${completion_file:1}"
} 

function update() {
    [ -x /usr/bin/flatpak ] && flatpak update -y
    [[ $(uname -s) == "Darwin" ]] && brew update && brew upgrade

    if [[ $(uname -a) == *Ubuntu* ]]; then
        sudo apt update
        sudo apt upgrade -y

        # update lazygit
        lazygit_current=$(lazygit -v 2> /dev/null | cut -d ' ' -f 6 | sed 's/version=\(.*\),/\1/')
        lazygit_latest=$(github_latest_tag "jesseduffield/lazygit")
        if [[ "$lazygit_current" != "$lazygit_latest" ]]; then
            pushd /tmp > /dev/null || exit
            curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/download/v${lazygit_latest}/lazygit_${lazygit_latest}_Linux_x86_64.tar.gz"
            tar xf lazygit.tar.gz lazygit
            sudo install lazygit -D -t /usr/local/bin/
            popd > /dev/null || exit
        else
            echo "Lazygit already up to date."
        fi

        yazi_latest=$(github_latest_tag "sxyazi/yazi")
        yazi_current=$(yazi --version | cut -d ' ' -f 2)
        if [[ "$yazi_current" != "$yazi_latest" ]]; then
            pushd /tmp > /dev/null || exit
            curl -Lo yazi.zip "https://github.com/sxyazi/yazi/releases/download/v${yazi_latest}/yazi-x86_64-unknown-linux-gnu.zip"
            mkdir -p yazi
            unzip yazi.zip
            sudo install yazi-x86_64-unknown-linux-gnu/yazi -D -t /usr/local/bin/
            popd > /dev/null || exit
        else
            echo "Yazi already up to date."
        fi
    fi

    # update neovim
    nvim_current=$(nvim -v | head -n 1 | sed 's/NVIM v\(.*\)$/\1/')
    nvim_latest=$(github_latest_tag "neovim/neovim")

    if [[ "$nvim_current" != "$nvim_latest" ]]; then
        [ ! -d ~/code/neovim ] && git clone https://github.com/neovim/neovim.git ~/code/neovim
        pushd ~/code/neovim > /dev/null || exit
        git checkout stable && git pull
        make CMAKE_BUILD_TYPE=RelWithDebInfo && sudo make install 
        popd > /dev/null || exit
    else
        echo "Neovim already up to date."
    fi

    # update fzf
    pushd ~/.fzf > /dev/null &&
    git pull &&
    ./install --key-bindings --completion --no-update-rc &&
    popd > /dev/null
}

function fzf-cd-code-projects() {
    local dirs=(
        "$HOME/code"
        "$HOME/code/work"
        "$WIN_HOME/code"
        "$WIN_HOME/code/work"
        "$WIN_HOME/code/work/candidates"
    )

    local selected=$(fd . "${dirs[@]}" --exact-depth 1 -t d &> /dev/null | fzf)

    if [[ -n "$selected" ]]; then
        cd "$selected"
        [[ $TERM_PROGRAM == "WezTerm" ]] && wez cli set-tab-title $(basename $(pwd))
    fi
}

function setdiff() {
    if [ ! -f /tmp/before.txt ]; then
        adb shell settings list global > /tmp/before.txt
        adb shell settings list secure >> /tmp/before.txt
        adb shell settings list system >> /tmp/before.txt
        adb shell settings list --lineage global >> /tmp/before.txt
        adb shell settings list --lineage secure >> /tmp/before.txt
        adb shell settings list --lineage system >> /tmp/before.txt

        echo "Current settings written to /tmp/before.txt"
    else
        adb shell settings list global > /tmp/after.txt
        adb shell settings list secure >> /tmp/after.txt
        adb shell settings list system >> /tmp/after.txt
        adb shell settings list --lineage global >> /tmp/after.txt
        adb shell settings list --lineage secure >> /tmp/after.txt
        adb shell settings list --lineage system >> /tmp/after.txt

        diff --color /tmp/before.txt /tmp/after.txt
        rm /tmp/before.txt /tmp/after.txt
    fi
}
