# this dockerfile launches rstudio server, can attach to it from the browser, nice!
#   docker container run --rm -p 8787:8787 -u $(id -u):9955 -v ${PWD}:/home/rstudio -w /home/rstudio rstudio-server-aib
#   in browser:  localhost:8787
# docker build . -f rstudio-server-aib.dockerfile -t rstudio-server-aib
# Adapted from here https://hub.docker.com/r/dceoy/rstudio-server/  https://github.com/dceoy/docker-rstudio-server
# Modifications:
# 1. That version used R 3.4, had trouble switching to 3.5, a key was to use ubuntu18.10
# 2. Preinstall packages needed for AIB stats project
# 
# Other relevant links
# see https://www.digitalocean.com/community/tutorials/how-to-install-r-on-ubuntu-18-04
# https://cran.r-project.org/bin/linux/debian/
# https://cran.r-project.org/bin/linux/ubuntu/README.html

# using 18.04 or earlier version results in the wrong cran,
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
      pkgs <- c('FSA','agricolae','rcompanion'); \
      install.packages(pkgs = pkgs, dependencies = TRUE, repos = '${CRAN_URL}'); \
      sapply(pkgs, require, character.only = TRUE);"

# INTENTIONALLY LEAVE OFF ONE PACKAGE TO SEE IF WE HAVE PERMISSIONS TO INSTALL IT
# command above needs wPerm
#      pkgs <- c('FSA','agricolae','rcompanion','wPerm'); \

#----------------------------------------------------------------
# switch user - does not allow login!
# linux:  
# - if host folder is go-w get (Permission denied) [path=/home/rstudio/.rstudio,
# - with go+w can run with default uid, created files show as 1000:1000 on the host
# - with new groupadd code, gid gets set to 999, maybe 9955 was too high, but worked.
#   uid 9955/9955 created files on host have 9955:999 = 9955:docker  ->  docker is 999 group
# - with uid/gid both 987, gives invalid uname/passwd.  also when uid/gid = 980/987
# - passing commandline arg -u $(id -u):9955 gives invalid psw
#----------------------------------------------------------------

ARG myuid=9955
ARG mygid=9955
# the container will be running as this, unless overridden with --user
RUN set -e \
	groupadd rstudio-server -g $mygid && useradd -m -d /home/rstudio -u $myuid -g rstudio-server rstudio \
	&& echo rstudio:rstudio | chpasswd
# USER rstudio	<- cannot login when this is added!!

# originally:
#RUN set -e \
#      && useradd -m -d /home/rstudio -G rstudio-server rstudio \
#      && echo rstudio:rstudio | chpasswd


# on the linux host, do this one-time setup:
# sudo groupadd duckuser -g 9955 && sudo adduser  zilla duckuser  # and logout/in.  
# or: sudo usermod -a -G duckuser zilla
# to clean up later: sudo deluser user group 

EXPOSE 8787

#----------------------------------------------------------------

CMD ["/usr/lib/rstudio-server/bin/rserver", "--server-daemonize=0", "--server-app-armor-enabled=0"]
