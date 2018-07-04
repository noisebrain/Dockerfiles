# adapted from datasciencenotebook version a866877 fromn 1 Apr 18
# jplewis remove R stuff, pkg.add Knet,Images, update to julia0.6.3
# julia is installed into /opt/julia/
#
# docker build . -f Dockerfile-julia063-knet-nogpu-jupyter  -t julia063-knet-nogpu-jupyter  
# to run, chmod o+rw on the working directory, then
# docker run -p 8888:8888 -it -e GRANT_SUDO=yes --user root  --mount type=bind,source="$(pwd)",target=/home/jovyan/work julia063-knet-nogpu-jupyter [start.sh bash]
# If the start.sh bash is left off, will launch the jupyter notebook interface, however bash can launch jupyter lab
# from bash > start.sh jupyter lab
#
# building --build-arg myuid=$(id -u) --build-arg mygid=$(id -g) builds an image that has _my_ uid mapped to NB_UID, cannot share image with others
# running with--rm -e NB_UID=$(id -u) -e NB_GID=$(id -g) maps NB_UID to our id, but then cannot access /opt/julia
# 
# Copyright (c) Jupyter Development Team.
# Distributed under the terms of the Modified BSD License.

#FROM jupyter/minimal-notebook
FROM jupyter/scipy-notebook

LABEL maintainer="Jupyter Project <jupyter@googlegroups.com>"

# Set when building on Travis so that certain long-running build steps can
# be skipped to shorten build time.
ARG TEST_ONLY_BUILD

USER root

# R pre-requisites.  ffmpeg needed for matplotlib anim
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    ffmpeg \
    gfortran \
    gcc && apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Julia dependencies
# install Julia packages in /opt/julia instead of $HOME
ENV JULIA_PKGDIR=/opt/julia
ENV JULIA_VERSION=0.6.3

RUN mkdir /opt/julia-${JULIA_VERSION} && \
    cd /tmp && \
    wget -q https://julialang-s3.julialang.org/bin/linux/x64/`echo ${JULIA_VERSION} | cut -d. -f 1,2`/julia-${JULIA_VERSION}-linux-x86_64.tar.gz && \
    echo "36212ed8e1c864599e9f149d884d504eee15b57b96bf918cb5b9ac35a5ab6283 *julia-${JULIA_VERSION}-linux-x86_64.tar.gz" | sha256sum -c - && \
    tar xzf julia-${JULIA_VERSION}-linux-x86_64.tar.gz -C /opt/julia-${JULIA_VERSION} --strip-components=1 && \
    rm /tmp/julia-${JULIA_VERSION}-linux-x86_64.tar.gz
RUN ln -fs /opt/julia-*/bin/julia /usr/local/bin/julia

# Show Julia where conda libraries are 
# Create JULIA_PKGDIR 
RUN mkdir /etc/julia && \
    echo "push!(Libdl.DL_LOAD_PATH, \"$CONDA_DIR/lib\")" >> /etc/julia/juliarc.jl && \
    mkdir $JULIA_PKGDIR && \
    chown $NB_USER $JULIA_PKGDIR && \
    fix-permissions $JULIA_PKGDIR

USER $NB_UID
#ARG myuid=1000
#ARG mygid=100
#USER $myuid:$mygid

# R packages including IRKernel which gets installed globally.
RUN conda install --quiet --yes \
    'rpy2=2.8*' \
    'r-base=3.4.1' \
    'r-irkernel=0.8*' \
    && \
    conda clean -tipsy && \
    fix-permissions $CONDA_DIR && \
    fix-permissions /home/$NB_USER

# Add Julia packages. Only add HDF5 if this is not a test-only build since
# it takes roughly half the entire build time of all of the images on Travis
# to add this one package and often causes Travis to timeout.
#
# Install IJulia as jovyan and then move the kernelspec out
# to the system share location. Avoids problems with runtime UID change not
# taking effect properly on the .local folder in the jovyan home dir.
#     (test $TEST_ONLY_BUILD || julia -e 'Pkg.add("HDF5")') && \
RUN julia -e 'Pkg.init()' && \
    julia -e 'Pkg.update()' && \
    julia -e 'Pkg.add("Gadfly")' && \
    julia -e 'Pkg.add("IJulia")' && \
    julia -e 'Pkg.add("Knet")' && \
    julia -e 'Pkg.add("PyPlot")' && \
    julia -e 'Pkg.add("Images")' && \
    julia -e 'Pkg.add("ImageMagick")' && \
    julia -e 'Pkg.add("FileIO")' && \
    julia -e 'Pkg.add("ArgParse")'

# Precompile Julia packages. When this is merged with above, julia jupyter kernel does not get created
RUN julia -e 'using IJulia' && \
    julia -e 'using ArgParse' && \
    julia -e 'using Knet' && \
    julia -e 'using Images' && \
    julia -e 'using FileIO' && \
    julia -e 'using Knet,Images;include(Knet.dir("data","mnist.jl"))' 

# move kernelspec out of home 
RUN mv $HOME/.local/share/jupyter/kernels/julia* $CONDA_DIR/share/jupyter/kernels/ && \
    chmod -R go+rx $CONDA_DIR/share/jupyter && \
    fix-permissions $JULIA_PKGDIR $CONDA_DIR/share/jupyter
#    rm -rf $HOME/.local && \

#USER root
# /opt/julia is owned by uid 1000. The USER command did not work?
#RUN sudo chown -R $NB_UID:$NB_GID /opt/julia
#RUN chown -R $NB_UID:$NB_GID /opt/julia
#RUN chmod -R o+r /opt/julia/lib/v0.6	# otherwise get ERROR: LoadError: SystemError: opening file /opt/julia/lib/v0.6/IJulia.ji: Permission denied

# no, this is haunted. use chrome dark reader
#RUN pip install jupyterthemes && jt -t chesterish
#RUN pip install jupyterthemes

