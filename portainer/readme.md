# Portainer test/deploy environment
Use the provided compose file to create a new environemt which includes:
- Portainer web GUI for managing instances
- Traefik reverse proxy
- Automatic https certificates for each instance from letsencrypt
- Portainer template for standing-up openeyes instances
  - Go to App templates once logged in to Portainer

# Important notes
- Edit your domain and email address in the .env file
- All new instances will be created at \<instance name>.\<$DOMAINNAME>
  - You must ensure that the DNS record for *.$DOMAINNAME matches the IP address of the server running this portainer setup.
- You will need to set an admin password at firt run
- Portainer will be available on http://localhost:9000 (and https://portainer.$DOMAINNAME)
- Traefik dashboard will be available on http://localhost:8081 (and https://traefik.$DOMAINNAME)
  - To set an http password for the Traefik dashboard. Add an .htaccess file to the `./traefikShared/` folder
- The templates will only be imported on first run. If you need to reset/refresh, you'll need to do so via the portainer HTTP API (see portainer documentation for more info)