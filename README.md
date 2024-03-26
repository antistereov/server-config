# Server Config

<!-- TOC -->
* [Server Config](#server-config)
  * [Prerequisites](#prerequisites)
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



## Monitoring

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

Details: Scheme: http, Forward Hostname: IP of server, Port: 8000
Cache Assets: true
Block common exploits: true
Web socket support: true
SSL-certificate: *.stereov.com
Force SSL: true
HTTP/2-support: true
HSTS enabled: true
HSTS subdomains: true

Custom Nginx Configuration:

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
