FROM appertaopeneyes/web-allin1:php7

ARG BUILD_BRANCH="develop"
ARG DEBIAN_FRONTEND="noninteractive"

## NOTE: This image uses default ENV options from base image, unless explicitly overridden below

# The main difference between this and the base web image is that mode is that it contains a ready built and migrated database, which speeds up CI build time considerably


# ENV BUILD_BRANCH=$BUILD_BRANCH

ENV OE_MODE="TEST"

# Used to pass extra command line switches to phpunit when running in test mode
ENV PHPUNIT_CLI_SWITCHES=""

# Used to pass extra command switches to the behat cli
ENV BEHAT_CLI_SWITCHES=""

# Used to specify the path to the config file to use for BEHAT (default is $WROOT/behat.yml)
ENV BEHAT_CONFIG_PATH=""

# Used to specify the path to the test file/folder that you want to run
ENV BEHAT_TEST_PATH=""

# A comma separated (no spaces) list of tests to run. Options are: 
##   PHPUNIT
##   BEHAT
# Note that if running > 1 test suite, then the database will be reset between each set
ENV TESTS_TO_RUN="PHPUNIT"

ENV TRACK_NEW_GIT_COMMITS="FALSE"

RUN git clone --single-branch --branch master --depth 1 https://github.com/appertafoundation/sample.git /sample \
        && unzip /sample/sql/sample_db.zip -d /sample \
        && service mysql start \
        && export dbresetsql="drop database if exists openeyes; create database ${DATABASE_NAME:-openeyes}; grant all privileges on ${DATABASE_NAME:-openeyes}.* to '${DATABASE_USER:-openeyes}'@'%' identified by '${DATABASE_PASS:-openeyes}'; flush privileges;" \
        && [ -n "${MYSQL_ROOT_PASSWORD}" ] && export dbpw="-p${MYSQL_ROOT_PASSWORD}" || export dbpw="" \
        && echo "" \
        && eval "echo ***RUNNING COMMAND*** $dbpw -e \"${dbresetsql}\"" \
        && eval "mysql $dbpw -e \"${dbresetsql}\"" \
        && echo "" \
        && echo "Re-importing database... " \
        && echo "*** RUNING COMMAND*** mysql -u${MYSQL_SUPER_USER} $dbpw -D ${DATABASE_NAME:-'openeyes'} < sample/openeyes_sample_data.sql" \
        && eval "mysql -u${MYSQL_SUPER_USER} $dbpw -D ${DATABASE_NAME:-'openeyes'} < sample/openeyes_sample_data.sql" \
        && echo "cleaning up..." \
        && rm -rf /sample

EXPOSE 80 3306 9515

ENTRYPOINT ["/init.sh"]
