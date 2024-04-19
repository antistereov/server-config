# Server Config

<!-- TOC -->
* [Server Config](#server-config)
  * [Remark](#remark)
  * [Prerequisites](#prerequisites)
    * [Initializing Server](#initializing-server)
      * [Install Ubuntu](#install-ubuntu)
      * [Setup](#setup)
    * [Change SSH port](#change-ssh-port)
    * [Firewall setting](#firewall-setting)
    * [Mounting Storage Box](#mounting-storage-box)
    * [Setting up Docker](#setting-up-docker)
    * [DNS, Cloudflare, Proxy](#dns-cloudflare-proxy)
  * [Nginx Proxy Manager](#nginx-proxy-manager)
  * [Monitoring](#monitoring)
    * [Configuration](#configuration)
      * [DNS](#dns)
      * [Nginx Proxy Manager](#nginx-proxy-manager-1)
      * [Grafana](#grafana)
  * [Nextcloud](#nextcloud)
    * [Prerequisites](#prerequisites-1)
    * [Installation](#installation)
    * [Configuration](#configuration-1)
      * [DNS](#dns-1)
      * [Nginx Proxy Manger](#nginx-proxy-manger)
      * [Nextcloud Config](#nextcloud-config)
  * [Backup](#backup)
  * [Mailcow](#mailcow)
<!-- TOC -->

## Remark

This configuration is specific to my setup. You might need to skip some of these steps. 
I tried to add every source that I used to configure my server. Feel free to check these out too.

Two notes on Docker: 
* I like to use Docker volumes for persistent storage instead of local directories since these are easier to back up, and you cannot destroy your containers with user rights management. I strongly recommend you using Docker volumes as well. This would have saved me days trying to fix things when setting up my server for the first time.
* I use an external docker network to connect all services. This way, only port `80` and `443` get exposed. Routing is done by Nginx Proxy Manager. Everything else stays in the Docker network.

## Prerequisites

### Initializing Server

#### Install Ubuntu

> My server is hosted by Hetzner. Therefore, the installation of Ubuntu on this machine is specific to Hetzner.

To install an operating system follow this doc: [Installimage](https://docs.hetzner.com/robot/dedicated-server/operating-systems/installimage/)

In short, in order to be able to access the server, you have to activate the rescue system first. 
Hetzner will show a password that can be used to access the server as user `root`.

> To be able to access the Rescue System you have to reboot the server.

```shell
ssh root@<server-ip>
```

Then you can run `installimage` to start the installation script.

#### Setup

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
   
### Change SSH port

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

Be extra careful when modifying the SSH configuration file. The incorrect configuration may cause the SSH service to fail to start.

Once done, save the file and restart the SSH service to apply the changes:

```shell
sudo systemctl restart ssh
```

### Firewall setting

This configuration is based on the following sources:

* [How to limit SSH (TCP port 22) connections with ufw on Ubuntu Linux](https://www.cyberciti.biz/faq/howto-limiting-ssh-connections-with-ufw-on-ubuntu-debian/) by Vivek Gite on https://www.cyberciti.biz
* [How to Set Up a Firewall with UFW on Ubuntu](https://www.digitalocean.com/community/tutorials/how-to-set-up-a-firewall-with-ufw-on-ubuntu) by Brian Boucheron and Jamon Camisso on https://www.digitalocean.com
 
Set up default policies:

```shell
sudo ufw default deny incoming
sudo ufw default allow outgoing
```

Allow SSH (make sure to use the port specified [here](#change-ssh-port):

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

Clone repository:

```shell
git clone <repository-url>
```

Create the docker network:

```shell
docker network create proxy
```

### DNS, Cloudflare, Proxy

Follow this tutorial: https://www.youtube.com/watch?v=GarMdDTAZJo

## Nginx Proxy Manager

[Nginx Proxy Manager](https://nginxproxymanager.com/) is a tool that simplifies the management of reverse proxies, 
allowing users to easily configure and deploy routing rules for their web applications. 
It provides a graphical interface for managing Nginx configurations, 
making it accessible for users without extensive server administration experience.

Nginx Proxy Manager exposes the following ports:

* `80`: http
* `443`: https

## Monitoring

This configuration is based on the following sources:

* [How to Set Up Grafana and Prometheus Using Docker ](https://dev.to/chafroudtarek/part-1-how-to-set-up-grafana-and-prometheus-using-docker-i47) by Chafroud Tarek on https://dev.to

The `monitoring`-stack contains the following services:

* [Portainer](https://www.portainer.io/): Container management tool
* [Grafana](https://grafana.com/oss/grafana/): Data visualization
* [Prometheus](https://prometheus.io/docs/introduction/overview/): Systems monitoring and alerting toolkit
* [Cadvisor](https://github.com/google/cadvisor): Container monitoring
* [Node Exporter](https://github.com/prometheus/node_exporter): Prometheus exporter for machine metrics

### Configuration

#### DNS

Add an A-record for Grafana, Nginx Proxy Manager and Portainer.

#### Nginx Proxy Manager

Follow the [official guide](https://nginxproxymanager.com/guide/#quick-setup) to set up Nginx Proxy Manager. 
The setup is also covered in the subsection [DNS, Cloudflare, Proxy](#dns-cloudflare-proxy).

> Make sure to add SSL certificates for your domain.

Add a Proxy Host for:

* Portainer: 
  * Destination: `http://portainer:9000`
  * Block common exploits: `true`
  * SSL: make sure to use your SSL certificate
  * SSL/Force SSL: `true`
* Grafana:
  * Destination: `http://grafana:3000`
  * Block common exploits: `true`
  * SSL: make sure to use your SSL certificate
  * SSL/Force SSL: `true`
* Nginx Proxy Manager:
  * Destination: `http://nginx-proxy-manager:81`
  * Block common exploits: `true`
  * SSL: make sure to use your SSL certificate
  * SSL/Force SSL: `true`

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

Create file `.env` in `./nextcloud` directory:

```shell
touch ./.env
```
Add the following variables in the `.env` file
```text
MYSQL_ROOT_PASSWORD=<ROOT_PASSWORD>
MYSQL_PASSWORD=<PASSWORD>
NEXTCLOUD_TRUSTED_DOMAINS=<DOMAIN>
OVERWRITEHOST=<DOMAIN>
```

### Installation

Build and run the stack:

```shell
docker compose up -d
```

### Configuration

#### DNS

Add an A-record for your Nextcloud domain.

#### Nginx Proxy Manger

* Destination: `http://nextcloud-app:80`
* Cache Assets: `true `
* Block common exploits: `true`
* Web socket support: `true`
* SSL: make sure to use your SSL certificate
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

Add these lines to `nextcloud-data/config/config.php`:
```php
  'logtimezone' => 'Europe/Berlin',
  'default_locale' => 'en_DE',
  'default_phone_region' => 'DE',
  'maintenance_window_start' => 1,
```

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


## Mailcow

Follow this tutorial for setting up Mailcow: https://www.youtube.com/watch?v=4rzc0hWRSPg

Follow this tutorial for setting up DNS records: https://www.youtube.com/watch?v=o66UFsodUYo

> Development is still in progress...
