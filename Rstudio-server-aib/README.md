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

## Stop the server when done

Important to do this -- otherwise it may keep using disk or memory. I think rebooting is not enough to clear it.

First have a look at the docker processes

    docker ps -a

This will return a lsit such as 

    CONTAINER ID        IMAGE                COMMAND                  CREATED             STATUS              PORTS                    NAMES
    0c4e976e40c5        rstudio-server-aib   "/usr/lib/rstudio-se."   3 minutes ago       Up 3 minutes        0.0.0.0:8787->8787/tcp   quizzical_goldberg

Probably there should be only such line, containing 'rstudio-server-aib' (if there are more, remove them using "docker rm").

Note the container ID, and run docker stop on it:

    docker stop 0c4e

As with git, it is enough to give the unique prefix 0c4e rather than the whole id 0c4e976e40c5.

