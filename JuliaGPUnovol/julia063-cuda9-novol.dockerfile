# docker build . -f julia063-cuda9-novol.dockerfile -t julia063-cuda9-novol
# docker run --runtime=nvidia -v $PWD:/data -it --rm julia063-cuda9-novol
#
# adapted from JuliaGPU by Tim Besard <tim.besard@gmail.com>
# 1. Avoid making an external volume, install package under /pkg inside this image/container.
#    Advantage: single file to keep track of (disadvantage: missing packages must be added on each run...)
# 2. Add a few extra packages, via precompile.jl 
# 
# future strategy
# first verify it can build/run without an external volume ** this file
# then add some extra packages, avoiding python
# then try to add vgg
# lastly add pyplot

FROM nvcr.io/nvidia/cuda:9.0-cudnn7-devel-ubuntu16.04



## checkout

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

RUN git clone https://github.com/JuliaLang/julia.git && \
    cd julia && \
    git checkout v0.6.3


## build

WORKDIR /opt/julia

RUN make all -j$(nproc) \
        MARCH=x86-64 \
        JULIA_CPU_TARGET=x86-64 && \
    rm -rf deps/scratch deps/srccache usr-staging


## packages

WORKDIR /opt/julia/usr/bin

ENV JULIA_PKGDIR /template

RUN ./julia -e "Pkg.init()"

ADD REQUIRE /template/v0.6

# install packages (some will fail to build, due to no GPU available during `docker build`)
RUN ./julia -e 'Pkg.resolve()' && \
    rm -rf /template/lib


## execution

COPY .juliarc.jl precompile.jl /root/

#VOLUME /pkg
#ENV JULIA_PKGDIR /pkg
#VOLUME /data

# make the /pkg folder, is used by .juliarc, precompile stuff
WORKDIR /pkg
RUN /opt/julia/usr/bin/julia /root/precompile.jl 


# /data will be mounted/mapped to external work directory
WORKDIR /data

ENTRYPOINT ["/opt/julia/usr/bin/julia"]
#ENTRYPOINT ["/bin/bash"]	# for debugging
