#!/usr/bin/env bash

sudo apt-get install -y nodejs npm
npm config set prefix ~/.local/npm
npm i -g n
n lts

