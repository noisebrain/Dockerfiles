# 1) docker build . -f julia064-cuda92-extvol-knet-vgg.dockerfile -t julia064-cuda92-extvol-knet-vgg
# 2) docker volume ls, remove anything leftover
# 
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
# docker run --runtime=nvidia -v /juliapkgsV06:/pkg  -v $PWD:/data -it --rm --entrypoint /bin/bash julia064-cuda92-extvol-knet-vgg
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

#FROM nvidia/cuda:8.0-cudnn7-devel-ubuntu16.04
#FROM nvcr.io/nvidia/cuda:9.0-cudnn7-devel-ubuntu16.04
FROM nvcr.io/nvidia/cuda:9.2-cudnn7-devel-ubuntu16.04




## checkout

WORKDIR /opt

RUN apt-get update && \
    apt-get install --yes --no-install-recommends \
                    # basic stuff
                    build-essential ca-certificates \
                    # Julia
                    cmake curl wget gfortran git m4 python2.7 imagemagick \
                    # GPUArrays
                    libclfft-bin libclblas-bin && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*


## JULIA

WORKDIR /opt/julia
ENV JULIA_VERSION=0.6.4
ARG JULVER=0.6

# 0.6.4:     echo "d20e6984bcf8c3692d853a9922e2cf1de19b91201cb9e396d9264c32cebedc46 *julia-${JULIA_VERSION}-linux-x86_64.tar.gz" | sha256sum -c - && \
# 0.7.0:     echo "35211bb89b060bfffe81e590b8aeb8103f059815953337453f632db9d96c1bd6 *julia-${JULIA_VERSION}-linux-x86_64.tar.gz" | sha256sum -c - && \
# 1.0.0:     echo "bea4570d7358016d8ed29d2c15787dbefaea3e746c570763e7ad6040f17831f3 *julia-${JULIA_VERSION}-linux-x86_64.tar.gz" | sha256sum -c - && \

RUN mkdir /opt/julia-${JULIA_VERSION} && \
    cd /tmp && \
    wget -q https://julialang-s3.julialang.org/bin/linux/x64/`echo ${JULIA_VERSION} | cut -d. -f 1,2`/julia-${JULIA_VERSION}-linux-x86_64.tar.gz && \
    echo "d20e6984bcf8c3692d853a9922e2cf1de19b91201cb9e396d9264c32cebedc46 *julia-${JULIA_VERSION}-linux-x86_64.tar.gz" | sha256sum -c - && \
    tar xzf julia-${JULIA_VERSION}-linux-x86_64.tar.gz -C /opt/julia-${JULIA_VERSION} --strip-components=1 && \
    rm /tmp/julia-${JULIA_VERSION}-linux-x86_64.tar.gz
RUN ln -fs /opt/julia-*/bin/julia /usr/local/bin/julia

# it unpacks into /opt/julia-${JULIA_VERSION} , ../bin/julia is the executable

# compile from source
#RUN git clone https://github.com/JuliaLang/julia.git && \
#    cd julia && \
#    git checkout v${JULIA_VERSION}
#
# RUN make all -j$(nproc) \
#         MARCH=x86-64 \
#         JULIA_CPU_TARGET=x86-64 && \
#     rm -rf deps/scratch deps/srccache usr-staging

## packages

WORKDIR /opt/julia-${JULIA_VERSION}/bin

# /template is the default value for this env variable
ENV JULIA_PKGDIR /template
RUN ./julia -e "Pkg.init()"
ADD REQUIRE /template/v${JULVER}
#
# install packages (some will fail to build, due to no GPU available during `docker build`)
# i.e. during run, nvidia docker is used, but I guess no way to use this during build
# julia1.0.0: Pkg.resolve does not exist
RUN ./julia -e 'Pkg.resolve()' && rm -rf /template/lib

##---------------- execution

# copy vgg also so it can be run one time
#COPY .juliarc.jl runrc.jl precompile.jl vgg.jl cat.jpg /root/

# in order to build version that does not use external volume, comment out next line
VOLUME /pkg
ENV JULIA_PKGDIR /pkg

VOLUME /data
WORKDIR /data

# no longer:
#RUN /usr/local/bin/julia /root/precompile.jl 
#RUN /usr/local/bin/julia /root/runrc.jl 

ENTRYPOINT ["/usr/local/bin/julia"]
