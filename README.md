![Banner](https://github.com/11notes/defaults/blob/main/static/img/banner.png?raw=true)

# 🏔️ Alpine - adguard
![size](https://img.shields.io/docker/image-size/11notes/adguard/0.107.52?color=0eb305) ![version](https://img.shields.io/docker/v/11notes/adguard/0.107.52?color=eb7a09) ![pulls](https://img.shields.io/docker/pulls/11notes/adguard?color=2b75d6)

**Run your on-prem DNS blocker with ease and security in mind**

# SYNOPSIS
What can I do with this? Block most ads from most websites, have entire categories blocked on your or other networks or for individual clients. Perfect for parents and enterprises alike.

# VOLUMES
* **/adguard/etc** - Directory of your configuration file (AdGuardHome.yaml)
* **/adguard/var** - Directory of your database

# COMPOSE
```yaml
services:
  adguard:
    image: "11notes/adguard:0.107.52"
    container_name: "adguard"
    environment:
      TZ: "Europe/Zurich"
    volumes:
      - "etc:/adguard/etc"
      - "var:/adguard/var"
    networks:
      macvlan:
        ipv4_address: 10.255.255.53
    restart: always
volumes:
  etc:
  var:
networks:
  macvlan:
    driver: macvlan
    driver_opts:
      parent: eth0
    ipam:
      config:
        - subnet: "10.255.255.0/24"
          gateway: "10.255.255.254"
```

# DEFAULT SETTINGS
| Parameter | Value | Description |
| --- | --- | --- |
| `user` | docker | user docker |
| `uid` | 1000 | user id 1000 |
| `gid` | 1000 | group id 1000 |
| `home` | /adguard | home directory of user docker |
| `web` | https://${IP}:8443 | default web ui |
| `login` | admin // adguard | default login |


# ENVIRONMENT
| Parameter | Value | Default |
| --- | --- | --- |
| `TZ` | [Time Zone](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones) | |
| `DEBUG` | Show debug information | |

# SOURCE
* [11notes/adguard](https://github.com/11notes/docker-adguard)

# PARENT IMAGE
* [11notes/alpine:stable](https://hub.docker.com/r/11notes/alpine)

# BUILT WITH
* [adguard](https://github.com/AdguardTeam/AdGuardHome)
* [alpine](https://alpinelinux.org)

# TIPS
* Use a reverse proxy like Traefik, Nginx to terminate TLS with a valid certificate
* Use Let’s Encrypt certificates to protect your SSL endpoints

# ElevenNotes<sup>™️</sup>
This image is provided to you at your own risk. Always make backups before updating an image to a new version. Check the changelog for breaking changes. You can find all my repositories on [github](https://github.com/11notes).
    