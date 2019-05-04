## Builds an OpenEyes DicomProcessor service instance.

ARG OS_VERSION=bionic

FROM ubuntu:$OS_VERSION

ARG OS_VERSION
ARG BUILD_BRANCH="develop"
ARG BUILD_CLONEROOT="https://github.com/"
ARG BUILD_GIT_ORG="openeyes"
ARG BUILD_PROJROOT="/dicomprocessor"
ARG DEBIAN_FRONTEND=noninteractive
ARG TIMEZONE="Europe/London"

ENV BUILD_BRANCH=$BUILD_BRANCH
ENV PROJROOT="$BUILD_PROJROOT"
ENV BUILD_CLONEROOT=$BUILD_CLONEROOT
ENV BUILD_GIT_ORG=$BUILD_GIT_ORG

## Used by some scripts to determine if they are runing in a container
ENV DOCKER_CONTAINER="TRUE"

ENV GIT_ORG=""
ENV GIT_USER=""
ENV GIT_EMAIL=""
ENV SSH_PRIVATE_KEY=""
# If TRACK_NEW_GIT_COMMITS=true, then the container will run oe-update every 30 minutes as a cron job
ENV TRACK_NEW_GIT_COMMITS="FALSE"
ENV TZ=$TIMEZONE

## Database connection credentials:
## It is STRONGLY recommended to change the password for production environments
## It is STRONGLY recommended to use docker secrets for DATABASE_PASS, rather than env variables
## defaults are db; openeyes; 3306; openeyes; openeyes
ENV DATABASE_HOST="db"
ENV DATABASE_NAME="openeyes"
ENV DATABASE_PASS="openeyes"
ENV DATABASE_PORT="3306"
ENV DATABASE_USER="openeyes"

ENV PROCESSOR_QUEUE_NAME="dicom_queue"
ENV PROCESSOR_SHUTDOWN_AFTER=0


# Set timezone, add common packes, apt clean at the end to minimise layer size
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone \
 && apt-get update && apt-get install --no-install-recommends -y \
    git-core \
    mariadb-client \
    maven \
    nano \
    ssh-client \
    sudo \
  && apt-get autoremove -y \
  && rm -rf /var/lib/apt/lists/* \
  && apt-get clean -y \
  && rm -rf /var/www/html/* \
  && git config --global core.fileMode false

  # set up folders
  RUN cd / && mkdir -p $PROJROOT \
      && echo cloning "-b ${BUILD_BRANCH} $BUILD_CLONEROOT${BUILD_GIT_ORG}/DicomProcessor.git" \
      && git clone -b ${BUILD_BRANCH} $BUILD_CLONEROOT${BUILD_GIT_ORG}/DicomProcessor.git $PROJROOT \
      && cd $PROJROOT \
      && mvn package

  # Add the init script
  COPY init.sh /init.sh
  RUN chmod a+rx /init.sh

  ENTRYPOINT /init.sh
