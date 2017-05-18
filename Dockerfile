#################################################
## Hi. Run it with -v / path_to_project ##
## This mount you project when in container.   ##
#################################################

FROM ubuntu:14.04
MAINTAINER varenikx@gmail.com

###########env
ENV DEBIAN_FRONTEND noninteractive
ENV SCREEN_WIDTH 1280
ENV SCREEN_HEIGHT 1024
ENV SCREEN_DEPTH 24
ENV DISPLAY :0

###########update
RUN apt-get update -qqy && apt-get -qqy --no-install-recommends install ca-certificates unzip wget apt-utils

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
RUN apt-get update -qqy --fix-missing && apt-get -qqy --no-install-recommends --fix-missing install default-jre build-essential libssl-dev libasound2 libxrender1 libxss1 fluxbox google-chrome-stable xvfb x11vnc

###########user
RUN sudo useradd bdd --shell /bin/bash --create-home && sudo usermod -a -G sudo bdd && echo 'ALL ALL = (ALL) NOPASSWD: ALL' >> /etc/sudoers && echo 'bdd:bdd' | chpasswd

RUN rm /etc/apt/sources.list.d/google.list && rm -rf /var/lib/apt/lists/*

###########project
COPY entrypoint.sh /entrypoint.sh

RUN chmod 777 /entrypoint.sh
RUN chmod +x /entrypoint.sh

CMD ["su", "-", "bdd", "-c", "/bin/bash"]

###########config x11vnc
RUN mkdir -p ~/.vnc && x11vnc -storepasswd bdd ~/.vnc/passwd

ENTRYPOINT ["/entrypoint.sh"]

EXPOSE 5900
