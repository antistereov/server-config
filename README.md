# Server Config

This README serves as a guide for setting up your own server with useful tools. The starting point is a server with root access. An operating system does not need to be installed yet.

These tools are included:

* **VPN Server:** [Wireguard](https://github.com/linuxserver/docker-wireguard)
* **Reverse Proxy:** [Nginx Proxy Manager](https://nginxproxymanager.com/)
* **Monitoring:** [Grafana](https://grafana.com/) to visualize data from [Prometheus](https://prometheus.io/docs/introduction/overview/) using system metrics from [Node Exporter](https://github.com/prometheus/node_exporter) and docker metrics from [cAdvisor](https://github.com/google/cadvisor)
* **Cloud:** [Nextcloud](https://nextcloud.com/)
* **Mail:** [Docker Mailserver](https://github.com/docker-mailserver/docker-mailserver) as mailserver and [Roundcube](https://roundcube.net/) as webmail client
* **Home Automation:** [Home Assistant](https://www.home-assistant.io/)
* **Backup:** Backing up all containers and volumes using a shell script.

If your server does not have Docker installed, if you need help setting up DNS records or, if your server is even missing an OS, start [here](#prerequisites).

If Docker is already installed, and you only want to deploy the services, you can check out my preconfigured stacks of Docker containers. Here's a guide on how to install the services: [Installation](#installation). 
You can run each stack individually. Just check out the corresponding section:

* [VPN](#vpn)
* [Nginx Proxy Manager](#nginx-proxy-manager)
* [Monitoring](#monitoring)
* [Nextcloud](#nextcloud)
* [Mail](#mail)
* [Home Assistant](#home-assistant)

I also created a backup script that backs up all containers and Docker volumes.
You can use a cron job to run this script periodically.

* [Backup](#backup)

## Remark

This configuration is specific to my setup. You might need to skip some of these steps. 
I tried to add every source that I used to configure my server. Feel free to check these out too.

I'm using Cloudflare as my DNS and domain provider. For me, this makes the process of setting up proxies and DNS records as simple as possible.
If you are using another DNS provider, some configuration steps might be different from mine.

Two notes on Docker: 
* I like to use Docker volumes for persistent storage instead of local directories since these are easier to back up, and you cannot destroy your containers with user rights management.
  I strongly recommend you using Docker volumes as well. This would have saved me days trying to fix things when setting up my server for the first time.
* I use an external docker network to connect all services. This way, only port `80` and `443` get exposed. Routing is done by Nginx Proxy Manager.
  Everything else stays in the Docker network.

## Installation

First, you need to clone this repository:

```shell
git clone https://github.com/antistereov/server-config.git
```

Now there are still a few things you need to do before you can start:

* Please consider [changing your SSH port](#changing-ssh-port) and [setting up a firewall](#firewall-settings).
* Make sure Docker is installed and correctly set up, more information here: [Setting up Docker](#setting-up-docker).
* Set up [DNS records and a proxy](#dns-proxy-cloudflare).

If you want to deploy one of the Docker container stacks, first take a look at the respective section in this README and make sure everything is set (e.g. all the environment variables). 
Once you completed the setup just move to respective directory and do:

```shell
docker compose up -d
```

**Note:** Backup is no stack but a shell script. Check out [Backup](#backup) for more information on how to set it up.

## Update

To update the containers of a stack just move to the respective directory and run:

```shell
docker compose pull
```

This pulls the latest images of your containers.
To update the containers, you need to restart them:

```shell
docker compose down
docker compose up -d
```

## Prerequisites

### Initializing Server

#### Installing Ubuntu

My server is hosted by Hetzner. Therefore, the installation of Ubuntu on this machine is specific to Hetzner.
To install an operating system follow this doc: [Installimage](https://docs.hetzner.com/robot/dedicated-server/operating-systems/installimage/)

In short, in order to be able to access the server, you have to activate the rescue system first. 
Hetzner will show a password that can be used to access the server as user `root`.

To be able to access the Rescue System you have to reboot the server.

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
    adduser username
    ```
3. Granting sudo privileges 
    ```shell
    usermod -aG sudo username
    ```
4. Update the system:
    ```shell
    sudo apt update && sudo apt upgrade -y
    ```
5. Install `homebrew` (my preferred package manager, more information: [Homebrew](https://brew.sh/)
   ```shel
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   # Add homebrew to path
   fish_add_path /home/linuxbrew/.linuxbrew/bin
   ```
6. Install fish using `homebrew` (my preferred shell)
   ```shell
   brew install fish
   # Add fish to shells
   echo $(which fish) | sudo tee -a /etc/shells
   ```
   If you don't want to use `homebrew` or if you are on an ARM device, you can install fish using:
   ```shell
   sudo apt-add-repository ppa:fish-shell/release-3
   sudo apt update
   sudo apt install fish
   ```
7. Make `fish` the default shell:
   ```shell
   chsh -s $(which fish)
   ```
   Restart the terminal. `fish` should now be the default shell.
8. Install useful tools:
    ```shell
    brew install zoxide fzf bat fd fisher
    ```
    If you don't want to use `homebrew` or if you are on an ARM device, you need to install these tools using apt:

    ```shell
    sudo apt install zoxide fzf bat fd-find
    # Install fisher
    curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher install jorgebucaran/fisher
    # Add alias for bat
    alias --save bat=batcat
    ```
    
 9. For these tools to work, you need to append the following lines to `~/.config/fish/config.fish`:
    ```text
    # Enable zoxide
    zoxide init fish | source
    ```
10. Check out this repository to install fish plugins: [awsm.fish](https://github.com/jorgebucaran/awsm.fish)
    I like to use these:
    ```shell
    fisher install jethrokuan/z PatrickF1/fzf.fish IlanCosman/tide@v6
    ```
11. Create useful aliases:
    ```shell
    alias --save dc="docker compose"
    alias --save dl="docker logs"
    alias --save de="docker exec"
    alias --save dps="docker ps --format '{{.Names}}\t{{.Status}}'"
    ```
12. If you want to use private Git repositories, you need to generate an SSH-key to be able to access the Server Config repository.
    ```shell
    ssh-keygen -t ed25519 -C your@email.com
    ```
    and add the newly generated SSH-key to your GitHub account: [GitHub Doc](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/adding-a-new-ssh-key-to-your-github-account#adding-a-new-ssh-key-to-your-account).
13. Setting your Git username and mail for every repository on your computer:
   ```shell
   git config --global user.name "Mona Lisa"
   git config --global user.email "YOUR_EMAIL"
   ```
       
### Changing SSH port

This configuration is based on the following sources:

* [How to Change the SSH Port in Linux](https://linuxize.com/post/how-to-change-ssh-port-in-linux/) on https://linuxize.com

It is recommended to change your SSH port. By default, SSH listens on port 22. 
Changing the default SSH port adds an extra layer of security to your server by reducing the risk of automated attacks.

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

#### Enable Key-Based Authentication

You might also consider enabling key-based authentication to provide an extra layer of security. Here is a detailed guide on how to do just that: [How To Configure SSH Key-Based Authentication on a Linux Server](https://www.digitalocean.com/community/tutorials/how-to-configure-ssh-key-based-authentication-on-a-linux-server)

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
sudo ufw limit <SSH Port Number>/tcp comment 'SSH Port Rate Limit'
```

Allow http and https:

```shell
sudo ufw allow http
sudo ufw allow https
```

**Note:** Docker doesn't obey these firewall settings and sets up its own settings in order to allow Docker to function as intended.

### Mounting Storage Box

I use a [Storage Box](https://docs.hetzner.com/robot/storage-box/) provided by Hetzner to store backups of my Docker volumes and containers.
Make sure that Samba/CIFS and external reachablitiy is enabled for your storage box.

Install dependencies:

```shell
sudo apt install cifs-utils
```

Make sure to mount the storage box to `/backup` on the server and enable encryption. Add this line to `/etc/fstab`:

```text
//<username>.your-storagebox.de/backup /backup cifs seal,iocharset=utf8,rw,credentials=/etc/backup-credentials.txt,uid=<system account>,gid=<system group>,file_mode=0660,dir_mode=0770 0 0
```

Also create the file `/etc/backup-credentials.txt` with the following content:

```text
username=<username>
password=<password>
```

For further information, take a look at Hetzner's documentation: [Access Storage Box via Samba/CIFS](https://docs.hetzner.com/robot/storage-box/access/access-samba-cifs)

### Setting up Docker

Install Docker (more information here: [Installation methods](https://docs.docker.com/engine/install/ubuntu/#installation-methods)):

```shell
curl -sSL https://get.docker.com | sh
```

Granting docker privileges:

```shell
groupadd docker
usermod -aG docker <username>
```

Create the docker network:

```shell
docker network create --subnet=10.0.0.0/24 default_network
```

Create a volume for SSL certificates:

```shell
docker volume create --name letsencrypt_data
```

### DNS, Proxy, Cloudflare

You can just follow this tutorial: https://www.youtube.com/watch?v=GarMdDTAZJo. This tutorial shows how to:

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
* Set up Nginx Proxy Manager following this section: [Setup](#setup). If you are able to access NPM at http://10.0.0.5:81 through your [VPN](#vpn), you are good to go.
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

Keep in mind that this was just an example. Making Nginx Proxy Manager accessible from the internet might be a security risk.
If you want to add more proxy hosts, just repeat this whole process. 
You can access NPM via http://10.0.0.5:81 using your [VPN](#vpn).

## VPN

This script sets up a VPN server. This is required to access the Nginx Proxy Manager and other tools.
These won't be exposed to the world wide web for security reasons.

### Prerequisites

The only thing you need to do is adding your server URL to the `.env`-file.
This can either be a fqdn or the public IP address of your server.

### Connect to VPN

The container automatically generates a configuration file that you can access using this command:

```shell
docker exec homeassistant bash -c "cat /config/peer1/peer1.conf"
```

On your device create a new file `wg0.conf` and paste the contents of `peer1.conf`. 
Install the [VPN client](https://www.wireguard.com/install/) on your device and connect to the VPN by adding `wg0.conf` to the client.

### Access containers through VPN

You can now access the following containers using the specified address:

* Nginx Proxy Manager: http://10.0.0.5:81
* Grafana: http://10.0.0.0.9:3000
* Portainer: http://10.0.0.11:9000
* Nextcloud: http://10.0.0.13:80
* Roundcube: http://10.0.0.15:80
* Home Assistant: http://10.0.0.16:8123

## Nginx Proxy Manager

[Nginx Proxy Manager](https://nginxproxymanager.com/), or NPM for short, is a tool that simplifies the management of reverse proxies, 
allowing users to easily configure and deploy routing rules for their web applications. 
It provides a graphical interface for managing Nginx configurations, 
making it accessible for users without extensive server administration experience.

Follow the [official guide](https://nginxproxymanager.com/guide/#quick-setup) to set up Nginx Proxy Manager. 
The setup is also covered in the subsection [DNS, Cloudflare, Proxy](#dns-proxy-cloudflare).

Make sure to add SSL certificates for your domain. The tutorial in the subsection [DNS, Cloudflare, Proxy](#dns-proxy-cloudflare) covers the process.

Nginx Proxy Manager exposes the following ports:

* `80`: http
* `443`: https

### Setup

Inside the `npm` directory do:

```shell
docker compose up -d
```

If you get any errors, make sure you followed every step of [Setting up Docker](#setting-up-docker) correctly.

If everything went well, you need to connect to the VPN (instructions to set up VPN: [here](#vpn)) and access the GUI here: `http://10.0.0.5:81`

You can find out how to set up proxy hosts here: [DNS, Proxy, Cloudflare](#dns-proxy-cloudflare).

### SSL Certificates

Nginx Proxy Manger automatically generates certificates based on your configuration.
These certificates will be saved in the external volume `letsencrypt_data`.
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

Add an A-record for Grafana.

#### Nginx Proxy Manager

Add a Proxy Host for:

* Grafana:
  * Destination: `http://grafana:3000`
  * Block common exploits: `true`
  * SSL: make sure to use [your SSL certificate](#dns-proxy-cloudflare)
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

* Destination: `http://nextcloud_app:80`
* Cache Assets: `true `
* Block common exploits: `true`
* Web socket support: `true`
* SSL: make sure to use [your SSL certificate](#dns-proxy-cloudflare)
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

After starting the containers and initial setup of Nextcloud you may see warnings regarding the Maintenance Window and default phone regions.
Setting the following values should resolve these warnings.

Add these lines to `/var/www/html/config/config.php`:
```php
  'logtimezone' => 'Europe/Berlin',
  'default_locale' => 'en_DE',
  'default_phone_region' => 'DE',
  'maintenance_window_start' => 1,
```

Alternatively, you can set these values using occ: [occ config commands](https://docs.nextcloud.com/server/stable/admin_manual/configuration_server/occ_command.html#config-commands)

## Mail

This section is based on the following sources:

* [Setting up DNS records - YouTube](https://www.youtube.com/watch?v=o66UFsodUYo)
* [Official documentation for Docker Mailserver](https://docker-mailserver.github.io/docker-mailserver/latest/)

I'm using [Docker Mailserver](https://github.com/docker-mailserver/docker-mailserver) as Mailserver and [Roundcube](https://roundcube.net/) as Webmail Client.

I can highly recommend to follow the official documentation to set up your mailserver: https://docker-mailserver.github.io/docker-mailserver/latest/

### SSL

It is highly recommended that you use SSL encryption for your mail.
Since Nginx Proxy Manager already generates certificates for us, we can just use those. 
SSL certificates are generated by Nginx Proxy Manager to the external volume `letsencrypt-data`.
For some reason, Nginx Proxy Manager saves the certificates in the directory `/etc/letsencrypt/live/npm-<number>`.
Therefore, the certificate location must be updated manually.
You need to check with folder contains the right certificates and change the environment variables in the docker compose file accordingly.

### Setup

#### Environment variables

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

#### Firewall

I had some issues with `ufw` when trying to connect to the mailserver using an external mail client. Therefore, I allowed these ports as well: 25, 143, 465, 587, 933.

You can allow ports by running: 

```shell
sudo ufw allow <port>
```

#### Initial setup

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

#### Start the mailserver

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

The value in `mail._domainkey` should be the DKIM you just generated in the section above.

You should also set up a PTR record on your host. For Hetzner servers, follow this [guide](https://docs.hetzner.com/dns-console/dns/general/reverse-dns/). The PTR record tells what FQDN your server's IP should resolve to. Use the name of your Mailserver, e.g. `mail.example.com`. For other server providers just look for PTR records or reverse DNS.

You can check your settings using:

* [MXToolbox](https://mxtoolbox.com/): insert the name of your mailserver, e.g. `mail.example.com`
* [Mail Tester](https://www.mail-tester.com/): send an email to the provided address to check if you might get blacklisted.

### Roundcube

Of course, you would want to access your emails. For this purpose we have Roundcube. This is an open source webmail client.
To use it, just set up a DNS record and a proxy host for Roundcube ([DNS, Proxy, Cloudflare](#dns-proxy-cloudflare)) and you can use Roundcube to read and compose emails.

Use `user@example.com` as username. You can create new users using:

```shell
docker exec -it mailserver setup email add <user>@<your domain>
```

#### DNS, Proxy

Add an A-record for roundcube and add the following Proxy Host in Nginx Proxy Manager:

* Roundcube:
  * Destination: `http://roundcube:80`
  * Block common exploits: `true`
  * SSL: make sure to use [your SSL certificate](#dns-proxy-cloudflare)
  * SSL/Force SSL: `true`

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

## Home Assistant

If you need help configuring your `homeassistant` visit the [official documentation](https://www.home-assistant.io/docs/).

### Gluetun

In order to be able to control the devices in your local network you need to connect `homeassistant` to your local network.
This can be done by using a VPN. [Gluetun](https://github.com/qdm12/gluetun-wiki/blob/main/setup/providers/custom.md) is a tool that allows to connect single containers to a VPN.

First, you need to enable a new connection to your home network using Wireguard VPN on your router. 
On the German Fritzbox UI this can be done in Internet/Freigaben/VPN (Wireguard).
Create a new connection, download the configuration. Create a new file `wg0.conf` in the `homeassistant` directory and paste the contents of this file there. Now, you need to copy the endpoint domain and paste it to the `.env` file as value for `VPN_ENDPOINT_DOMAIN`.

Since your router is likely to change its public IP address, you need to update the IP from time to time.
I created a script `dyndns.sh` in the homeassistant directory. This script looks for the corresponding IP address of your router and changes the configuration accordingly. To do this you need to:

* add domain of your router using DynDNS or the DNS your router provided for your VPN connection to the `.env` file
* create a crontab:
  ```shell
  crontab -e
  ```
  and add the following line:
  ```shell
  * * * * * /path/to/dyndns.sh >> /path/to/logs 2>&1
  ```
  Make sure to add the correct path of the script and a valid path for the log file.

### Configuration

Now you need to create new DNS records for homeassistant and a new proxy host in Nginx Proxy Mangager.
It should resolve to: `http://10.0.0.16:8123`. Make sure to enable `Websockets support` and SSL encryption.
Now you need homeassistant to trust the proxy. To do this you need to change the configuration of `homeassistant`.

You can access the configuration by creating another container and mounting the volumes from `homeassistant`.

```
docker run --rm --volumes-from homeassistant -it ubuntu bash
-c "apt update && apt install -y nano && nano /config/configuration.yaml"
```
Now you should have root access to the newly created container. Inside the container do:

```
apt update && apt install -y nala
nala /config/configuration.yml
```

Add the following lines:

```
http:
  use_x_forwarded_for: true
  trusted_proxies:
    - 10.0.0.5

homeassistant:
  auth_mfa_modules:
    - type: totp
```

This configuration also enabled two factor authentication.
Restart the container and you should now be able to access `homeassistant` via your newly created domain.

To make the health check work properly, you also need to configure the domain you want to access `homeassistant` from in the `.env` file.

## Backup

The backup script is located in `backup`. This script is specific to my system. You need to change the variable `backup-parent-dir`.

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
