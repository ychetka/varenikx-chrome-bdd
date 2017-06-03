#################################################
## Hi. Read readme please.
#################################################

FROM ubuntu:14.04
MAINTAINER varenikx@gmail.com

###########env
ENV DEBIAN_FRONTEND noninteractive
ENV SCREEN_WIDTH 1280
ENV SCREEN_HEIGHT 1024
ENV SCREEN_DEPTH 24
ENV DISPLAY :0
ENV NVM_DIR /usr/local/nvm
ENV NVM_VERSION v0.33.2
ENV NODE_VERSION v7.10.0
ENV RUN ''

########### replace shell with bash so we can source files
RUN rm /bin/sh && ln -s /bin/bash /bin/sh

###########update
RUN apt-get update -qqy && apt-get -qqy --no-install-recommends install ca-certificates build-essential unzip wget apt-utils

###########nvm
RUN wget -qO- https://raw.githubusercontent.com/creationix/nvm/${NVM_VERSION}/install.sh | bash

###########nodejs
RUN /bin/bash -c "source $NVM_DIR/nvm.sh && nvm install $NODE_VERSION && nvm use --delete-prefix $NODE_VERSION"
ENV NODE_PATH $NVM_DIR/versions/node/$NODE_VERSION/lib/node_modules
ENV PATH      $NVM_DIR/versions/node/$NODE_VERSION/bin:$PATH

###########locale
ENV LANGUAGE en_US.UTF-8
ENV LANG en_US.UTF-8
RUN locale-gen en_US.UTF-8 \
  && dpkg-reconfigure --frontend noninteractive locales \
  && apt-get update -qqy \
  && apt-get -qqy --no-install-recommends install \
    language-pack-en

###########fonts
RUN apt-get -qqy --no-install-recommends install libfontconfig fontconfig xfonts-cyrillic xfonts-100dpi xfonts-75dpi xfonts-base xfonts-scalable

###########google-chrome-stable repository
RUN wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add -
RUN echo "deb http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google.list

###########install packages
RUN apt-get update -qqy --fix-missing && apt-get -qqy --no-install-recommends --fix-missing install default-jre libssl-dev libasound2 libxrender1 libxss1 fluxbox google-chrome-stable xvfb x11vnc x11-utils

###########user
RUN sudo useradd bdd --shell /bin/bash --create-home && sudo usermod -a -G sudo bdd && echo 'ALL ALL = (ALL) NOPASSWD: ALL' >> /etc/sudoers && echo 'bdd:bdd' | chpasswd

RUN rm /etc/apt/sources.list.d/google.list && rm -rf /var/lib/apt/lists/*

###########project
COPY entrypoint.sh /entrypoint.sh
COPY away_init.sh /away_init.sh
COPY init_headless.sh /init_headless.sh

RUN chmod 777 /entrypoint.sh
RUN chmod +x /entrypoint.sh
RUN chmod 777 /away_init.sh
RUN chmod +x /away_init.sh
RUN chmod 777 /init_headless.sh
RUN chmod +x /init_headless.sh

CMD ["su", "-", "bdd", "-c", "/bin/bash"]

###########config x11vnc
RUN mkdir -p ~/.vnc && x11vnc -storepasswd bdd ~/.vnc/passwd

ENTRYPOINT ["/entrypoint.sh"]

EXPOSE 5900
