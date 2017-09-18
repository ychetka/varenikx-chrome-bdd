# DOCKER-VERSION 1.6.0
# DESCRIPTION    Bdd in chrome browser and vnc for linux hosts

# Pull base image
FROM debian:8.8

ENV DEBIAN_FRONTEND noninteractive
ENV SCREEN_WIDTH 1920
ENV SCREEN_HEIGHT 1080
ENV SCREEN_DEPTH 24
ENV DISPLAY :0
ENV NVM_VERSION v0.33.2
ENV NODE_VERSION v7.10.0
ENV WORKDIR "/project"
ENV RUN ''
ENV HOME "/home/bdd"
ENV NVM_DIR "/home/bdd/.nvm"

#base
RUN apt-get update -qqy && apt-get -qqy --no-install-recommends install ca-certificates unzip wget git jq sudo bzip2 mc

#user
RUN sudo useradd bdd --shell /bin/bash --create-home && sudo usermod -a -G sudo bdd && echo 'ALL ALL = (ALL) NOPASSWD: ALL' >> /etc/sudoers && echo 'bdd:bdd' | chpasswd

#chrome
RUN wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add -
RUN echo "deb http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google-chrome.list
RUN apt-get update -qqy && apt-get -qqy install google-chrome-stable

RUN chmod 777 $HOME && chmod -R 777 $HOME

#nvm
USER bdd
RUN wget -qO- https://raw.githubusercontent.com/creationix/nvm/v0.33.2/install.sh | bash

#nodejs
RUN /bin/bash -c "source $NVM_DIR/nvm.sh && nvm install $NODE_VERSION && nvm use --delete-prefix $NODE_VERSION"
ENV NODE_PATH $NVM_DIR/versions/node/$NODE_VERSION/lib/node_modules
ENV PATH      $NVM_DIR/versions/node/$NODE_VERSION/bin:$PATH

#yarn
RUN npm install -g yarn

USER root


#Xvfb
RUN apt-get update -qqy && apt-get -qqy install xvfb

#vnc
RUN apt-get update -qqy && apt-get -qqy install x11vnc

#vnc

USER bdd
RUN mkdir -p $HOME/.vnc && x11vnc -storepasswd bdd $HOME/.vnc/passwd

USER root
#locale
RUN apt-get update -qqy && apt-get -qqy --no-install-recommends install locales locales-all
ENV LC_ALL en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US.UTF-8

#fonts
RUN apt-get update -qqy \
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


#fluxbox
RUN apt-get update -qqy && apt-get -qqy install fluxbox

#java
RUN apt-get update -qqy \
  && apt-get -qqy install \
    default-jre \
    libssl-dev \
    libasound2 \
    libxrender1 \
    libxss1 \
  && rm -rf /var/lib/apt/lists/*



COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
RUN apt-get update -qqy && apt-get -qqy --no-install-recommends install bzip2
EXPOSE 5900

CMD ["su", "-", "bdd", "-c", "/bin/bash"]
USER bdd

ENTRYPOINT ["/entrypoint.sh"]