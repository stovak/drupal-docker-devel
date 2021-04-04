FROM solr:7.7

USER root

## SOLR
ENV SOLR_HOST solr
ENV SOLR_PORT 8983
ENV SOLR_PATH /
ENV SOLR_CORE ${PANTHEON_SITE_NAME}

LABEL org.label-schema.vendor="pantheon" \
  org.label-schema.name=$REPO_NAME \
  org.label-schema.description="Prettier is an opinionated code formatter." \
  org.label-schema.build-date=$BUILD_DATE \
  org.label-schema.version=$VERSION \
  org.label-schema.vcs-ref=$VCS_REF \
  org.label-schema.vcs-url="https://github.com/$REPO_NAME" \
  org.label-schema.usage="https://github.com/$REPO_NAME/blob/master/README.md#usage" \
  org.label-schema.docker.cmd="docker run --rm -v \$PWD:/work $REPO_NAME --parser=markdown --write '**/*.md'" \
  org.label-schema.schema-version="1.0"

RUN apt-get update && \
  apt-get install -y --fix-missing make \
        supervisor \
        curl \
        vim \
        procps \
        apt-utils \
        zip \
        sudo

RUN set -ex
RUN mkdir -p /opt/solr/server/solr/mycores/milken/data
RUN chmod -R 777 /opt/solr/server/solr/mycores/milken
RUN mkdir -p /opt/solr/server/solr/configsets/_default/conf

COPY ./7.x/* /opt/solr/server/solr/configsets/_default/conf/
COPY init_solr /docker-entrypoint-initdb.d/
COPY actions.mk /usr/local/bin/actions.mk
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

RUN echo "export PATH=/usr/local/openjdk-11:$PATH" >> /opt/solr/.bashrc
RUN echo "export PATH=/usr/local/openjdk-11:$PATH" >> /root/.bashrc

EXPOSE 8983
WORKDIR /opt/solr

CMD [ "/usr/bin/supervisord" ]
