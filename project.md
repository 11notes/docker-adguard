${{ content_synopsis }} This image will run AdGuard-Home [rootless](https://github.com/11notes/RTFM/blob/main/linux/container/image/rootless.md) and [distroless](https://github.com/11notes/RTFM/blob/main/linux/container/image/distroless.md), for maximum security and performance.

${{ content_uvp }} Good question! Because ...

${{ github:> [!IMPORTANT] }}
${{ github:> }}* ... this image runs [rootless](https://github.com/11notes/RTFM/blob/main/linux/container/image/rootless.md) as 1000:1000
${{ github:> }}* ... this image has no shell since it is [distroless](https://github.com/11notes/RTFM/blob/main/linux/container/image/distroless.md)
${{ github:> }}* ... this image has a health check
${{ github:> }}* ... this image runs read-only
${{ github:> }}* ... this image is automatically scanned for CVEs before and after publishing
${{ github:> }}* ... this image is created via a secure and pinned CI/CD process
${{ github:> }}* ... this image is very small

If you value security, simplicity and optimizations to the extreme, then this image might be for you.

${{ content_comparison }}

${{ title_config }}
```yaml
${{ include: ./rootfs/adguard/etc/config.yaml }}
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

${{ title_volumes }}
* **${{ json_root }}/etc** - Directory of the configuration file
* **${{ json_root }}/var** - Directory of database and query log files

${{ content_compose }}

${{ content_defaults }}
| `login` | admin // adguard | login using default config |

${{ content_environment }}

${{ content_source }}

${{ content_parent }}

${{ content_built }}

${{ content_tips }}

${{ title_caution }}
${{ github:> [!CAUTION] }}
${{ github:> }}* This image comes with a default configuration with a default password for the admin account. Please set your own password or provide your own configuration.