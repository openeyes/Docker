FROM appertaopeneyes/base-apache as builder

ARG BUILD_BRANCH=develop
ARG BUILD_GITROOT=openeyes
ARG BUILD_SAMPLE=TRUE
ARG SSH_PRIVATE_KEY

ARG DEBIAN_FRONTEND=noninteractive

ENV TZ=Europe/London
ENV OE_MODE=BUILD
ENV OE_NO_DB=FALSE
ENV OE_GITROOT=$BUILD_GITROOT

WORKDIR /root/

	
# NOTE: We're not being too fussy about creating extra layers in this builder image, 
# as it is only a temporary image and will be removed in the next stage

# Install mariadb (it may be possible to remove this step with some tweaking to the install script)
RUN apt-get update && apt-get install -y mariadb-server mariadb-client
RUN service mysql start

# copy ssh key
RUN mkdir -p /root/.ssh \
    && echo "${SSH_PRIVATE_KEY}" > /root/.ssh/id_rsa && echo "IdentityFile ~/.ssh/id_rsa" > /root/.ssh/config \
    && chmod 600 /root/.ssh/id_rsa
RUN ssh -oStrictHostKeyChecking=no git@github.com -T || echo "host key set"

ARG CACHEBUSTER=$RANDOM
	# Use this to prevent build cache using an old version of source files

# Checkout openeyes
RUN git -C /var/www/html clone --depth=1 -b ${BUILD_BRANCH} git@github.com:${BUILD_GITROOT}/openeyes.git .

RUN rm /var/www/html/protected/scripts/git.conf 2&> /dev/null \
  && chmod 777 /var/www/html/protected/scripts/*.sh 

# Call the installer script  
RUN /var/www/html/protected/scripts/install-oe.sh --accept

RUN echo "cleaning up" \
	&& composer clearcache --working-dir=/var/www/html \
	&& npm cache clean --prefix /var/www/html/ --force 


# We could delete all git files before moving if needed, but left in for now
# RUN find /var/www/html/ -name '.git*' -exec rm -rf {} +

############ FINAL IMAGE #############

FROM appertaopeneyes/base-apache

ARG BUILD_FINAL_OE_MODE=DEV
ARG BUILD_NO_DB=FALSE
	# By default we expect an external database container to be used
	# Set this arg to false to install mariadb inside the container
ARG BUILD_EXTRA_PACKAGES=""
  # Add additional apt packages
ARG DEBIAN_FRONTEND=noninteractive

ENV TZ=Europe/London
ENV OE_MODE=$BUILD_FINAL_OE_MODE

WORKDIR /var/www/html
COPY --from=builder /var/www/html/ ./
COPY --from=builder /etc/profile.d/ /etc/profile.d/

RUN if [ "$BUILD_NO_DB" != "TRUE" ]; then apt-get update && apt-get install -y mariadb-server mariadb-client; fi \
  && service mysql start && oe-reset \
	&& echo "cleaning up" \
	&& apt-get autoremove -y \
	&& rm -rf /var/lib/apt/lists/* \
	&& composer clearcache --working-dir=/var/www/html \
	&& npm cache clean --prefix /var/www/html/ --force

RUN chgrp -R www-data .

# Add the init script
WORKDIR /
COPY init.sh init.sh
RUN chmod a+rx init.sh

EXPOSE 80 3306

VOLUME /var/www/html/protected/runtime/cache /var/www/html/protected/config/local /var/www/html/protected/protectedfiles

# ENTRYPOINT
CMD /init.sh
