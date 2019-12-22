# dec19 updated, works
# dec18 this works, however trying to run vae-mnist fails when loading MAT, extra token error

# ---------------- TO BUILD ----------------
# 
# 	edit dockerfile:
#	edit CUDA-BASE, JULIA_VERSION, SHASUM variables
# 	if julia tar.gz is downloaded in /tmp it will be used
# 
# setenv juliaver julia130
# setenv cudaver cuda92
# setenv knetver knet132
# 
# sudo docker build . -f julia-gpu.dockerfile --network host -t ${juliaver}-${cudaver}
# sudo nvidia-docker run --rm -it --ipc=host --entrypoint /bin/bash ${juliaver}-${cudaver}
# container# /usr/local/bin/julia
# julia> include("prebuild.jl")
# todo merge this into prebuild:
# julia> using IJulia
# julia> notebook()	# causes miniconda to be downloaded
#				Pkg.add("Conda")
#				using Conda
#				Conda.add("jupyterlab") # runs conda install -y jupyterlab
#				^^^^ this worked to add jupyterlab!	
# julia> ^D
#     BACK TO HOST BASH
# docker commit bff36d4f0183 ${juliaver}-${cudaver}-${knetver}
# 
# ---------------- TO RUN ----------------
# sudo nvidia-docker run -p 8888:8888 --rm -it -v ${PWD}:/work --ipc=host --entrypoint /bin/bash ${juliaver}-${cudaver}-${knetver}
# container# cd /work;  /root/.julia/conda/3/bin/jupyter-lab --ip 0.0.0.0 --port 8888 --allow-root
# local browser go to link like http://127.0.0.1:888/?token= ...
# notebook new>

# ----------------OLD, TODO----------------
# COMMANDLINE: dockNV  --rm -v ${PWD}:/data -v $JP/0.7:/root/.julia  julia07-gpu  mlp.jl
# FIRST RUN, COPY .julia out: dockNV -it --rm -v ${PWD}:/data --entrypoint /bin/bash julia07-gpu
# 	run once, cp ~/.julia /data/JULIAPKGS
# 	run again with -v /someplace/JULIAPKGS:/root/.julia  -v ${PWD}:/data 
# INTERACTIVE SHELL: dockNV -it --rm -v ${PWD}:/data -v $JP/0.7:/root/.julia  --entrypoint /bin/bash julia07-gpu
# JUPTYER RUN: dockNV -p 8888:8888 -it --rm -v ${PWD}:/data -v $JP/0.7:/root/.julia --entrypoint /bin/bash julia07-gpu
# 

# Key problem is that "docker build" is not nvidia-docker, and so has no access to the GPU,
# thus trying to add GPU packages at build time will not work unless some tricks are done (below)
#
# ----------------------------------------------------------------
# ---------------- OLD NOTES -----------------------------------------
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

#
## mv ~/.julia into /PREBUILT, then .startup.jl will copy it back to ~/.julia which is mapped to an ext volume
# Problem, this increases the size of the image by 2g.
# COPY startup.jl ${HOME}/.julia/config/startup.jl
# RUN mv ~/.julia /PREBUILT		# SLOW
# instead:
# run once, cp ~/.julia /install/JULIAPKGS
# run again with -v ${PWD}/JULIAPKGS:/root/.julia 

# ----------------------------------------------------------------
# ---------------- OLD USAGE -----------------------------------------
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

# docker pull nvcr.io/nvidia/pytorch:19.11-py3
# CUDA-BASE
#FROM nvcr.io/nvidia/cuda:10.1-cudnn7-devel-ubuntu18.04
FROM nvcr.io/nvidia/cuda:9.2-cudnn7-devel-ubuntu16.04
#FROM nvcr.io/nvidia/cuda:9.0-cudnn7-devel-ubuntu16.04
#FROM nvidia/cuda:8.0-cudnn7-devel-ubuntu16.04
# selecting 10.1 on a machine with driver396.24/1080 card gave an error when starting container,
# "...--require=cuda>=10.1 brand=tesla,driver>=384,driver<385 brand=tesla,driver>=396,driver<397 brand=tesla,driver>=410,driver<411"

MAINTAINER j.p.lewis <noisebrain@gmail.com>

ENV HOME=/root
ENV JULIA_VERSION=1.3.0
ENV CUDA_HOME=/usr/local/cuda


RUN apt-get update && \
    apt-get install --yes --no-install-recommends \
                    # basic stuff
                    build-essential ca-certificates \
                    # Julia
                    curl nano wget gfortran git m4 zlib1g-dev imagemagick hdf5-tools && \
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

# retrieve a checksum from url like this: https://julialang-s3.julialang.org/bin/checksums/julia-1.2.0.sha256
#ENV SHASUM="d20e6984bcf8c3692d853a9922e2cf1de19b91201cb9e396d9264c32cebedc46"  #0.6.4
#ENV SHASUM="35211bb89b060bfffe81e590b8aeb8103f059815953337453f632db9d96c1bd6"  #0.7.0
#ENV SHASUM="e0e93949753cc4ac46d5f27d7ae213488b3fef5f8e766794df0058e1b3d2f142"  #1.0.2
#ENV SHASUM="926ced5dec5d726ed0d2919e849ff084a320882fb67ab048385849f9483afc47"  #1.2.0
#ENV SHASUM="9ec9e8076f65bef9ba1fb3c58037743c5abb3b53d845b827e44a37e7bcacffe8"  #1.3.0
ENV SHASUM="9ec9e8076f65bef9ba1fb3c58037743c5abb3b53d845b827e44a37e7bcacffe8" 

RUN mkdir /opt/julia-${JULIA_VERSION} && \
    cd /tmp && \
        [ -f julia-${JULIA_VERSION}-linux-x86_64.tar.gz ] || ( wget -q https://julialang-s3.julialang.org/bin/linux/x64/`echo ${JULIA_VERSION} | cut -d. -f 1,2`/julia-${JULIA_VERSION}-linux-x86_64.tar.gz ) && \
    echo "${SHASUM} *julia-${JULIA_VERSION}-linux-x86_64.tar.gz" | sha256sum -c - && \
    tar xzf julia-${JULIA_VERSION}-linux-x86_64.tar.gz -C /opt/julia-${JULIA_VERSION} --strip-components=1 && \
    rm /tmp/julia-${JULIA_VERSION}-linux-x86_64.tar.gz
RUN ln -fs /opt/julia-*/bin/julia /usr/local/bin/julia

WORKDIR /usr/local/bin
ENV JULIAEXE=/usr/local/bin/julia

## setup packages
#ARG JULVER=1.2	# not used
## configure jupyter kernel and jupyterlab  <-- worked under earlier versions, now the conda path does not exist
## RUN mv ${HOME}/.local/share/jupyter/kernels/julia-${JULVER} ${HOME}/.julia/packages/Conda/m7vem/deps/usr/share/jupyter/kernels && /root/.julia/packages/Conda/m7vem/deps/usr/bin/conda install -y jupyterlab


## execution

VOLUME /install
WORKDIR /install
COPY prebuild.jl /install
#RUN ./julia -e 'using Pkg; Pkg.add("ArgParse")'
#RUN julia prebuild.jl


RUN echo "echo TO LAUNCH JUPYTER: \"cd /work;/root/.julia/conda/3/bin/jupyter-lab --ip 0.0.0.0 --port 8888 --allow-root\""  >> ~/.bashrc

COPY startup.jl ${HOME}/.julia/config/startup.jl
COPY julia-gpu.dockerfile /install

ENTRYPOINT ["/usr/local/bin/julia"]
