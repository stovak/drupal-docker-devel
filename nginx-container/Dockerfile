FROM nginx:mainline-perl
ENV DEBIAN_FRONTEND=noninteractive

WORKDIR /tmp

RUN apt-get update -y --fix-missing && apt-get install -y \
      gnupg2 \
      curl

RUN curl -sS -o - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add -
RUN echo "deb [arch=amd64]  http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google-chrome.list

RUN apt-get update -y --fix-missing && apt-get install -y \
      syncthing \
      supervisor \
      gvfs \
      vim \
      procps \
      apt-utils \
      zip \
      unzip \
      xvfb \
      libxi6 \
      libgconf-2-4 \
      gnupg2 \
      google-chrome-stable



RUN mkdir -p /usr/share/man/man1
RUN apt-get update -y --fix-missing && apt-get -yf install   default-jre-headless default-jdk-headless default-jre default-jdk

RUN wget https://chromedriver.storage.googleapis.com/2.41/chromedriver_linux64.zip
RUN unzip chromedriver_linux64.zip
RUN mv chromedriver /usr/bin/chromedriver
RUN chown root:root /usr/bin/chromedriver
RUN chmod +x /usr/bin/chromedriver
RUN wget https://selenium-release.storage.googleapis.com/3.9/selenium-server-standalone-3.9.1.jar
RUN mv selenium-server-standalone-3.9.1.jar /opt/selenium-server-standalone.jar

COPY ./nginx /etc/nginx
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY ./docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh
RUN rm -rf /var/lib/apt/lists/*
WORKDIR /

EXPOSE 80

STOPSIGNAL SIGTERM

ENTRYPOINT [ "/docker-entrypoint.sh" ]
CMD [ "/usr/bin/supervisord" ]
