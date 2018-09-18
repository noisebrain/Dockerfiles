# COMMANDLINE: dockNV  --rm -v ${PWD}:/data -v $JP/0.7:/root/.julia  julia07-gpu  mlp.jl
# FIRST RUN, COPY .julia out: dockNV -it --rm -v ${PWD}:/data --entrypoint /bin/bash julia07-gpu
# INTERACTIVE SHELL: dockNV -it --rm -v ${PWD}:/data -v $JP/0.7:/root/.julia  --entrypoint /bin/bash julia07-gpu
# JUPTYER RUN: dockNV -p 8888:8888 -it --rm -v ${PWD}:/data -v $JP/0.7:/root/.julia --entrypoint /bin/bash julia07-gpu
# docker build . -f julia07-dev-gpu.dockerfile --network host -t julia07-dev-gpu


# ----------------------------------------------------------------
# ---------------- NOTES -----------------------------------------
# ----------------------------------------------------------------
#
# adapted from dockerfile by Tim Besard <tim.besard@gmail.com>
# The main improvement is that instead of compiling from source it downloads the official installer.
# Really no other changes, and this version does not attempt to preinstall any packages.
# The original TimBesard version installed some things in /template and copied them into /Pkgs the 
# first time the container is run, so effectively that time is spent in the build process rather than in a first run.
#
# THIS VERSION INSTALLS ADDON PACKAGES INTO AN EXTERNAL VOLUME /juliapkgsV06 mapped to /pkgs 
# Previously did:   # docker volume create --name juliapkgs-vol, 
# that seems to allow it to access the volume during the build process.
# Otherwise, note that nvidia-docker is used only during the docker RUN, not the BUILD,
# and so building things that access the gpu may need to wait until the run.
#
#-Negative aspect of having an external Pkgs volume: 
# there is then _both_ the docker image and the volume to worry about.
#-Positive: when all the data is included inside, basically have to build the docker _after_
# the project is completed and one knows what packages will be included. Otherwise, 
# the extra packages(and data) not included in the docker build have to be added at each run.
#-Conclusion: use the external volume approach for general work/debugging, then make a separate
# docker image when the project is mature. Also, when experimenting with installing packages,
# make a copy of the /juliapkgsVxx folder, and can restore it later if something breaks.
# 
# NOTE for this to work, must pass -v /juliapkgsV06:/pkg 
# Otherwise, at run time it will install things in /pkg in the container, 
# but that goes away when the container exits, so would need to reinstall every time.
# 
# Also see a "novol" docker file that attempts to preinstall everything into the interal /pkg folder.

# ----------------------------------------------------------------
# ---------------- USAGE -----------------------------------------
# ----------------------------------------------------------------
#
# FIRST TIME RUN - INSTALL/COMPILE THINGS
# a) sudo mkdir /juliapkgsV06				# <- weird, seemed like it was not necessary??
# b) setenv DOCKERIMG julia064-cuda92-extvol-knet-vgg
#
#
# RUN VGG COMMANDLINE
# docker run --runtime=nvidia  -v /juliapkgsV06:/pkg -v $PWD:/data  --rm $DOCKERIMG vgg.jl cat.jpg --model /data/imagenet-vgg-verydeep-16 
# 
#
# RUN WITH PERMISSION MAPPING
# (PUTTING vgg.jl IN SUBFOLDER DOES NOT WORK because this line in vgg: "PROGRAM_FILE=="vgg.jl" && main(ARGS)")
# docker run --runtime=nvidia -v /juliapkgsV06:/pkg -v $PWD:/data  --rm --user root -e NB_UID=$(id -u) -e NB_GID=100 $DOCKERIMG vgg.jl cat.jpg --model /data/imagenet-vgg-verydeep-16 
#
#  
# ALIAS
# $ alias juliagpu='docker run --runtime=nvidia -v /juliapkgsV06:/pkg -v $PWD:/data -it --rm julia064-cuda92-extvol-knet-vgg'
#
# 
# RUN A SHELL INSIDE THE CONTAINER:
# docker run --runtime=nvidia -v /juliapkgsV100:/pkg  -v $PWD:/data -it --rm --entrypoint /bin/bash julia064-cuda92-extvol-knet-vgg
# /opt/julia/usr/bin/julia vgg.jl cat.jpg --model /data/imagenet-vgg-verydeep-16 
# ##in this case the imagenet-vgg-verydeep-16 must be copied into the launch folder, a symlink does not work.
#
# julia source is here (e.g.) /template/v0.6/Knet/data/mnist.jl
# e.g.   julia -e 'using Knet,Images;include(Knet.dir("data","mnist.jl"))' 
#
# These error does not matter?
# ERROR: CUDAdrv   LoadError: MethodError: no method matching dlopen(::Void)
# WARNING: CUDAnative and CUDAdrv had build errors.
# 
#----------------------------------------------------------------

