# Portainer test/deploy environment
Use the provided compose file to create a new environemt which includes:
- Portainer web GUI for managing instances
- Traefik reverse proxy
- Automatic https certificates for each instance from letsencrypt
- Portainer template for standing-up openeyes instances
  - Go to App templates once logged in to Portainer

# Pre-requisites
- [Docker](https://docs.docker.com/v17.12/install/) and [Docker Compose](https://docs.docker.com/compose/install/)
- A private key with access to the OE GitHub repo (for the latest builds)

# Setup
1. Install/configure pre-requisites
2. Ensure that the DNS record for *.$DOMAINNAME matches the IP address of the server running this portainer setup
3. Ensure that the host is accessible on ports 80 and 443 (this is required for Let's Encrypt certificate creation)
4. Clone this repo to your host environment
5. Update the desired domain and email address in the `.env` file
6. (Recommended) Create a password for the Traefik dashboard
    1. Create a folder named `traefikshared` in the portainer directory
    2. Create a `.htpasswd` file under the `./traefikshared/` folder using the Apache [htpasswd](https://httpd.apache.org/docs/2.4/programs/htpasswd.html) command. E.g. `htpasswd .htpasswd my-user-name`
7. Start Portainer/Traefik using the command `docker-compose up -d` (the -d flag will start in detatched mode)
    * Note: If you need to view the logs for Traefik then use the command `docker-compose logs -tf --tail="50" traefik`
8. Portainer and Traefik should now be available!
    * Portainer will be available on http://localhost:9000 (and https://portainer.$DOMAINNAME)
    * Traefik dashboard will be available on http://localhost:8081 (and https://traefik.$DOMAINNAME)

# Important notes
- All new instances will be created at \<instance name>.\<$DOMAINNAME>
- You will need to set an admin password for Portainer at firt run
- The portainer templates will only be imported on first run. If you need to reset/refresh, you'll need to do so via the portainer HTTP API (see portainer documentation for more info)
- You may need to set the permissions on the `acme/acme.json` file to 600 - check Traefik logs to see if they need changing.
