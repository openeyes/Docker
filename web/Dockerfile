FROM ubuntu:bionic as builder

#FROM php:5.6 as builder

ARG BUILD_BRANCH=master
ARG BUILD_GITROOT=openeyes
ARG SSH_PRIVATE_KEY

ARG DEBIAN_FRONTEND=noninteractive

ENV TZ=Europe/London
ENV OE_MODE=BUILD
ENV OE_NO_DB=TRUE
	# db never needed for building

WORKDIR /root/

RUN apt-get update && apt-get install -y sudo git-core tzdata \
    && ln -sf /usr/share/zoneinfo/${TZ:-Europe/London} /etc/localtime

# dialog apt-utils
RUN mkdir -p /root/.ssh
#RUN echo "IdentityFile ~/.ssh/id_rsa" > /root/.ssh/config \
RUN echo "${SSH_PRIVATE_KEY}" > /root/.ssh/id_rsa && echo "IdentityFile ~/.ssh/id_rsa" > /root/.ssh/config \
    && chmod 600 /root/.ssh/id_rsa

ARG CACHEBUSTER=$RANDOM
	# Use this to prevent build cache using an old version of source files

RUN ssh -oStrictHostKeyChecking=no git@github.com -T \
	|| git clone --depth=1 -b ${BUILD_BRANCH} git@github.com:${BUILD_GITROOT}/openeyes.git openeyes  
	RUN sudo bash openeyes/protected/scripts/install-system.sh 
	RUN sudo bash openeyes/protected/scripts/install-oe.sh --accept


# Delete all git and build assets before copy
RUN find . -name '.git*' -exec rm -rf {} +

############ FINAL IMAGE #############

FROM ubuntu:bionic

#FROM php:5.6-apache

ARG BUILD_MODE=LIVE
	# Can be LIVE or DEV
ARG BUILD_NO_DB=TRUE
	# By default we expect an external database container to be used
	# Set this arg to false to install mariadb inside the container
ARG EXTRA_PACKAGES=""

ENV $OE_INSTALL_EXTRA_PACKAGES=$EXTRA_PACKAGES

ARG DEBIAN_FRONTEND=noninteractive
ENV TZ=Europe/London
ENV OE_MODE=${BUILD_MODE}
ENV OE_NO_DB=${BUILD_NO_DB}
WORKDIR /var/www/html
COPY --from=builder /root/openeyes/* .
RUN bash ./protected/scripts/install-system.sh \ 
	&& bash ./protected/scripts/install-oe.sh --accept --no-checkout \
	&& apt clean

EXPOSE 80

ENTRYPOINT apachectl -DFOREGROUND
