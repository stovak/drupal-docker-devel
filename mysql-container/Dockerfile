# Derived from official mysql image (our base image)
FROM mariadb:10.4
# Add a database
ENV MYSQL_DATABASE drupal8
ENV MYSQL_ROOT_PASSWORD drupal

RUN apt-get update && \
  apt-get install -y --fix-missing \
  expect \
  procps

# Add the content of the sql-scripts/ directory to your image
# All scripts in docker-entrypoint-initdb.d/ are automatically
# executed during container startup

WORKDIR /tmp
RUN apt-get update -y
RUN apt-get install -y jq curl zip

COPY ./my.cnf /etc/mysql/conf.d/milken.cnf
COPY ./entrypoint/* /docker-entrypoint-initdb.d/
RUN chmod +x /docker-entrypoint-initdb.d/*
RUN mkdir /home/mysql
RUN chmod -R 700 /home/mysql
RUN chown mysql:mysql /home/mysql
RUN chown -R mysql:mysql /var/lib/mysql
RUN chmod -R 700 /var/lib/mysql

USER mysql

USER root

ENTRYPOINT [ "/docker-entrypoint.sh" ]

EXPOSE 3306 33060

CMD [ "mysqld" ]
