# Alpine :: AdGuard
Run AdGuard based on Alpine Linux. Small, lightweight, secure and fast 🏔️

## Volumes
* **/adguard/etc** - Directory of your configuration file (AdGuardHome.yaml)
* **/adguard/var** - Directory of your database

## Run
```shell
docker run --name adguard \
  -v ../etc:/adguard/etc \
  -v ../var:/adguard/var \
  -d 11notes/adguard:[tag]
```

## Defaults
| Parameter | Value | Description |
| --- | --- | --- |
| `user` | docker | user docker |
| `uid` | 1000 | user id 1000 |
| `gid` | 1000 | group id 1000 |
| `home` | /adguard | home directory of user docker |
| `webui` | https://${IP}:8443 | default web ui|
| `login` | admin // adguard | default login |

## Parent
* [11notes/alpine:stable](https://github.com/11notes/docker-alpine)

## Built with
* [AdGuardHome](https://github.com/AdguardTeam/AdGuardHome)
* [Alpine Linux](https://alpinelinux.org)