# docker build . -f test-uid.dockerfile -t test-uid
# docker run -it --rm -e NB_UID=$(id -u) -e NB_GID=$(id -g) -e GRANT_SUDO=yes [--user root]  --mount type=bind,source="$(pwd)",target=/data test-uid

# http://www.inanzzz.com/index.php/post/dna6/unning-docker-container-with-a-non-root-user-and-fixing-shared-volume-permissions-with-gosu

# conclusion: the --user affects only the 'docker run' container process
# the USER command inside the dockerfile affects the files that are created during the build,
# AND, the USER that is active when the build is over will be the user for the container run,
# UNLESS overridden by --user uid:gid on the command line
# any files created in the build are not changed by --user


FROM ubuntu:18.10

USER root
RUN echo `id`

#WORKDIR /systemdata
RUN mkdir /systemdata
RUN echo TESTING1 > /systemdata/CREATEDFILE1

RUN mkdir /userdata && chmod go+rw /userdata

ARG myuid=504
ARG mygid=20
# the container will be running as this, unless overridden with --user
RUN groupadd appuser -g 1001 && useradd -u 1001 -g appuser appuser
USER appuser
#USER $myuid:$mygid	

#WORKDIR /userdata
RUN echo TESTING2 > /userdata/CREATEDFILE2

WORKDIR /data

