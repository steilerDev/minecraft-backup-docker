# Docker Container for Minecraft Backups
This docker container can be run together with `itzg/minecraft-server` and provides a comprehensive set of tools to regularily backup the minecraft world, apply retention policies and restore to previous states.

The tool communicates with the minecraft server through RCON messages and can optionally log the current activities to specific users on the server.

The backup process itself has been designed to ensure data integrity. Unfortunately Mojang does not guarantee `auto save off` (See [MC-217729](https://bugs.mojang.com/browse/MC-217729)), however the tool will try and detect inconsistencies.

# Configuration options
## Environment Variables
The following environmental variables can be used for configuration:

 - `MC_DOCKER`
    The docker container name of the Minecraft server (used to start/stop the server during restoring)
    *required*
 - `RCON_PASSWORD`
    The password to login to the RCON interface of the Minecraft server.
    *required*
 - `RCON_HOST`
    The hostname of the RCON interface of the Minecraft server.
    *required*
 - `RCON_PORT`
    The port of the RCON interface of the Minecraft server.
    *default: 25575*
 - `RCON_PREFIX` 
    The prefix used in RCON messages.
    *default: BOT*
 - Data retention policy:
   - Specify the number of backups to be kept for this category. If the variable is not defined, all backups of the category are kept.
   - `KEEP_HOURLY`
      Number of last hourly backups to be retained
   - `KEEP_DAILY`
      Number of last daily backups to be retained
   - `KEEP_WEEKLY`
      Number of last weekly backups to be retained
   - `KEEP_MONTHLY`
      Number of last monthly backups to be retained
   - `KEEP_YEARLY`
      Number of last yearly backups to be retained
 - `DEBUG`
    If not empty, increase logging output for debug purposes
    *default: unset*
 - `LOG_RCON`
    If not empty, log messages to the RCON interface
    *default: unset*

## Volume Mounts
The following paths are recommended for persisting state and/or accessing configurations

 - `/world/` 
    Source location of the current Minecraft world.
 - `/config/`
    Configuration directory
 - `/history/`
    Directory holding the backup history

# docker-compose example
Usage with [`nginx-proxy`](https://github.com/nginx-proxy/nginx-proxy) and [`acme-companion`](https://github.com/nginx-proxy/acme-companion) inside of predefined `steilerGroup` network.

```
version: '2'
services:
  <service-name>:
    image: steilerdev/<pkg-name>:latest
    container_name: <docker-name>
    restart: unless-stopped
    hostname: "<hostname>"
    environment:
      VAR: "value"
    volumes:
      - /<some-host-path>:/<some-docker-path>
networks:
  default:
    external:
      name: steilerGroup
```