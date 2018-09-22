# this dockerfile launches rstudio server, can attach to it from the browser, nice!
#
# If on linux behind firewall: try adding "--network host" to both the build and run
# On Mac running with --network host does not work.
#
# On linux, first make a Folder with docker group, and run inside that folder:
#	umask u=rwx,g=rwx,o=rx    #set group writable umask   
#	mkdir Folder
#	chgrp docker Folder
#	chmod g+s Folder	# group sticky bit
#	cd Folder
#
# Now launch the docker server
#   	docker run --rm -p 8787:8787 -v ${PWD}:/home/rstudio -w /home/rstudio noisebrain/rstudio-server-aib
#	# also try --network  host
# And in a browser, go to
#	localhost:8787
#
# To build the docker image:
# 	docker build . -f rstudio-server-aib.dockerfile -t rstudio-server-aib  	# also try --network  host
# Adapted from here https://hub.docker.com/r/dceoy/rstudio-server/  https://github.com/dceoy/docker-rstudio-server
# Modifications:
# 1. That version used R 3.4, had trouble switching to 3.5, a key was to use ubuntu18.10
# 2. Preinstall packages needed for AIB stats project
# 
# Other relevant links
# see https://www.digitalocean.com/community/tutorials/how-to-install-r-on-ubuntu-18-04
# https://cran.r-project.org/bin/linux/debian/
# https://cran.r-project.org/bin/linux/ubuntu/README.html

# as of sep18 using 18.04 or earlier version results in the wrong cran,
# gives a long list of unmet dependencies e.g.  r-cran-zoo : Depends: r-api-3.4
FROM ubuntu:18.10

ENV DEBIAN_FRONTEND noninteractive
ENV CRAN_URL https://cloud.r-project.org/

# see https://www.digitalocean.com/community/tutorials/how-to-install-r-on-ubuntu-18-04
# https://cran.r-project.org/bin/linux/debian/
# https://cran.r-project.org/bin/linux/ubuntu/README.html
RUN set -e \
      && ln -sf /bin/bash /bin/sh \
      && apt-get -y update \
      && apt-get -y dist-upgrade \
      && apt-get -y install --no-install-recommends --no-install-suggests \
      	gnupg2 gnupg1 ca-certificates software-properties-common \
      && apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E298A3A825C0D65DFD57CBB651716619E084DAB9 \
      && add-apt-repository 'deb https://cloud.r-project.org/bin/linux/ubuntu bionic-cran35/'

#      && echo "deb https://cloud.r-project.org/bin/linux/ubuntu bionic-cran35/" >> /etc/apt/sources.list

RUN set -e \
      && apt-get -y update \
      && apt-get -y dist-upgrade \
      && apt-get -y install --no-install-recommends --no-install-suggests \
                            apt-transport-https apt-utils curl default-jdk g++ gcc gdebi-core \
                            gfortran git libapparmor1 libblas-dev libcurl4-gnutls-dev libedit2 \
                            libgtk2.0-dev libssl1.0-dev liblapack-dev libmagick++-dev \
                            libmariadb-client-lgpl-dev libglu1-mesa-dev libopenmpi-dev libpq-dev \
                            libssh2-1-dev libssl1.0-dev libxml2-dev lsb-release openmpi-bin \
                            pandoc psmisc r-base r-cran-* sudo x11-common \
      && apt-get -y autoremove \
      && apt-get clean \
      && rm -rf /var/lib/apt/lists/*

# # current version 1.1.456  ea77929e40eac30baee9e336e26a1dd5
# RUN set -e \
#       && curl -sS https://s3.amazonaws.com/rstudio-server/current.ver \
#         | xargs -I {} curl -sS http://download2.rstudio.org/rstudio-server-{}-amd64.deb -o /tmp/rstudio.deb \
#       && gdebi -n /tmp/rstudio.deb \
#       && rm -rf /tmp/rstudio.deb

# current version 1.1.456  ea77929e40eac30baee9e336e26a1dd5
RUN set -e \
      && curl -sS http://download2.rstudio.org/rstudio-server-1.1.456-amd64.deb -o /tmp/rstudio.deb \
      && gdebi -n /tmp/rstudio.deb \
      && rm -rf /tmp/rstudio.deb

#----------------------------------------------------------------
# install packages
#----------------------------------------------------------------

RUN set -e \
      && umask u=rwx,g=rwx,o=rx \
      && R -e "\
      update.packages(ask = FALSE, repos = '${CRAN_URL}'); \
      pkgs <- c('dbplyr', 'devtools', 'docopt', 'doParallel', 'foreach', 'gridExtra', 'rmarkdown', 'tidyverse'); \
      install.packages(pkgs = pkgs, dependencies = TRUE, repos = '${CRAN_URL}'); \
      sapply(pkgs, require, character.only = TRUE);"

# needed for AIB project:
RUN set -e \
      && umask u=rwx,g=rwx,o=rx \
      && R -e "\
      update.packages(ask = FALSE, repos = '${CRAN_URL}'); \
      pkgs <- c('FSA','agricolae','rcompanion', 'effsize'); \
      install.packages(pkgs = pkgs, dependencies = TRUE, repos = '${CRAN_URL}'); \
      sapply(pkgs, require, character.only = TRUE);"

# INTENTIONALLY LEAVE OFF ONE PACKAGE TO SEE IF WE HAVE PERMISSIONS TO INSTALL IT
# command above needs wPerm
#      pkgs <- c('FSA','agricolae','rcompanion','wPerm'); \
# Try running this in rstudio:
# if(!require(wPerm)){install.packages("wPerm")}
# library(wPerm)
# if(!require(abctools)){install.packages("abctools")}
# library(abctools)


## UID/GID: Rstudio runs as root, then does a setuid(?) to the "rstudio" user.
## With this dockerfile, /etc/passwd and /etc/group have these:
##   rstudio-server:x:999:999::/home/rstudio-server:/bin/sh
##   rstudio:x:1000:1000::/home/rstudio:/bin/sh
##   ------------
##   rstudio-server:x:999:rstudio
##   rstudio:x:1000:
## The 999 group is coincidentally(?) the docker group on linux. By setting the host folder as
##   mkdir Folder;  chgrp docker Filer; chmod g+s Folder then 
## 1) Rstudio can write in the folder (group writable and same group), 
## 2) viewed from the host, created files will have uid/gid 1000:docker and rw-r-r permission.
##   They can be moved/removed, but not edited without doing a chmod g+w.


#----------------------------------------------------------------
# add the rstudio user
#----------------------------------------------------------------

RUN set -e \
      && useradd -m -d /home/rstudio -G rstudio-server rstudio \
      && echo rstudio:rstudio | chpasswd

EXPOSE 8787

# copy the dockerfile into the image to help identify 
COPY rstudio-server-aib.dockerfile /

CMD ["/usr/lib/rstudio-server/bin/rserver", "--server-daemonize=0", "--server-app-armor-enabled=0"]
