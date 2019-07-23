FROM appertaopeneyes/web-allin1:latest

ARG BUILD_BRANCH="develop"
ARG BUILD_WROOT="/var/www/openeyes"
ARG BUILD_SAMPLE="TRUE"
ARG BUILD_LOCAL_DB="TRUE"

## THE REST OF THIS FILE IS IDENTICAL TO THE MAIN web Dockerfile
## This file exists only to workaround Docjer Hub's daft inability
## to set build arguments!

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
ENV OE_MODE="TEST"
ENV OE_PORTAL_URI=""
ENV OE_PORTAL_EXTERNAL_URI=""
ENV OE_PORTAL_USERNAME=""
ENV OE_PORTAL_PASSWORD=""
ENV OE_PORTAL_CLIENT_ID=""
ENV OE_PORTAL_CLIENT_SECRET=""
ENV OE_PORTAL_ENABLED="FALSE"
ENV OE_SIGNATURE_APP_URL=""
ENV OE_INSTITUTION_CODE=""
# Used to pass extra command line switches to phpunit when running in test mode
ENV PHPUNIT_CLI_SWITCHES=""
ENV SSH_AUTHORIZED_KEYS=""
ENV SSH_PRIVATE_KEY=""
ENV SSH_SERVER_ENABLE="FALSE"
# If TRACK_NEW_GIT_COMMITS=true, then the container will run oe-update every 30 minutes as a cron job
ENV TRACK_NEW_GIT_COMMITS="FALSE"
ENV TZ="Europe/London"
ENV USE_DEMO_DATA="TRUE"
ENV WROOT="$BUILD_WROOT"

RUN git clone --single-branch --branch master --depth 1 https://github.com/appertafoundation/sample.git /sample \
        && unzip /sample/sql/sample_db.zip -d /sample \
        && service mysql start \
        && export dbresetsql="drop database if exists openeyes; create database ${DATABASE_NAME:-openeyes}; grant all privileges on ${DATABASE_NAME:-openeyes}.* to '${DATABASE_USER:-openeyes}'@'%' identified by '${DATABASE_PASS:-openeyes}'; flush privileges;" \
        && [ ! -z ${MYSQL_ROOT_PASSWORD} ] && export dbpw="-p${MYSQL_ROOT_PASSWORD}" || export dbpw="" \
        && echo "" \
        && eval "echo ***RUNNING COMMAND*** $dbpw -e \"${dbresetsql}\"" \
        && eval "mysql $dbpw -e \"${dbresetsql}\"" \
        && echo "" \
        && echo "Re-importing database... " \
        && echo "*** RUNING COMMAND*** mysql -u${MYSQL_SUPER_USER} $dbpw -D ${DATABASE_NAME:-'openeyes'} < sample/openeyes_sample_data.sql" \
        && eval "mysql -u${MYSQL_SUPER_USER} $dbpw -D ${DATABASE_NAME:-'openeyes'} < sample/openeyes_sample_data.sql" \
        && echo "cleaning up..." \
        && rm -rf /sample


EXPOSE 80 3306 22

ENTRYPOINT ["/init.sh"]