FROM nvcr.io/nvidia/cuda:9.2-cudnn7-devel-ubuntu16.04
#FROM nvcr.io/nvidia/cuda:9.0-cudnn7-devel-ubuntu16.04
#FROM nvidia/cuda:8.0-cudnn7-devel-ubuntu16.04

MAINTAINER j.p.lewis <noisebrain@gmail.com>

ENV HOME=/root
#ENV JULIA_VERSION=1.0.0
#ARG JULVER=1.0
ENV JULIA_VERSION=0.7.0
ARG JULVER=0.7


RUN apt-get update && \
    apt-get install --yes --no-install-recommends \
                    # basic stuff
                    build-essential ca-certificates \
                    # Julia
                    curl wget gfortran git m4 zlib1g-dev imagemagick hdf5-tools && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

## ---------------- BUILD FROM SOURCE ----------------
#-WORKDIR /opt
#- RUN git clone https://github.com/JuliaLang/julia.git && \
#-     cd julia && \
#-     git checkout v${JULIA_VERSION}
#- ## build
#- WORKDIR /opt/julia
#- RUN make all -j$(nproc) \
#-         MARCH=x86-64 \
#-         JULIA_CPU_TARGET=x86-64 && \
#-     rm -rf deps/scratch deps/srccache usr-staging
#-
#-WORKDIR /opt/julia/usr/bin
#-ENV JULIAEXE=/opt/julia/usr/bin/julia


## ---------------- DOWNLOAD JULIA ----------------
# this unpacks into /opt/julia-${JULIA_VERSION} , ../bin/julia is the executable

# 0.6.4:     echo "d20e6984bcf8c3692d853a9922e2cf1de19b91201cb9e396d9264c32cebedc46 *julia-${JULIA_VERSION}-linux-x86_64.tar.gz" | sha256sum -c - && \
# 0.7.0:     echo "35211bb89b060bfffe81e590b8aeb8103f059815953337453f632db9d96c1bd6 *julia-${JULIA_VERSION}-linux-x86_64.tar.gz" | sha256sum -c - && \
# 1.0.0:     echo "bea4570d7358016d8ed29d2c15787dbefaea3e746c570763e7ad6040f17831f3 *julia-${JULIA_VERSION}-linux-x86_64.tar.gz" | sha256sum -c - && \

RUN mkdir /opt/julia-${JULIA_VERSION} && \
    cd /tmp && \
    wget -q https://julialang-s3.julialang.org/bin/linux/x64/`echo ${JULIA_VERSION} | cut -d. -f 1,2`/julia-${JULIA_VERSION}-linux-x86_64.tar.gz && \
# 1.0.0:     echo "bea4570d7358016d8ed29d2c15787dbefaea3e746c570763e7ad6040f17831f3 *julia-${JULIA_VERSION}-linux-x86_64.tar.gz" | sha256sum -c - && \
    tar xzf julia-${JULIA_VERSION}-linux-x86_64.tar.gz -C /opt/julia-${JULIA_VERSION} --strip-components=1 && \
    rm /tmp/julia-${JULIA_VERSION}-linux-x86_64.tar.gz
RUN ln -fs /opt/julia-*/bin/julia /usr/local/bin/julia

WORKDIR /usr/local/bin
ENV JULIAEXE=/usr/local/bin/julia

## packages

COPY prebuild.jl /usr/local/bin
#RUN ./julia -e 'using Pkg; Pkg.add("ArgParse")'
RUN julia prebuild.jl

#COPY prebuild2.jl /usr/local/bin
#RUN LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:/root/.julia/packages/Conda/m7vem/deps/usr/lib && julia prebuild2.jl

## configure jupyter kernel and jupyterlab
RUN mv ${HOME}/.local/share/jupyter/kernels/julia-${JULVER} ${HOME}/.julia/packages/Conda/m7vem/deps/usr/share/jupyter/kernels && /root/.julia/packages/Conda/m7vem/deps/usr/bin/conda install -y jupyterlab


## execution

VOLUME /data
WORKDIR /data

RUN echo "echo TO LAUNCH JUPYTER: /root/.julia/packages/Conda/m7vem/deps/usr/bin/jupyter lab --ip 0.0.0.0 --port 8888 --allow-root"  >> ~/.bashrc

## mv ~/.julia into /PREBUILT, then .startup.jl will copy it back to ~/.julia which is mapped to an ext volume
# Problem, this increases the size of the image by 2g.
# COPY startup.jl ${HOME}/.julia/config/startup.jl
# RUN mv ~/.julia /PREBUILT		# SLOW

# instead:
# run once, cp ~/.julia /data/JULIAPKGS
# run again with -v ${PWD}/JULIAPKGS:/root/.julia 

COPY startup.jl ${HOME}/.julia/config/startup.jl
ENTRYPOINT ["/usr/local/bin/julia"]
