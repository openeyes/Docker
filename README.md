# docker
Docker configuration etc.

Currently a minimum openeyes version of 3.1 is required to use this image. Tagged versions for older openeyes versions will be created in due course.

# DISCLAIMER
Maintained by @biskyt, with no official support from the AppertaFoundation.

**NO SUPPORT IS PROVIDED / IMPLIED**, and use is **AT YOUR OWN RISK**

# Running the container

**First boot may take some minutes**, but subsequent boots should take only a few seconds, particularly if you pay attention to the persistent storage section below.

The simplest way to run this container is with the "allin1" version. This can be run standalone. Alternatively, you can use a separate MySQL or MariaDB server.

e.g.: `docker run -it -p 80:80 -p 3306:3306 appertaopeneyes/web-allin1`


However, you will most likely want to provide some persistent storage and other environment variables. See below...

## Persistent storage for web files, configuration and database

This image will automatically setup the web files and database on first start. However, to avoid this lengthy process every time you recreate the container, it is strongly recommended to use persistent storage for:
* Web files and config : `/var/www/openeyes`
* Database (if using allin1 container version) : `/var/lib/mysql`

For persistent file storage, It is recommended that you either:
* Use docker docker volumes; or
* Bind to host folders

On Windows hosts, using docker volumes is _much_ faster for running the website, but host folders is quicker if working with IDE tools.

It is recommended to create the following volumes:
* `docker create volume oe-web`
* `docker volume create oe-db`

To e.g to run allin1 with persistent storage, use:

`docker run -it --name "openeyes" -v oe-web:/var/www/openeyes -v oe-db:/var/lib/mysql -p 80:80 -p 3306:3306 appertaopeneyes/web-allin1`

You can now destroy, recreate or upgrade the container at will, without losing any data or configuration

# Access to private repos using git
By default, this image will grab the latest openeyes files from the appertafoundation "Gold Master" openeyes repositories.

If you wish to use the latest development builds, you will need to:
1. Be a member of the openeyes github organisation
2. Provide your public SSH keys
3. Provide your github username and email Address

### SSH key
You can provide your SSH key in 3 different ways:
1. As a docker secret named SSH_PRIVATE_KEY
2. As an environment variables
3. By binding your ~/.ssh directory to /tmp/.host-ssh

Docker secrets are the recommended method. There is plenty of information on how to use secrets in the docker documentation (note that docker swarm and docker-compose support slightly different methods)

As an environment variable, you can add `-e SSH_PRIVATE_KEY=$(cat ~/.ssh/id_rsa)` to the run / create command.

As a mount, you can add `-v ~/.ssh:/tmp/.host-ssh` to the run / create commands.

**Note 1:** that the exact command will differ slightly between docker for windows / linux / macOS. See general docker documentation for more help.

**Note 2:** If mounting your host .ssh folder, you will need to ensure that the folder contains a `config` file, with an IdentityFile directive that points to your github SSH key


To pass in your github username and email, use the following environment variables:
``-e GIT_USER="<your username>" -e GIT_EMAIL="<Your@Github.Account.Email>"``

# Accessing the container's shell
To access the bash shell inside the container; with the container already running use:

`docker exec -it <container_name> bash`

# Accessing docker volumes on a [Windows] Host

If you wish to share back docker volumes to a [Windows] host. Use the following image:

`
docker run --rm -d -v /var/lib/docker/volumes:/docker_volumes -p 139:139 -p 445:445 -v /var/run/docker.sock:/var/run/docker.sock --net=host biskyt/volume-sharer`
This will make all volumes available via samba on the host \\\10.0.75.2 (which is the default docker for windows VM IP Address)

# docker-compose
An example compose file is provided in the [web folder](https://github.com/openeyes/Docker/tree/master/web). Note that this expects you to provide a .env file for some of the environment variables. E.g, Create a file names `.env` in the same folder as the compose file. Inside .env, add Environment varibales (one per line). E.g,
```
GIT_USER=<your github username>
```
When you run `docker-compose up` the contents of `.env` will be read and the variables inserted in the relevant places in the compose file.

The example compose file creates 3x containers:
* A MariaDB database container (on port 3306)
* A PHP5.6 version of the openeyes web container (on port 80)
* A PHP7.3 version of the openeyes container (on port 7777)

This demonstrates how 2 instances can connect to the same database and use the same code files. It also allows dual PHP version testing, while we migrate to PHP7.

# Adding key for encryption/decryption
The key to be used for encryption and decryption of the email account password needs to be stored in the key file under [web folder](https://github.com/openeyes/Docker/tree/master/web).

To generate a key having 64 characters in hex format, execute the following command in terminal -

`openssl rand -hex 32

In the above command, 32 indicates the number of random bytes to print. -hex prints those bytes in the hex format - 2 characters per byte, so 64 characters.

Copy the randomly generated key and store it in the key file, make sure to set the encoding of the file to UTF-8.
