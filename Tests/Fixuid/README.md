# FIXUID script for docker 

Commonly we want to install an executable (R,Julia) as root, then preinstall some packages
as user, such that the user can delete packages or add new ones when the container is run.
It appears that the only was to do this are
1. have each user build their own docker images, passing build args to create the correct user uid/gid
2. run a chown process at every container startup.

The FIXUID script causes files that are created in the container run to have any desired uid/gid.
However, it does not alter files that were created during the build.

Actually, just running the container with -u uid:gid appears to have the same effect!

Thus it does not appear to help the problem of having add-on packages (for julia,R) owned by the user running the container.

https://boxboat.com/2017/07/25/fixuid-change-docker-container-uid-gid/
https://github.com/boxboat/fixuid
