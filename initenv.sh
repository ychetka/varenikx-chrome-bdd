#!/bin/bash

NVM_VERSION="v0.33.11"
NODE_VERSION="v8.11.2"
NVM_DIR="/home/bdd/.nvm"

sudo apt-get update -qqy
sudo apt-get -qqy --no-install-recommends install git apt-utils ca-certificates unzip wget git jq sudo bzip2 mc locales locales-all sqlite3


LC_ALL="en_US.UTF-8"
LANG="en_US.UTF-8"
LANGUAGE="en_US.UTF-8"

export LC_ALL
export LANG
export LANGUAGE

wget -qO- https://raw.githubusercontent.com/creationix/nvm/${NVM_VERSION}/install.sh | bash
export NVM_DIR="$HOME/.nvm"; [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm

#nvm install "${NODE_VERSION}"
#nvm use ${NODE_VERSION}
nvm alias default "${NODE_VERSION}"

npm install -g yarn

#fonts
apt-get update -qqy \
  && apt-get -qqy --no-install-recommends install \
    fonts-ipafont-gothic \
    xfonts-100dpi \
    xfonts-75dpi \
    xfonts-cyrillic \
    xfonts-scalable \
    xfonts-base \
    xfonts-scalable \
    fontconfig \
    libfontconfig

NODE_PATH="${NVM_DIR}/versions/node/${NODE_VERSION}/lib/node_modules"
PATH="${NVM_DIR}/versions/node/${NODE_VERSION}/bin:$PATH"

export PATH
export NODE_PATH

source $NVM_DIR/nvm.sh
nvm install $NODE_VERSION
nvm use --delete-prefix $NODE_VERSION
nvm alias default $NODE_VERSION



