# Server Config

<!-- TOC -->
* [Server Config](#server-config)
  * [Prerequisites](#prerequisites)
    * [Mounting Storage Box](#mounting-storage-box)
  * [Monitoring](#monitoring)
  * [Portainer](#portainer)
  * [Nginx Proxy Manager](#nginx-proxy-manager)
  * [Nextcloud](#nextcloud)
    * [Prerequisites](#prerequisites-1)
    * [Installation](#installation)
    * [Configuration](#configuration)
      * [DNS](#dns)
      * [Nginx Proxy Manger](#nginx-proxy-manger)
<!-- TOC -->

## Prerequisites

### Initializing Server

To install an operating system follow this doc: [Installimage](https://docs.hetzner.com/robot/dedicated-server/operating-systems/installimage/)

In short, in order to be able to access the server, you have to activate the rescue system first. 
Hetzner will show a password that can be used to access the server as user `root`.

> To be able to access the Rescue System you have to reboot the server.

```shell
ssh root@<server-ip>
```

Then you can run `installimage` to start the installation script.

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
