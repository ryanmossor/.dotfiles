#!/usr/bin/env bash
# shellcheck disable=2154

if ! have indicator-sound-switcher; then
    sudo apt-add-repository -y ppa:yktooo/ppa
    sudo apt-get update
    sudo apt-get install -y indicator-sound-switcher
fi

