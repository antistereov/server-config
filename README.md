# Server Config

<!-- TOC -->
* [Server Config](#server-config)
  * [Prerequisites](#prerequisites)
    * [Initializing Server](#initializing-server)
      * [Install OS](#install-os)
      * [Setup](#setup)
    * [Mounting Storage Box](#mounting-storage-box)
    * [Setting up Docker](#setting-up-docker)
  * [Monitoring](#monitoring)
  * [Portainer](#portainer)
  * [Nginx Proxy Manager](#nginx-proxy-manager)
  * [Mailcow](#mailcow)
  * [Nextcloud](#nextcloud)
    * [Prerequisites](#prerequisites-1)
    * [Installation](#installation)
    * [Configuration](#configuration)
      * [DNS](#dns)
      * [Nginx Proxy Manger](#nginx-proxy-manger)
  * [Backup](#backup)
<!-- TOC -->

## Prerequisites

### Initializing Server

#### Install OS

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
5. Install applications:
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
9. Change default shell to `fish`:
    ```shell
    chsh -s $(which fish)
    ```
   
### Change SSH port

Open the SSH configuration file /etc/ssh/sshd_config with your text editor:

```shell
sudo nano /etc/ssh/sshd_config
```

Search for the line starting with Port 22. In most cases, this line starts with a hash (#) character. 
Remove the hash # and enter the new SSH port number:

```text
Port 5522
```

Be extra careful when modifying the SSH configuration file. The incorrect configuration may cause the SSH service to fail to start.

Once done, save the file and restart the SSH service to apply the changes:

```shell
sudo systemctl restart ssh
```

### Mounting Storage Box

Follow this tutorial: [Access Storage Box via Samba/CIFS](https://docs.hetzner.com/robot/storage-box/access/access-samba-cifs)

Make sure to mount the storage box to `/data` on the server and enable encryption. Add this line to `/etc/fstab`:

```text
//<username>.your-storagebox.de/backup /data cifs seal,iocharset=utf8,rw,credentials=/etc/backup-credentials.txt,uid=<system account>,gid=<system group>,file_mode=0660,dir_mode=0770 0 0
```

Also create the file `/etc/backup-credentials.txt` with the following content:

```text
username=<username>
password=<password>
```

### Setting up Docker

Generate an SSH-key to be able to access the [Server Config](https://github.com/antistereov/server-config)

```shell
ssh-keygen -t ed25519 -C "andre.antimonov@posteo.de"
```

Clone repository:

```shell
git clone   
```

## Monitoring

<!-- TODO: Add monitoring -->

## Portainer

Portainer exposes the following ports:

* `9443`: Portainer console using a self-signed SSL-certificate

## Nginx Proxy Manager

Nginx Proxy Manager exposes the following ports:

* `80`: http
* `443`: https
* `81`: Nginx Proxy Manager Console

## Mailcow

Follow this tutorial for setting up Mailcow: https://www.youtube.com/watch?v=4rzc0hWRSPg

Follow this tutorial for setting up DNS records: https://www.youtube.com/watch?v=o66UFsodUYo

## Nextcloud

Nextcloud exposes the following ports:

* `8000`: Nextcloud website

### Prerequisites

Create directory `/data/nextcloud`.

```shell
sudo mkdir /data/nextcloud
```

Create file `.env` in same directory as `docker-compose.yml`
```shell
touch ./.env
```
Add the following variables in the `.env` file
```text
MYSQL_ROOT_PASSWORD=<ROOT_PASSWORD>
MYSQL_PASSWORD=<PASSWORD>
NEXTCLOUD_TRUSTED_DOMAINS=<DOMAIN>
```

### Installation

Build and run the stack:

```shell
docker compose up -d
```

### Configuration

#### DNS

Add the following A-record:


#### Nginx Proxy Manger

* Scheme: `http`
* Forward Hostname: `IP of server`
* Port: `8000 `
* Cache Assets: `true `
* Block common exploits: `true`
* Web socket support: `true` 
* SSL-certificate: `*.stereov.com`
* Force SSL: `true`
* HTTP/2-support: `true`
* HSTS enabled: `true`
* HSTS subdomains: `true`
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
Add these lines to `nextcloud-data/config/config.php`:
```php
  'logtimezone' => 'Europe/Berlin',
  'default_locale' => 'en_DE',
  'default_phone_region' => 'DE',
  'maintenance_window_start' => 1,
```

## Backup

The backup script is located in `backup`.

To schedule a cron job to run your script every day at 4 AM, you can use the `crontab` command.
First, open the crontab file for editing with the command `crontab -e`
Then, add the following line to the file:

```bash
0 4 * * * bash -c "/home/stereov/server-config/backup/backup.sh" >> /var/log/backup.log 2>&1
```

> Make sure to set the ownership of the logfile to the user.

This line tells cron to run your script at 4 AM (0 minutes past the 4th hour) every day.
Make sure your script has execute permissions. You can add them with the command `chmod +x /home/stereov/server-config/backup/backup.sh`.
Save and close the file. The cron job is now scheduled and will run your script every day at 4 AM.
