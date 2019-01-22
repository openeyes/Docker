FROM appertaopeneyes/base-apache

ARG BUILD_BRANCH="develop"
ARG BUILD_WROOT="/var/www/openeyes"
ARG BUILD_SAMPLE="TRUE"
ARG BUILD_LOCAL_DB="FALSE"
	# By default we expect an external database container to be used
	# Set this arg to TRUE to install mariadb inside the container

ARG DEBIAN_FRONTEND="noninteractive"

ENV WROOT="$BUILD_WROOT"

ENV TZ="Europe/London"
ENV OE_MODE="DEV"
ENV LOCAL_DB=${BUILD_LOCAL_DB}
ENV BUILD_BRANCH=$BUILD_BRANCH
ENV SSH_PRIVATE_KEY=""
## Used by some scripts to determine if they are runing in a container
ENV DOCKER_CONTAINER="TRUE"

## Database connection credentials:
## It is STRONGLY recommended to change the password for production environments
## It is STRONGLY recommended to use docker secrets for DATABASE_PASS, rather than env variables
## defaults are localhost; openeyes; 3306; openeyes; openeyes
ENV DATABASE_HOST="localhost"
ENV DATABASE_NAME="openeyes"
ENV DATABASE_PORT="3306"
ENV DATABASE_USER="openeyes"
ENV DATABASE_PASS="openeyes"
ENV USE_DEMO_DATA="TRUE"

ENV GIT_ORG=""
ENV GIT_USER=""
ENV GIT_EMAIL=""

## MySQL/MariaDB root login credentials (used for install / reset scripts)
## It is strongly recommended that you use docker secrets or similar methods
## To set these, as opposed to using environment variables!
## It is also STRONGLY recommended to change your root password in production
## environments
ENV MYSQL_ROOT_PASSWORD=""
ENV MYSQL_SUPER_USER="root"

WORKDIR /

# set up folders
RUN mkdir $WROOT

# ARG CACHEBUSTER=$RANDOM
	# Use this to prevent build cache using an old version of source files

RUN [ "$BUILD_LOCAL_DB" = "TRUE" ] && { apt-get update && apt-get install -y mariadb-server mariadb-client \
        && apt-get autoremove -y \
        && rm -rf /var/lib/apt/lists/* ; }

RUN chgrp -R www-data $WROOT

# Add the init script
COPY ./init.sh /init.sh
RUN chmod a+rx /init.sh

EXPOSE 80 3306

ENTRYPOINT /init.sh
