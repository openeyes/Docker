#!/bin/bash


# Add keys
source sources/keys

for newkey in ${gpgkeys[@]}; do
    apt-key adv --keyserver keyserver.ubuntu.com --recv-keys $newkey
done	


# Expand sources list to sources.d
touch /etc/apt/sources.list.d/openeyes-dependencies.list
sed "s|\$OS_VERSION|$OS_VERSION|" sources/sources | tee /etc/apt/sources.list.d/openeyes-dependencies.list
chmod 755 /etc/apt/sources.list.d/openeyes-dependencies.list

# DO NOT apt-get update here or you risk creating a new layer - call with apt-get install RUN statement
