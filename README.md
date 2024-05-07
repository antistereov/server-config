# Server Config

This README serves as a guide for setting up your own server with useful tools. The starting point is a usable server with root access. An operating system does not need to be installed yet.
This configuration is opinionated. Please check out the [Remark](#remark).

If your server does not have Docker installed, if you need help setting up DNS records or, if your server is even missing an OS, start [here](#prerequisites).

If Docker is already installed, and you only want to deploy the services, you can check out my preconfigured stacks of Docker containers. 
These containers include a Nextcloud instance, a Mailserver, monitoring solutions, a reverse proxy manager and some utilities.
You can run each stack individually. Just check out the corresponding section:

* [Nginx Proxy Manager](#nginx-proxy-manager)
* [Monitoring](#monitoring)
* [Nextcloud](#nextcloud)
* [Mailserver](#mailserver)

I also created a backup script that backs up all containers and Docker volumes.
You can use a cron job to run this script periodically.

* [Backup](#backup)

## Remark

This configuration is specific to my setup. You might need to skip some of these steps. 
I tried to add every source that I used to configure my server. Feel free to check these out too.

I'm using Cloudflare as my DNS and domain provider. For me, this makes the process of setting up proxies and DNS records as simple as possible.
If you are using another DNS provider, some configuration steps might be different from mine.

Two notes on Docker: 
* I like to use Docker volumes for persistent storage instead of local directories since these are easier to back up, and you cannot destroy your containers with user rights management. I strongly recommend you using Docker volumes as well. This would have saved me days trying to fix things when setting up my server for the first time.
* I use an external docker network to connect all services. This way, only port `80` and `443` get exposed. Routing is done by Nginx Proxy Manager. Everything else stays in the Docker network.

## Prerequisites

### Initializing Server

#### Installing Ubuntu

> My server is hosted by Hetzner. Therefore, the installation of Ubuntu on this machine is specific to Hetzner.

To install an operating system follow this doc: [Installimage](https://docs.hetzner.com/robot/dedicated-server/operating-systems/installimage/)

In short, in order to be able to access the server, you have to activate the rescue system first. 
Hetzner will show a password that can be used to access the server as user `root`.

> To be able to access the Rescue System you have to reboot the server.

```shell
ssh root@<server-ip>
```

Then you can run `installimage` to start the installation script.

#### Setting Up Ubuntu

1. Change root password:
    ```shell
    passwd
    ```
2. Create new user:
    ```shell
    adduser <username>
    ```
3. Granting sudo privileges 
    ```shell
    usermod -aG sudo <username>
    ```
4. Update the system:
    ```shell
    sudo apt update && sudo apt upgrade -y
    ```
5. *(You can skip this step if you don't like these tools.)* Install applications:
    ```shell
    sudo apt install nala fish neofetch 
    ```
6. Install docker by following this tutorial: [Installation methods](https://docs.docker.com/engine/install/ubuntu/#installation-methods)
7. Granting docker privileges
    ```shell
    groupadd docker
    usermod -aG docker <username>
    ```
8. Reboot the system and log in as `<username>`.
9. *(You can skip this step if you don't like fish.)* Change default shell to `fish`:
    ```shell
    chsh -s $(which fish)
    ```
   
### Changing SSH port

This configuration is based on the following sources:

* [How to Change the SSH Port in Linux](https://linuxize.com/post/how-to-change-ssh-port-in-linux/) on https://linuxize.com

> It is recommended to change your SSH port. By default, SSH listens on port 22. 
> Changing the default SSH port adds an extra layer of security to your server by reducing the risk of automated attacks.

Open the SSH configuration file /etc/ssh/sshd_config with your text editor:

```shell
sudo nano /etc/ssh/sshd_config
```

Search for the line starting with Port 22. In most cases, this line starts with a hash (#) character. 
Remove the hash # and enter the new SSH port number:

```text
Port <Port Number>
```

Be extra careful when modifying the SSH configuration file. An incorrect configuration may cause the SSH service to fail to start.

Once done, save the file and restart the SSH service to apply the changes:

```shell
sudo systemctl restart ssh
```

### Firewall Settings

This configuration is based on the following sources:

* [How to limit SSH (TCP port 22) connections with ufw on Ubuntu Linux](https://www.cyberciti.biz/faq/howto-limiting-ssh-connections-with-ufw-on-ubuntu-debian/) by Vivek Gite on https://www.cyberciti.biz
* [How to Set Up a Firewall with UFW on Ubuntu](https://www.digitalocean.com/community/tutorials/how-to-set-up-a-firewall-with-ufw-on-ubuntu) by Brian Boucheron and Jamon Camisso on https://www.digitalocean.com
 
Set up default policies:

```shell
sudo ufw default deny incoming
sudo ufw default allow outgoing
```

Allow SSH (make sure to use the port specified [here](#changing-ssh-port):

```shell
sudo ufw allow <SSH Port Number>/tcp comment 'SSH Port Rate Limit'
```

Allow http and https:

```shell
sudo ufw allow http https
```

> Docker doesn't obey these firewall settings and sets up its own settings in order to allow Docker to function as intended.

### Mounting Storage Box

> I use a [Storage Box](https://docs.hetzner.com/robot/storage-box/) provided by Hetzner to store backups of my Docker volumes and containers.

Follow this tutorial: [Access Storage Box via Samba/CIFS](https://docs.hetzner.com/robot/storage-box/access/access-samba-cifs)

Make sure to mount the storage box to `/backup` on the server and enable encryption. Add this line to `/etc/fstab`:

```text
//<username>.your-storagebox.de/backup /backup cifs seal,iocharset=utf8,rw,credentials=/etc/backup-credentials.txt,uid=<system account>,gid=<system group>,file_mode=0660,dir_mode=0770 0 0
```

Also create the file `/etc/backup-credentials.txt` with the following content:

```text
username=<username>
password=<password>
```

### Setting up Docker

Generate an SSH-key to be able to access the Server Config repository.

```shell
ssh-keygen -t ed25519 -C <email>
```

Add the newly generated SSH-key to your GitHub account: [GitHub Doc](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/adding-a-new-ssh-key-to-your-github-account#adding-a-new-ssh-key-to-your-account)

Clone repository:

```shell
git clone <repository-url>
```

Create the docker network:

```shell
docker network create proxy
```

Create a volume for SSL certificates:

```shell
docker volume create --name letsencrypt-data
```

### DNS, Proxy, Cloudflare

You can just follow this tutorial: https://www.youtube.com/watch?v=GarMdDTAZJo

This tutorial shows how to:

* configure DNS records
* set up a proxy
* generate your own SSL-certificates
* make your website accessible from the world wide web

For the impatient, here is a short overview:

* Set up a DNS record on your DNS provider's website. I'm using Cloudflare.
  * Type: A
  * Name: `npm.example.com` (This is the domain you want to access NPM from.)
  * Destination: your server's public IP
  * Proxied: `true`, since we want to use a reverse proxy later on
* Set up Nginx Proxy Manager following this section: [Setup](#setup). If you are able to access NPM at `<your public ip>:81`, you are good to go.
* Generate SSL certificates
  * in Nginx Proxy Manager go to SSL Certificates
  * click on *Add SSL certificate* and enter the following values:
    * Domain name: `*.example.com`, where `example.com` is the domain you registered. The `*` serves as a placeholder so any domain containing `example.com` can use this certificate
    * Use DNS challenge: `true` is recommended. If you use Cloudflare as DNS provider, just enter your Cloudflare API token. Click [here](https://developers.cloudflare.com/fundamentals/api/get-started/create-token/) to learn how to create one.
    * agree to the terms of services and you are set to go
* Set up Proxy Hosts
  * In NPM go to *Hosts* and click on *Proxy Hosts*. Here you can set up how your containers can be accessed from the internet. We will now create a proxy host for NPM. Other hosts can be created in the same way.
  * click on *New Proxy Host* and enter the following values:
    * Domain names: `npm.example.com` (The domain you just set up a DNS record for.)
    * Scheme: `http`
    * Forward Hostname: `nginx-proxy-manager` (This is the name of the Docker container inside the network)
    * Forward Port: `81` (This is the port that you can access the web interface from.)
    * choose *Block common exploits*
    * click on the SSL tab and choose the certificate we just generated (should be `*.example.com`)
    * choose *Force SSL*
  * Click save, and now you should be able to access NPM from `https://npm.example.com`. Congratulations!

If you want to add more proxy hosts, just repeat this whole process. You can scip accessing NPM via `<your public ip>:81` and access it directly via `https://npm.example.com`

## Nginx Proxy Manager

[Nginx Proxy Manager](https://nginxproxymanager.com/), or NPM for short, is a tool that simplifies the management of reverse proxies, 
allowing users to easily configure and deploy routing rules for their web applications. 
It provides a graphical interface for managing Nginx configurations, 
making it accessible for users without extensive server administration experience.

Follow the [official guide](https://nginxproxymanager.com/guide/#quick-setup) to set up Nginx Proxy Manager. 
The setup is also covered in the subsection [DNS, Cloudflare, Proxy](#dns-cloudflare-proxy).

> Make sure to add SSL certificates for your domain. The tutorial in the subsection [DNS, Cloudflare, Proxy](#dns-cloudflare-proxy) covers the process.

Nginx Proxy Manager exposes the following ports:

* `80`: http
* `81`: Nginx Proxy Manager
* `443`: https

### Setup

#### Prerequisites

There is an `.env`-file in the `npm` directory. Please enter your domain, npm should be accessible at.
You can set up a DNS record for `npm.example.com` for example. Use this domain here.

#### Starting the container

Inside the `npm` directory do:

```shell
docker compose up -d
```

If you get any errors, make sure you followed every step of [Setting up Docker](#setting-up-docker) correctly.

If everything went well, you can access Nginx Proxy Manager at `<your public ip-address>:81`.
You can find how to set up proxy hosts here: [DNS, Proxy, Cloudflare](#dns-proxy-cloudflare).

### SSL Certificates

Nginx Proxy Manger automatically generates certificates based on your configuration.
These certificates will be saved in the external volume `letsencrypt-data`.
If you need these certificates in another container just mount this volume to `/etc/letsencrypt` inside the container.

## Monitoring

This configuration is based on the following sources:

* [How to Set Up Grafana and Prometheus Using Docker ](https://dev.to/chafroudtarek/part-1-how-to-set-up-grafana-and-prometheus-using-docker-i47) by Chafroud Tarek on https://dev.to

The `monitoring`-stack contains the following services:

* [Portainer](https://www.portainer.io/): Container management tool
* [Grafana](https://grafana.com/oss/grafana/): Data visualization
* [Prometheus](https://prometheus.io/docs/introduction/overview/): Systems monitoring and alerting toolkit
* [Cadvisor](https://github.com/google/cadvisor): Container monitoring
* [Node Exporter](https://github.com/prometheus/node_exporter): Prometheus exporter for machine metrics

### Setup

In case you have problems following the DNS and NPM setup, take a look here: [DNS, Proxy, Cloudflare](#dns-proxy-cloudflare).

#### Prerequisites

Add the missing fields in `monitoring/.env`. 
`GRAFANA_DOMAIN` is the domain you want to access Grafana from, e.g. `grafana.example.com`.

#### DNS

Add an A-record for Grafana, Nginx Proxy Manager and Portainer.

#### Nginx Proxy Manager

Add a Proxy Host for:

* Portainer: 
  * Destination: `http://portainer:9000`
  * Block common exploits: `true`
  * SSL: make sure to use [your SSL certificate](#dns-cloudflare-proxy)
  * SSL/Force SSL: `true`
* Grafana:
  * Destination: `http://grafana:3000`
  * Block common exploits: `true`
  * SSL: make sure to use [your SSL certificate](#dns-cloudflare-proxy)
  * SSL/Force SSL: `true`
* Nginx Proxy Manager:
  * Destination: `http://nginx-proxy-manager:81`
  * Block common exploits: `true`
  * SSL: make sure to use [your SSL certificate](#dns-cloudflare-proxy)
  * SSL/Force SSL: `true`
* Roundcube:
  * Destination: `http://roundcube:80`
  * Block common exploits: `true`
  * SSL: make sure to use [your SSL certificate](#dns-cloudflare-proxy)
  * SSL/Force SSL: `true`

#### Deployment

You can now move to the `monitoring` directory and start all the services using:

```shell
docker compose up -d
```

#### Grafana

Add the following data source:

* Prometheus
  * Name: `prometheus`
  * Source: `http://prometheus:9090`

Add the following dashboards and connect them to the prometheus data source:

* [Node Exporter Full](https://grafana.com/grafana/dashboards/1860-node-exporter-full/)
* [Docker-cAdvisor](https://grafana.com/grafana/dashboards/13946-docker-cadvisor/)

## Nextcloud

This configuration is based on the following sources: 

* [How to Install Nextcloud with Docker: A Step-by-Step Guide](https://linuxiac.com/how-to-install-nextcloud-with-docker-compose/) - by Bobby Borisov on https://linuxiac.com
* [Nginx Configuration](https://docs.nextcloud.com/server/28/admin_manual/installation/nginx.html) - Nextcloud Docs
* [Reverse Proxy Configuration](https://docs.nextcloud.com/server/28/admin_manual/configuration_server/reverse_proxy_configuration.html) - Nextcloud Docs
* [Background Jobs](https://docs.nextcloud.com/server/28/admin_manual/configuration_server/background_jobs_configuration.html) - Nextcloud Docs
* [HowTo: Add a new trusted domain](https://help.nextcloud.com/t/howto-add-a-new-trusted-domain/26) - Nextcloud Help
* [Your installation has no default phone region set](https://help.nextcloud.com/t/your-installation-has-no-default-phone-region-set/153632) - Nextcloud Help
* [Can't get Reverse Proxy Header / https set up right on Nextcloud through Docker and Nginx Proxy Manager](https://stackoverflow.com/questions/70856799/cant-get-reverse-proxy-header-https-set-up-right-on-nextcloud-through-docker) - StackOverflow

### Prerequisites

Edit file `.env` in `nextcloud` directory. You need to add the following variables in the `.env` file

* `NEXTCLOUD_TRUSTED_DOMAINS`: the domains you want to access your Nextcloud from, e.g. `nextcloud.example.com`
* `OVERWRITEHOST`: the main domain you want to access your Nextcloud from, e.g. `nextcloud.example.com`
* `MYSQL_ROOT_PASSWORD`: Insert a strong password, you don't need to use it anytime. This will be used inside the container only. You can use a password generator.
* `MYSQL_PASSWORD`: insert a different strong password

### Installation

Go to the `nextcloud` directory and run the stack:

```shell
docker compose up -d
```

### Configuration

In case you have problems following the DNS and NPM setup, take a look here: [DNS, Proxy, Cloudflare](#dns-proxy-cloudflare).

#### DNS

Add an A-record for your Nextcloud domain.

#### Nginx Proxy Manger

* Destination: `http://nextcloud-app:80`
* Cache Assets: `true `
* Block common exploits: `true`
* Web socket support: `true`
* SSL: make sure to use [your SSL certificate](#dns-cloudflare-proxy)
* SSL/Force SSL: `true`
* SSL/HTTP/2-support: `true`
* SSL/HSTS enabled: `true`
* SSL/HSTS subdomains: `true`
* Custom Nginx Configuration:
  ```text
  client_body_buffer_size 512k;
  proxy_read_timeout 86400s;
  client_max_body_size 0;
  
  # Make a regex exception for `/.well-known` so that clients can still
  # access it despite the existence of the regex rule
  # `location ~ /(\.|autotest|...)` which would otherwise handle requests
  # for `/.well-known`.
  location ^~ /.well-known {
      # The rules in this block are an adaptation of the rules
      # in `.htaccess` that concern `/.well-known`.
  
      location = /.well-known/carddav { return 301 /remote.php/dav/; }
      location = /.well-known/caldav  { return 301 /remote.php/dav/; }
  
      location /.well-known/acme-challenge    { try_files $uri $uri/ =404; }
      location /.well-known/pki-validation    { try_files $uri $uri/ =404; }
  
      # Let Nextcloud's API for `/.well-known` URIs handle all other
      # requests by passing them to the front-end controller.
      return 301 /index.php$request_uri;
  }
  ```
  
#### Nextcloud Config

> After starting the containers and initial setup of Nextcloud you may see warnings regarding the Maintenance Window and default phone regions.
> Setting the following values should resolve these warnings.

Add these lines to `nextcloud-data/config/config.php`:
```php
  'logtimezone' => 'Europe/Berlin',
  'default_locale' => 'en_DE',
  'default_phone_region' => 'DE',
  'maintenance_window_start' => 1,
```

Alternatively, you can set these values using occ: [occ config commands](https://docs.nextcloud.com/server/stable/admin_manual/configuration_server/occ_command.html#config-commands)

## Mailserver

This section is based on the following sources:

* [Setting up DNS records - YouTube](https://www.youtube.com/watch?v=o66UFsodUYo)
* [Official documentation for Docker Mailserver](https://docker-mailserver.github.io/docker-mailserver/latest/)

I'm using [Docker Mailserver](https://github.com/docker-mailserver/docker-mailserver) as Mailserver and [Roundcube](https://roundcube.net/) as Webmail Client.

> You need to change `hostname`, `domainname` in `docker-compose.yml` and `OVERRIDE_HOSTNAME` in `mailserver.env` to your domain.

Follow the official documentation to set up mailserver: https://docker-mailserver.github.io/docker-mailserver/latest/

### SSL

It is highly recommended that you use SSL encryption for your mail.
Since Nginx Proxy Manager already generates certificates for us, we can just use those. 
SSL certificates are generated by Nginx Proxy Manager to the external volume `letsencrypt-data`.
For some reason, Nginx Proxy Manager saves the certificates in the directory `/etc/letsencrypt/live/npm-<number>`.
Therefore, the certificate location must be updated manually.
You need to check with folder contains the right certificates and change the environment variables in the docker compose file accordingly.

### Setup

Enter the missing environment variables in `mail/.env`.
Both `DOMAIN_NAME` and `OVERRIDE_HOSTNAME` should be your mailserver's domain, e.g. `mail.example.com`
`ROUNDCUBE_DOMAIN` is the domain you want to access you webmail client from, e.g. `roundcube.example.com`

`SSL_CERT_PATH` is the path of your `fullchain.pem` and `SSL_KEY_PATH` is the path of your `privkey.pem` in your letsencrypt volume.
The directory should look like `/etc/letsencrypt/live/npm-2`. 
So your key's location is `/etc/letsencrypt/live/npm-2/privkey.pem` and your cert's location is `/etc/letsencrypt/live/npm-2/fullchaim.pem`.

If you don't know where to find them, just do

```shell
docker exec nginx-proxy-mananer bash -c "ll /etc/letsencrypt/live"
```

This should give you all possible directories. If you have multiple folders, visit your NPM interface, go to SSL Certificates and hover over the three dots next to the right certificate.
This is the correct number.

Now move to the `mail` directory and start the service for the first time:

```shell
docker compose up -d
```

There are still some things to do now:

Add a postmaster alias:

```shell
docker exec -ti mailserver setup alias add postmaster@<your domain> admin@<your domain>
```

Create a user:

```shell
docker exec -it mailserver setup email add admin@<your domain>
```

Generate DKIM-Key:

```shell
docker exec -it mailserver setup config dkim keysize 1024
```

I had some issues earlier when using the default keysize of 2048.
You need the value later to set up DNS-records.

The value is saved inside the container.
Just display the contents of the file using:

```shell
docker exec —it mailserver bash —c "cat rsa-1024-mail-<your domain>.public.txtt"
```

Now restart everything using:

```shell
docker compose down
docker compose up -d
```

And you are good to go. Check the logs using `docker logs -f mailserver` to see if there are any issues.

### DNS

Setting up your DNS records correctly can be tricky. If you need more advice, take a look at this guide: https://www.cloudflare.com/learning/dns/dns-records/

In my case, adding these records worked:

```text
MX  example.com         mail.example.com
A   mail.example.com    <your ip-address>
TXT _dmarc              v=DMARC1; p=reject; sp=reject; fo=1; ri=86400
TXT example.com         v=spf1 mx -all
TXT mail._domainkey     v=DKIM1; h=sha256; k=rsa; p=ABC124...
```

The value in `mail._domainkey` should be the value you just generated.

### Roundcube

Of course, you would want to access your emails. For this purpose we have Roundcube. This is an open source webmail client.
To use it, just set up a DNS record and a proxy host for Roundcube ([DNS, Proxy, Cloudflare](#dns-proxy-cloudflare)) and you can use Roundcube to read and compose emails.

Use `user@example.com` as username. You can create new users using:

```shell
docker exec -it mailserver setup email add <user>@<your domain>
```

### Connect to other clients

You can connect access the mailbox via roundcube or configure your e-mail client of choice:

* Incoming server: 
  * Server type: IMAP Mail Server
  * Server name: `mail.example.com` 
  * Port: `143`
  * Connection security: `STARTTLS`
  * User name: `user@example.com`
  * Authentication method: Normal password
* Outgoing server:
  * Server name: `mail.example.com`
  * Port: `587`
  * Connection security: `STARTTLS`
  * Authentication method: Normal password
  * User name: `user@example.com`

## Backup

The backup script is located in `backup`.

> This script is specific to my system. You need to change the variable `backup-parent-dir`.

To schedule a cron job to run your script every day at 4 AM, you can use the `crontab` command.
First, open the crontab file for editing with the command `crontab -e`
Then, add the following line to the file:

```bash
0 4 * * * bash -c <backup script location> >> /var/log/backup.log 2>&1
```

> Make sure to set the ownership of the logfile to the user.

This line tells cron to run your script at 4 AM (0 minutes past the 4th hour) every day.
Make sure your script has execute permissions. You can add them with the command `chmod +x <backup script location>`.
Save and close the file. The cron job is now scheduled and will run your script every day at 4 AM.
