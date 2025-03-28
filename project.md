${{ content_synopsis }} Block most ads from most websites, have entire categories blocked on your or other networks or for individual clients. Perfect for parents and enterprises alike.

${{ content_uvp }} Good question! All the other images on the market that do exactly the same don’t do or offer these options:

${{ github:> [!IMPORTANT] }}
${{ github:> }}* This image runs as 1000:1000 by default, most other images run everything as root
${{ github:> }}* This image has no shell since it is 100% distroless, most other images run on a distro like Debian or Alpine with full shell access (security)
${{ github:> }}* This image does not ship with any CVE and is automatically maintained via CI/CD, most other images mostly have no CVE scanning or code quality tools in place
${{ github:> }}* This image is created via a secure, pinned CI/CD process and immune to upstream attacks, most other images have upstream dependencies that can be exploited
${{ github:> }}* This image contains a patch to run rootless (Linux caps needed), most other images require higher caps
${{ github:> }}* This image contains a proper health check that verifies the app is actually working, most other images have either no health check or only check if a port is open or ping works

If you value security, simplicity and the ability to interact with the maintainer and developer of an image. Using my images is a great start in that direction.

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

${{ content_default }}
| `login` | admin // adguard | login using default config |

${{ content_environment }}

${{ content_source }}

${{ content_parent }}

${{ content_built }}

${{ content_tips }}

${{ title_caution }}
${{ github:> [!CAUTION] }}
${{ github:> }}* This image comes with a default SSL certificate. If you plan to expose the web interface via HTTPS, please replace the default certificate with your own.
${{ github:> }}* This image comes with a default configuration with a default password for the admin account. Please set your own password or provide your own configuration.