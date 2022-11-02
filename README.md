# Docker Container for Minecraft Backups
This docker container can be run together with `itzg/minecraft-server` and provides a comprehensive set of tools to regularily backup the minecraft world, apply retention policies and restore to previous states.

The tool communicates with the minecraft server through RCON messages and can optionally log the current activities to specific users on the server.

The backup process itself has been designed to ensure data integrity. Unfortunately Mojang does not guarantee `auto save off` (See [MC-217729](https://bugs.mojang.com/browse/MC-217729)), however the tool will try and detect inconsistencies.

# Configuration options
In order to restore back to a previous backup, this docker container needs to be able to access the local docker daemon. For this, please expose the docker socket through a volume bind:
 - `/var/run/docker.sock:/var/run/docker.sock`

## Environment Variables
The following environmental variables can be used for configuration:

 - `MC_DOCKER`  
    The docker container name of the Minecraft server (used to start/stop the server during restoring)  
    *required*
 - `CRON_SCHEDULE`  
    The cron expression, defining the backup schedule. See [crontab.guru](https://crontab.guru) for help on defining this.
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
   Specify the number of backups to be kept for this category. If the variable is not defined, all backups of the category are kept.
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
    Send log messages via RCON interface to the user specified in this variable. Not sending logs to RCON if this is empty.
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
Usage with [`itzg/minecraft-server`](https://github.com/itzg/docker-minecraft-server) inside a predefined `steilerGroup` network.

```
version: '3'
services:
   minecraft:
   image: itzg/minecraft-server:latest
   container-name: minecraft
   ports:
      "25565:25565"
   volumes:
      - /opt/steilerGroup-Docker/minecraft/volumes/data:/data
   environment:
      <...>
      RCON_PASSWORD: "someRCONPwd" 
      <...>
    restart: unless-stopped
  minecraft-backup:
    image: steilerdev/minecraft-backup-docker:latest
    container_name: minecraft-backup
    volumes:
      - /opt/steilerGroup-Docker/minecraft/volumes/data/world:/world
      - /opt/steilerGroup-Docker/minecraft/volumes/history:/history
      - /opt/steilerGroup-Docker/minecraft/volumes/mc-backup-config:/config
      - /var/run/docker.sock:/var/run/docker.sock
    environment:
      CRON_SCHEDULE: "0 * * * *"
      RCON_PASSWORD: "someRCONPwd"
      RCON_HOST: "minecraft.steilerGroup"
      LOG_RCON: "derduesterriese"
      KEEP_HOURLY: "6"
      KEEP_DAILY: "5"
      KEEP_WEEKLY: "3"
      MC_DOCKER: "minecraft"
    depends_on:
      - "minecraft" 
networks:
  default:
   name: steilerGroup
   external: true
```