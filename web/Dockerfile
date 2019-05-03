FROM appertaopeneyes/base-apache:latest

ARG BUILD_BRANCH="master"
ARG BUILD_WROOT="/var/www/openeyes"
ARG BUILD_SAMPLE="TRUE"
ARG BUILD_LOCAL_DB="FALSE"
	# By default we expect an external database container to be used
	# Set this arg to TRUE to install mariadb inside the container

ARG DEBIAN_FRONTEND="noninteractive"

ENV BUILD_BRANCH=$BUILD_BRANCH

## Database connection credentials:
## It is STRONGLY recommended to change the password for production environments
## It is STRONGLY recommended to use docker secrets for DATABASE_PASS, rather than env variables
## defaults are localhost; openeyes; 3306; openeyes; openeyes
ENV DATABASE_HOST="localhost"
ENV DATABASE_NAME="openeyes"
ENV DATABASE_PASS="openeyes"
ENV DATABASE_PORT="3306"
ENV DATABASE_USER="openeyes"

## Used by some scripts to determine if they are runing in a container
ENV DOCKER_CONTAINER="TRUE"

ENV GIT_ORG=""
ENV GIT_USER=""
ENV GIT_EMAIL=""

ENV LOCAL_DB=${BUILD_LOCAL_DB}

## MySQL/MariaDB root login credentials (used for install / reset scripts)
## It is strongly recommended that you use docker secrets or similar methods
## To set these, as opposed to using environment variables!
## It is also STRONGLY recommended to change your root password in production
## environments
ENV MYSQL_ROOT_PASSWORD=""
ENV MYSQL_SUPER_USER="root"

ENV OE_DOCMAN_EXPORT_DIRECTORY=""
ENV OE_MODE="DEV"
ENV OE_PORTAL_URI=""
ENV OE_PORTAL_EXTERNAL_URI=""
ENV OE_PORTAL_USERNAME=""
ENV OE_PORTAL_PASSWORD=""
ENV OE_PORTAL_CLIENT_ID=""
ENV OE_PORTAL_CLIENT_SECRET=""
ENV OE_PORTAL_ENABLED="FALSE"
ENV OE_SIGNATURE_APP_URL=""
ENV OE_INSTITUTION_CODE=""
ENV SSH_AUTHORIZED_KEYS=""
ENV SSH_PRIVATE_KEY=""
ENV SSH_SERVER_ENABLE="FALSE"
# If TRACK_NEW_GIT_COMMITS=true, then the container will run oe-update every 30 minutes as a cron job
ENV TRACK_NEW_GIT_COMMITS="FALSE"
ENV TZ="Europe/London"
ENV USE_DEMO_DATA="TRUE"
ENV WROOT="$BUILD_WROOT"

# set up folders
RUN cd / && mkdir -p $WROOT

# ARG CACHEBUSTER=$RANDOM
	# Use this to prevent build cache using an old version of source files

# If installing mysql into the image, setup mariadb and
# bind to accept connections from remote servers
RUN [ "$BUILD_LOCAL_DB" = "TRUE" ] && { apt-get update && apt-get install -y --no-install-recommends mariadb-server mariadb-client \
        && sed -i "s/\s*bind-address\s*=\s*127\.0\.0\.1/bind-address    = 0.0.0.0/" /etc/mysql/my.cnf \
        && sed -i "s/\s*bind-address\s*=\s*127\.0\.0\.1/bind-address    = 0.0.0.0/" /etc/mysql/mariadb.conf.d/50-server.cnf \
        && apt-get autoremove -y \
        && rm -rf /var/lib/apt/lists/* ; } || :

RUN chgrp -R www-data $WROOT

# Add the init script
COPY init.sh /init.sh
RUN chmod a+rx /init.sh

EXPOSE 80 3306

ENTRYPOINT /init.sh
