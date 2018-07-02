FROM mariadb:10.3

ENV MYSQL_ROOT_PASSWORD="password"
ENV TZ=Europe/London

RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

ADD mysql /var/lib/mysql
