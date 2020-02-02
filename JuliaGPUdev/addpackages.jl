# TODO add all the non-gpu packages as part of the docker build,
# include only the gpu packages here.
# That will also make the base image in common with Flux/Knet/other

println("running addpackages.jl")  # renamed from prebuild.jl

using Pkg

# dec18 suggested workaround for a problem building MAT, comes up while running vae-mnist.jl.
# did not help, though not clear if it correctly loaded the right version
# seems to always report loading 0.36...
# Pkg.add(PackageSpec(url="https://github.com/jheinen/GR.jl", version="0.35.0"))
# 
# FAILS HERE.  THIS IS NOT NECESSARY FOR KNET, BUT NEEDED FOR VAE EXAMPLE
# SPECIFICALLY, LOADING imagenet.jl CAUSES THIS. HOWEVER VAE-MNIST.jl DOES NOT NEED THIS.
# Pkg.add("MAT")
# Pkg.build("MAT")
# using MAT

# can also do this as a commandline e.g.
#	!julia -e 'using Pkg; pkg"add IJulia; add Pyplot; precompile"'
# Do that in the docker build for packages that do not use the GPU.
# Unfortunately cannot run in the docker build if adding packages that need to find the GPU,
# unless nvidia-docker can be used for the build?
#=
_pkgs = ["GZip", "ArgParse","Images","ImageMagick","Colors","IJulia","PyPlot", "Plots", "FileIO","HDF5","MAT","CMakeWrapper", "Random", "Statistics"]	# BSON
for p in _pkgs
  Pkg.add(p)
  Pkg.build(p)
end
using GZip,ArgParse,Images,ImageMagick,Colors,IJulia,PyPlot,FileIO,HDF5,MAT,CMakeWrapper,Random,Statistics
=#

# pull particular versions, was needed shortly after 1.0 release
#Pkg.add(PackageSpec(url="https://github.com/denizyuret/AutoGrad.jl",rev="c3a91a8"))	# is 1.01
#Pkg.add(PackageSpec(url="https://github.com/denizyuret/Knet.jl",rev="348a2fe")) # is 1.0.0 30aug18
#Pkg.add(PackageSpec(url="https://github.com/denizyuret/Knet.jl",rev="4342175")) # is 1.0.1
#Pkg.add(PackageSpec(name="Knet",version="1.0.1"))	# 4342175
#using Knet

# for julia1.3.0/knet132, 21dec19 needed to edit test/conv.jl, change @test_broken to @test on lines 62,67
# otherwise it says "passed unexpectedly" but it errors
#        @test_broken gradcheck(pool, ax; kw=[(:padding,1)])
# This was weird because nothing in Knet had changed, though maybe was some other package 

if true
  Pkg.add("Knet")
  Pkg.test("Knet")	#  Building the CUDAnative run-time library for your sm_61 device, this might take a while...
#Pkg.build("Knet")
  using Knet
  # adding this after in order to let Knet pick a specific version
  Pkg.add("AutoGrad")
  using AutoGrad
else
  #Pkg.add(PackageSpec(name = "Flux",version="0.9"))
  Pkg.add(PackageSpec(name = "Flux",version="0.8.3"))
  Pkg.add("MetalHead")
end

# jan20 do not add Colors,Images,Distributions -
# causes a conflict with Flux0.9/Metalhead, 
# install Flux first metalhead and then install these

_pkgs = ["Images","ImageMagick","FileIO","HDF5","MAT","BSON","Colors","Random","Distributions","Statistics","KernelDensity","GZip","ArgParse","Printf","Plots","PyPlot","CMakeWrapper"]
for p in _pkgs
  Pkg.add(p)
  Pkg.build(p)
end
using Images,ImageMagick,FileIO,HDF5,MAT,BSON,Colors,Random,Distributions,Statistics,KernelDensity,GZip,ArgParse,Printf,Plots,PyPlot,CMakeWrapper


using IJulia
Pkg.add("Conda")
using Conda
Conda.add("jupyterlab") # runs conda install -y jupyterlabw

notebook()
exit(0)
