![banner](https://github.com/11notes/defaults/blob/main/static/img/banner.png?raw=true)

# ADGUARD
![size](https://img.shields.io/docker/image-size/11notes/adguard/0.107.63?color=0eb305)![5px](https://github.com/11notes/defaults/blob/main/static/img/transparent5x2px.png?raw=true)![version](https://img.shields.io/docker/v/11notes/adguard/0.107.63?color=eb7a09)![5px](https://github.com/11notes/defaults/blob/main/static/img/transparent5x2px.png?raw=true)![pulls](https://img.shields.io/docker/pulls/11notes/adguard?color=2b75d6)![5px](https://github.com/11notes/defaults/blob/main/static/img/transparent5x2px.png?raw=true)[<img src="https://img.shields.io/github/issues/11notes/docker-ADGUARD?color=7842f5">](https://github.com/11notes/docker-ADGUARD/issues)![5px](https://github.com/11notes/defaults/blob/main/static/img/transparent5x2px.png?raw=true)![swiss_made](https://img.shields.io/badge/Swiss_Made-FFFFFF?labelColor=FF0000&logo=data:image/svg%2bxml;base64,PHN2ZyB2ZXJzaW9uPSIxIiB3aWR0aD0iNTEyIiBoZWlnaHQ9IjUxMiIgdmlld0JveD0iMCAwIDMyIDMyIiB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciPgogIDxyZWN0IHdpZHRoPSIzMiIgaGVpZ2h0PSIzMiIgZmlsbD0idHJhbnNwYXJlbnQiLz4KICA8cGF0aCBkPSJtMTMgNmg2djdoN3Y2aC03djdoLTZ2LTdoLTd2LTZoN3oiIGZpbGw9IiNmZmYiLz4KPC9zdmc+)

Run AdGuardHome rootless, distroless and secure by default

# SYNOPSIS 📖
**What can I do with this?** Block most ads from most websites, have entire categories blocked on your or other networks or for individual clients. Perfect for parents and enterprises alike.

# UNIQUE VALUE PROPOSITION 💶
**Why should I run this image and not the other image(s) that already exist?** Good question! All the other images on the market that do exactly the same don’t do or offer these options:

> [!IMPORTANT]
>* This image runs as 1000:1000 by default, most other images run everything as root
>* This image has no shell since it is 100% distroless, most other images run on a distro like Debian or Alpine with full shell access (security)
>* This image does not ship with any critical or high rated CVE and is automatically maintained via CI/CD, most other images mostly have no CVE scanning or code quality tools in place
>* This image is created via a secure, pinned CI/CD process and immune to upstream attacks, most other images have upstream dependencies that can be exploited
>* This image contains a patch to run rootless (Linux caps needed), most other images require higher caps
>* This image contains a proper health check that verifies the app is actually working, most other images have either no health check or only check if a port is open or ping works
>* This image works as read-only, most other images need to write files to the image filesystem
>* This image is a lot smaller than most other images

If you value security, simplicity and the ability to interact with the maintainer and developer of an image. Using my images is a great start in that direction.

# COMPARISON 🏁
Below you find a comparison between this image and the most used or original one.

| **image** | 11notes/adguard:0.107.63 | adguard/adguardhome:latest |
| ---: | :---: | :---: |
| **image size on disk** | 15.4MB | 74.2MB |
| **process UID/GID** | 1000/1000 | 0/0 |
| **distroless?** | ✅ | ❌ |
| **rootless?** | ✅ | ❌ |


# DEFAULT CONFIG 📑
```yaml
dns:
  bind_hosts:
    - 0.0.0.0
  ratelimit: 0
  aaaa_disabled: true
  all_servers: true
  upstream_dns:
    - 9.9.9.10
  bootstrap_dns:
    - 9.9.9.10
  cache_size: 1073741824
  max_goroutines: 1024
  hostsfile_enabled: false
dhcp:
  enabled: false
http:
  address: 0.0.0.0:3000
  session_ttl: 720h
querylog:
  enabled: true
  file_enabled: true
  size_memory: 8
  dir_path: /adguard/var
users:
  - name: admin
    password: $2b$12$xzIFiVMrq2jv5NH5pNNQSuEK84FDNI4PoiJbKIhZqUe1Ld/v1BI9W
auth_attempts: 3
block_auth_min: 60
filtering:
  blocking_mode: nxdomain
  cache_time: 1440
  filters_update_interval: 24
  blocked_response_ttl: 3660
  protection_enabled: true
clients:
  persistent:
    - name: dnslookup
      ids:
        - 127.0.0.1
      ignore_querylog: true
      ignore_statistics: true
log:
  enabled: true
  file: ""
  max_backups: 0
  max_size: 100
  max_age: 3
  compress: false
  local_time: true
  verbose: false
schema_version: 29
```

The default configuration contains no special settings, except ignoring the dnslookup health check in the statistics and as a client to not pollute your UI or statistics. Consider replacing it with your own or start the container with the default one and start changing what you need. The configuration will be updated with your settings if you use the mentioned volumes below. It is recommended to always add the exception for dnslookup.

```yaml
clients:
  persistent:
    - name: dnslookup
      ids:
        - 127.0.0.1
      ignore_querylog: true
      ignore_statistics: true
```

# VOLUMES 📁
* **/adguard/etc** - Directory of the configuration file
* **/adguard/var** - Directory of database and query log files

# COMPOSE ✂️
```yaml
name: "adguard"
services:
  adguard:
    image: "11notes/adguard:0.107.63"
    read_only: true
    environment:
      TZ: "Europe/Zurich"
    volumes:
      - "etc:/adguard/etc"
      - "var:/adguard/var"
    tmpfs:
      # tmpfs volume because of read_only: true
      - "/adguard/run:uid=1000,gid=1000"
    ports:
      - "53:53/udp"
      - "53:53/tcp"
      - "3000:3000/tcp"
    networks:
      frontend:
    sysctls:
      # allow rootless container to access ports < 1024
      net.ipv4.ip_unprivileged_port_start: 53
    restart: "always"

volumes:
  etc:
  var:

networks:
  frontend:
```

# DEFAULT SETTINGS 🗃️
| Parameter | Value | Description |
| --- | --- | --- |
| `user` | docker | user name |
| `uid` | 1000 | [user identifier](https://en.wikipedia.org/wiki/User_identifier) |
| `gid` | 1000 | [group identifier](https://en.wikipedia.org/wiki/Group_identifier) |
| `home` | /adguard | home directory of user docker |
| `login` | admin // adguard | login using default config |

# ENVIRONMENT 📝
| Parameter | Value | Default |
| --- | --- | --- |
| `TZ` | [Time Zone](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones) | |
| `DEBUG` | Will activate debug option for container image and app (if available) | |

# MAIN TAGS 🏷️
These are the main tags for the image. There is also a tag for each commit and its shorthand sha256 value.

* [0.107.63](https://hub.docker.com/r/11notes/adguard/tags?name=0.107.63)
* [stable](https://hub.docker.com/r/11notes/adguard/tags?name=stable)

### There is no latest tag, what am I supposed to do about updates?
It is of my opinion that the ```:latest``` tag is dangerous. Many times, I’ve introduced **breaking** changes to my images. This would have messed up everything for some people. If you don’t want to change the tag to the latest [semver](https://semver.org/), simply use the short versions of [semver](https://semver.org/). Instead of using ```:0.107.63``` you can use ```:0``` or ```:0.107```. Since on each new version these tags are updated to the latest version of the software, using them is identical to using ```:latest``` but at least fixed to a major or minor version.

If you still insist on having the bleeding edge release of this app, simply use the ```:rolling``` tag, but be warned! You will get the latest version of the app instantly, regardless of breaking changes or security issues or what so ever. You do this at your own risk!

# REGISTRIES ☁️
```
docker pull 11notes/adguard:0.107.63
docker pull ghcr.io/11notes/adguard:0.107.63
docker pull quay.io/11notes/adguard:0.107.63
```

# SOURCE 💾
* [11notes/adguard](https://github.com/11notes/docker-ADGUARD)

# PARENT IMAGE 🏛️
> [!IMPORTANT]
>This image is not based on another image but uses [scratch](https://hub.docker.com/_/scratch) as the starting layer.
>The image consists of the following distroless layers that were added:
>* [11notes/distroless](https://github.com/11notes/docker-distroless/blob/master/arch.dockerfile) - contains users, timezones and Root CA certificates
>* [11notes/distroless:dnslookup](https://github.com/11notes/docker-distroless/blob/master/dnslookup.dockerfile) - app to execute DNS queries

# BUILT WITH 🧰
* [AdGuardHome](https://github.com/AdguardTeam/AdGuardHome)

# GENERAL TIPS 📌
> [!TIP]
>* Use a reverse proxy like Traefik, Nginx, HAproxy to terminate TLS and to protect your endpoints
>* Use Let’s Encrypt DNS-01 challenge to obtain valid SSL certificates for your services

# CAUTION ⚠️
> [!CAUTION]
>* This image comes with a default configuration with a default password for the admin account. Please set your own password or provide your own configuration.

# ElevenNotes™️
This image is provided to you at your own risk. Always make backups before updating an image to a different version. Check the [releases](https://github.com/11notes/docker-adguard/releases) for breaking changes. If you have any problems with using this image simply raise an [issue](https://github.com/11notes/docker-adguard/issues), thanks. If you have a question or inputs please create a new [discussion](https://github.com/11notes/docker-adguard/discussions) instead of an issue. You can find all my other repositories on [github](https://github.com/11notes?tab=repositories).

*created 27.06.2025, 07:43:17 (CET)*