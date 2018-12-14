# DOCKER VERSION 18.06.1-ce, build e68fc7a
# DESCRIPTION PUPPETEER+CUCUMBER BDD IMAGE

# EXAMPLE
# docker run --rm --name 52cf7563-df97-43a0-aeb6-b18dca455522 -e ID=52cf7563-df97-43a0-aeb6-b18dca455522 -e FAILEDPARSER=node ./bin/cucumber-failed-parser.js -e RUN=yarn run test:bdd --dockerMode=true --useLocalProxy=true --filter "features/_service/test-trash-typing.feature" --apiHost="bdd1.optimacros.com" -v /home/bdd/96cfde18-2872-451c-86db-4809101cf0a5/{52cf7563-df97-43a0-aeb6-b18dca455522}/:/52cf7563-df97-43a0-aeb6-b18dca455522 -v /home/bdd/src/:/project varenikx/chrome-bdd:latest


FROM debian:latest

ENV DEBIAN_FRONTEND noninteractive
#ENV SCREEN_WIDTH 1920
#ENV SCREEN_HEIGHT 1080
#ENV SCREEN_DEPTH 24
#ENV DISPLAY :0
ENV NVM_VERSION v0.33.2
ENV NODE_VERSION v6.11.3
ENV WORKDIR "/project"
ENV RUN ''
ENV HOME "/home/bdd"
ENV NVM_DIR "/home/bdd/.nvm"


#base
RUN apt-get update -qqy && apt-get -qqy --no-install-recommends install apt-utils ca-certificates unzip wget git jq sudo bzip2 mc

#puppeter dependences
RUN apt-get update && \
    apt-get -y install xvfb gconf-service libasound2 libatk1.0-0 libc6 libcairo2 libcups2 \
      libdbus-1-3 libexpat1 libfontconfig1 libgcc1 libgconf-2-4 libgdk-pixbuf2.0-0 libglib2.0-0 \
      libgtk-3-0 libnspr4 libpango-1.0-0 libpangocairo-1.0-0 libstdc++6 libx11-6 libx11-xcb1 libxcb1 \
      libxcomposite1 libxcursor1 libxdamage1 libxext6 libxfixes3 libxi6 libxrandr2 libxrender1 libxss1 \
      libxtst6 ca-certificates fonts-liberation libappindicator1 libnss3 lsb-release xdg-utils wget && \
    rm -rf /var/lib/apt/lists/*

#user
RUN useradd -r -m -G audio,video,sudo -s /bin/bash bdd && echo 'ALL ALL = (ALL) NOPASSWD: ALL' >> /etc/sudoers && echo 'bdd:bdd' | chpasswd

#chrome
#RUN wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add -
#RUN echo "deb http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google-chrome.list
#RUN apt-get update -qqy && apt-get -qqy install google-chrome-stable

RUN chmod 777 $HOME && chmod -R 777 $HOME

#nvm
USER bdd
RUN wget -qO- https://raw.githubusercontent.com/creationix/nvm/$NVM_VERSION/install.sh | bash

#nodejs
RUN /bin/bash -c "source $NVM_DIR/nvm.sh && nvm install $NODE_VERSION && nvm use --delete-prefix $NODE_VERSION"
ENV NODE_PATH $NVM_DIR/versions/node/$NODE_VERSION/lib/node_modules
ENV PATH      $NVM_DIR/versions/node/$NODE_VERSION/bin:$PATH

#yarn
RUN npm install -g yarn

USER root


#Xvfb
#RUN apt-get update -qqy && apt-get -qqy install xvfb

#vnc
#RUN apt-get update -qqy && apt-get -qqy install x11vnc

#vnc

#USER bdd
#RUN mkdir -p $HOME/.vnc && x11vnc -storepasswd bdd $HOME/.vnc/passwd

#USER root
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
#RUN apt-get update -qqy && apt-get -qqy install fluxbox

#java
#RUN apt-get update -qqy \
#  && apt-get -qqy install \
#    default-jre \
#    libssl-dev \
#    libasound2 \
#    libxrender1 \
#    libxss1 \
#  && rm -rf /var/lib/apt/lists/*

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

#EXPOSE 5900

CMD ["su", "-", "bdd", "-c", "/bin/bash"]
USER bdd

ENTRYPOINT ["/entrypoint.sh"]