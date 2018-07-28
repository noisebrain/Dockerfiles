# example of how to bulid/run julia/knet/gpu/vgg:
#
# adapted from JuliaGPU by Tim Besard <tim.besard@gmail.com>
# 1. Avoid making an external volume, install package under /pkg inside this image/container.
#    Advantage: single file to keep track of (disadvantage: missing packages must be added on each run...)
# 2. Preinstall Images, other extra packages needed for vgg.jl, via precompile.jl
#
# NOTES
#
# docker build . -f julia064-cuda9-knet-vgg.dockerfile -t julia064-cuda9-knet-vgg
# 
# run commandline:
# docker run --runtime=nvidia  $PWD:/data  --rm julia064-cuda9-knet-vgg-img vgg.jl cat.jpg --model /data/imagenet-vgg-verydeep-16 
# with permission/uid mapping  
# (PUTTING vgg.jl IN SUBFOLDER DOES NOT WORK because this line in vgg: "PROGRAM_FILE=="vgg.jl" && main(ARGS)")
# docker run --runtime=nvidia -v $PWD:/data  --rm --user root -e NB_UID=$(id -u) -e NB_GID=100 julia064-cuda9-knet-vgg vgg.jl cat.jpg --model /data/imagenet-vgg-verydeep-16 
# 
# 
# run a shell inside the container:
# docker run --runtime=nvidia -v $PWD:/data -it --rm --entrypoint /bin/bash julia064-cuda9-knet-vgg
# Then run:   /opt/julia/usr/bin/julia vgg.jl cat.jpg --model /data/imagenet-vgg-verydeep-16 
# The imagenet-vgg-verydeep-16 must be copied into the launch folder, a symlink does not work.
#
# julia source is here (e.g.) /template/v0.6/Knet/data/mnist.jl
# e.g.   julia -e 'using Knet,Images;include(Knet.dir("data","mnist.jl"))' 
#
# Expect these errors:
# ERROR: CUDAdrv   LoadError: MethodError: no method matching dlopen(::Void)
# WARNING: CUDAnative and CUDAdrv had build errors.
# 
# strategy
# first verify it can build/run without an external volume 
# then add some extra packages (Images), avoiding python
# then add vgg (** this file)
# lastly add pyplot

FROM nvcr.io/nvidia/cuda:9.0-cudnn7-devel-ubuntu16.04



##---------------- prerequisites

WORKDIR /opt

RUN apt-get update && \
    apt-get install --yes --no-install-recommends \
                    # basic stuff
                    build-essential ca-certificates \
                    # Julia
                    cmake curl gfortran git m4 python \
                    # GPUArrays
                    libclfft-bin libclblas-bin && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

##---------------- checkout julia

RUN git clone https://github.com/JuliaLang/julia.git && \
    cd julia && \
    git checkout v0.6.4


##---------------- build

WORKDIR /opt/julia

RUN make all -j$(nproc) \
        MARCH=x86-64 \
        JULIA_CPU_TARGET=x86-64 && \
    rm -rf deps/scratch deps/srccache usr-staging


##---------------- packages

WORKDIR /opt/julia/usr/bin

ENV JULIA_PKGDIR /template

RUN ./julia -e "Pkg.init()"

ADD REQUIRE /template/v0.6

# install packages (some will fail to build, due to no GPU available during `docker build`)
RUN ./julia -e 'Pkg.resolve()' && \
    rm -rf /template/lib

##---------------- execution

# copy vgg also so it can be run one time
COPY .juliarc.jl runrc.jl precompile.jl vgg.jl cat.jpg /root/

#VOLUME /pkg
#ENV JULIA_PKGDIR /pkg
#VOLUME /data

# make the /pkg folder, is used by .juliarc, precompile stuff
# stop here: it appears to run without requiring an external volume
WORKDIR /pkg
RUN /opt/julia/usr/bin/julia /root/runrc.jl 

##---------------- install Images and other packages

RUN apt-get update && apt-get install --yes --no-install-recommends imagemagick 
RUN /opt/julia/usr/bin/julia /root/precompile.jl 

##---------------- install stuff needed for vgg

# /data will be mounted/mapped to external work directory
WORKDIR /data

RUN apt-get install --yes --no-install-recommends hdf5-tools
RUN 	/opt/julia/usr/bin/julia -e 'Pkg.add("HDF5")' && \
	/opt/julia/usr/bin/julia -e 'Pkg.add("HDF5")' && \
	/opt/julia/usr/bin/julia -e 'Pkg.add("CMakeWrapper")' 

RUN	/opt/julia/usr/bin/julia /root/vgg.jl /root/cat.jpg

ENTRYPOINT ["/opt/julia/usr/bin/julia"]
#ENTRYPOINT ["/bin/bash"]	# for debugging, or give --entrypoint argument
