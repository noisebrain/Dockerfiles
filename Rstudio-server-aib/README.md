# rstudio-server-aib

Adapted from here https://hub.docker.com/r/dceoy/rstudio-server/  https://github.com/dceoy/docker-rstudio-server

Modified to use R 3.5.1 and pre-install packages needed for AIB stats project

## How to run

### On mac: no special setup needed

### On windows: 

Have not tried this yet. It should run, however there may be folder permission issues.

### On linux: one-time setup

If not done previously, make a docker group and add yourself to it:

    sudo groupadd -g 999 docker`
    sudo usermod -aG docker mylogin`

Replace `mylogin` with your login name.

Make a folder to work in, with friendly permissions.

    mkdir MyDockerFolder
    chgrp docker MyDockerFolder
    chmod g+s MyDockerFolder
    cd MyDockerFolder 

This sets the folder group to "docker", makes it writable by group, and sets the "group sticky bit". The GSB causes all files created in the folder to have the docker group. Doing this seems to be the best way to allow both the host user and the container process have correct permissions, without giving the container root access.

## Start the rstudio server

    docker container run --rm -p 8787:8787 -v ${PWD}:/home/rstudio -w /home/rstudio rstudio-server-aib

On a linux machine behind a firewall it may be necessary to add `--network host` if the R process needs to access the internet (to install packages)

## Attach to the server

In a browser, go to `localhost:8787`



