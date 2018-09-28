FROM appertaopeneyes/base-apache as builder

ARG BUILD_BRANCH=master
ARG BUILD_GITROOT=openeyes
ARG BUILD_SAMPLE=TRUE
ARG SSH_PRIVATE_KEY

ARG DEBIAN_FRONTEND=noninteractive

ENV TZ=Europe/London
ENV OE_MODE=BUILD
ENV OE_NO_DB=TRUE
	# db never needed for building
ENV OE_GITROOT=$BUILD_GITROOT

WORKDIR /root/

# copy ssh key
RUN mkdir -p /root/.ssh \
    && echo "${SSH_PRIVATE_KEY}" > /root/.ssh/id_rsa && echo "IdentityFile ~/.ssh/id_rsa" > /root/.ssh/config \
    && chmod 600 /root/.ssh/id_rsa

ARG CACHEBUSTER=$RANDOM
	# Use this to prevent build cache using an old version of source files

# Checkout openeyes
RUN ssh -oStrictHostKeyChecking=no git@github.com -T || echo "host key set"

RUN git clone --depth=1 -b ${BUILD_BRANCH} git@github.com:${BUILD_GITROOT}/openeyes.git openeyes
RUN rm /root/openeyes/protected/scripts/git.conf 2&> /dev/null
RUN git -C /root/openeyes submodule update --init

# Checkout eyedraw
RUN cd /root/openeyes/protected/modules && git clone --depth=1 -b ${BUILD_BRANCH} git@github.com:${BUILD_GITROOT}/eyedraw.git eyedraw 2&> /dev/null
RUN if [ ! $? = 0 ]; then echo "no eyedraw branch $BUILD_BRANCH exists, switching to develop" && git clone --depth=1 -b develop git@github.com:${BUILD_GITROOT}/eyedraw.git eyedraw; fi

# Checkout sample data
RUN if [ "$BUILD_SAMPLE" = "TRUE" ]; then git clone --depth=1 -b ${BUILD_BRANCH} git@github.com:${BUILD_GITROOT}/sample.git sample 2&> /dev/null; fi
RUN if [ ! $? = 0 ]; then echo "no sample branch $BUILD_BRANCH exists, switching to develop" && git clone --depth=1 -b develop git@github.com:${BUILD_GITROOT}/sample.git sample 2&> /dev/null ; fi
RUN if [ ! $? = 0 ]; then echo "no sample branch develop exists, switching to master" && git clone --depth=1 -b master git@github.com:${BUILD_GITROOT}/sample.git sample; fi

# Install composer and npm dependencies
RUN echo "Installing composer dependencies" \
  && composer install --working-dir=/root/openeyes/ --no-plugins --no-scripts --no-dev \
  && composer clearcache \
  && echo "Installing npm dependencies" \
	&& npm install --prefix /root/openeyes/ --only=production \
  && npm cache clean --force

# Delete all git and build assets before copy
RUN find . -name '.git*' -exec rm -rf {} +

############ FINAL IMAGE #############

FROM appertaopeneyes/base-apache

ARG BUILD_NO_DB=TRUE
	# By default we expect an external database container to be used
	# Set this arg to false to install mariadb inside the container
ARG BUILD_EXTRA_PACKAGES=""
  # Add additional apt packages
ARG DEBIAN_FRONTEND=noninteractive

ENV TZ=Europe/London
ENV OE_MODE=LIVE

WORKDIR /var/www/html
COPY --from=builder /root/openeyes/ ./

RUN if [ "$BUILD_NO_DB" != "TRUE" ]; then apt-get update && apt-get install -y mariadb-server mariadb-client; fi \
        && apt-get autoremove -y \
        && rm -rf /var/lib/apt/lists/*

RUN chgrp -R www-data .

# Add the init script
WORKDIR /
COPY init.sh init.sh
RUN chmod a+rx init.sh

EXPOSE 80 3306

VOLUME /cache /config /logs /protectedfiles

# ENTRYPOINT
CMD /init.sh
