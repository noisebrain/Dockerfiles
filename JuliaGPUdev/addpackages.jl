# TODO add all the non-gpu packages as part of the docker build,
# include only the gpu packages here.
# That will also make the base image in common with Flux/Knet/other

#:todo Pkg.installed is deprecated

println("running addpackages.jl")  # renamed from prebuild.jl

ENV["JULIA_CUDA_VERBOSE"] = true

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

# For recent drivers need to do this to allow cuda profiling, which is called in the test():
#=
        Create .conf file (e.g. profile.conf) in folder /etc/modprobe.d
        Open file /etc/modprobe.d/profile.conf in any editor
        Add below line in profile.conf
        options nvidia "NVreg_RestrictProfilingToAdminUsers=0"
        Close file /etc/modprobe.d/profile.conf
        Restart your machine
=#

if false
  using Pkg
  Pkg.add("Knet")
  Pkg.test("Knet")	#  Building the CUDAnative run-time library for your sm_61 device, this might take a while...
#Pkg.build("Knet")
  using Knet
  # adding this after in order to let Knet pick a specific version
  Pkg.add("AutoGrad")
  using AutoGrad
end
if true
  using Pkg
    # PICK VERSION
  	#Pkg.activate(".")
  	#Pkg.instantiate(;verbose=true)
	#Pkg.add(PackageSpec(name = "Flux",version="0.9"))
	#Pkg.add(PackageSpec(name = "Flux",version="0.8.3"))
    	Pkg.add("Flux")
  Pkg.add("CUDA") # 1080/cuda92: could not load symbol "nvmlSystemGetCudaDriverVersion_v2"
  #Pkg.build("CUDA")
  Pkg.test("CUDA")
  using CUDA
  #Pkg.add("Zygote")
  Pkg.test("Flux") # 0.9 gives 4 errors in RNN, just ignore and manually run the sequel
  using Flux
end


# suspect these are not getting added if flux test errors
if true
  Pkg.add("Metalhead")
  using Metalhead
  Pkg.add("Zygote")
  using Zygote
end

# todo add CUDAnative CUDAdrv CUDAapi ?
Pkg.add("CUDAapi"); using CUDAapi
# CUDAdrv?  https://github.com/GdMacmillan/ml_flux_tutorial/blob/master/ML_Flux_Tutorial.ipynb
# julia -e 'using Pkg; pkg"add IJulia; add CuArrays; add CUDAnative; add CUDAdrv; add Flux; add BenchmarkTools; add MLDatasets; add ImageMagick; add ImageCore; add Plots; precompile"'

Pkg.pin("Flux")
Pkg.pin("Zygote")
Pkg.pin("CUDA")
Pkg.pin("CUDAapi")


using Flux      # if the Pkg.test fails, appears that the "using" above is never invoked
using Zygote

# get Conda+PyCall setup before adding PyPlot, because it looks for matplotlib
using Pkg
Pkg.add("Conda")
using Conda
Conda.add("matplotlib")
# if building from source there is a python2 in /usr/bin, force use of the conda python3
if Sys.islinux()
  ENV["PYTHON"] = "/root/.julia/conda/3/bin/python3"	
end
Pkg.add("PyCall")
Pkg.build("PyCall")
using PyCall
@assert PyCall.conda == true

# jan20 do not add Colors,Images,Distributions -
# causes a conflict with Flux0.9/Metalhead, 
# install Flux first metalhead and then install these

function addusing(pkgs)
  for p in pkgs
    #Pkg.installed(p)==nothing && Pkg.add(p)
    if !in(p, keys(Pkg.installed()))
      Pkg.add(p)
    end
    #Pkg.build(p)
    eval(quote using $(Symbol(p)) end) 
  end
end

_pkgs = ["Images","ImageMagick","FileIO","HDF5","MAT","NPZ","BSON","MLDatasets","DataFrames","CSV","Colors","Random","Distributions","Statistics","StatsBase", "KernelDensity","Distances","FiniteDifferences","GZip","ArgParse","Printf","Plots","PyPlot","CMakeWrapper","Parameters","Logging", "TensorBoardLogger","Literate","ProgressMeter","DrWatson","Revise","Pluto","Metalhead"]

addusing(_pkgs)

# HERE PICK EITHER JUPYTER OR JUNO
#---------------- jupyter ----------------

_pkgs = ["IJulia", "WebIO"] # MeshCat
# "MeshCat" does not build on 1.5: IOError: could not spawn `unzip -x /tmp/jl_LmztJ1/meshcat.zip -d /tmp/jl_LmztJ1`: no such file or directory 
addusing(_pkgs)
using IJulia
#Pkg.add("Conda")	# added above
#using Conda


# BEGIN-JUPYTERLAB-BROKEN
error("run the jupyterlab step manually")
# either run ~/.julia/conda/3/bin/conda install -y jupyterlab
# OR
# run WebIO.install_jupyter_labextension() and say "Y" when it asks to install
Conda.add("jupyterlab") # runs conda install -y jupyterlab
#
# conda install -y nodejs
using WebIO
WebIO.install_jupyter_labextension()
# END-JUPYTERLAB-BROKEN

notebook()
println("REPL pkg manager run precompile!")
println("now run setupemacskeys.sh if you like")


#---------------- or atom/juno ----------------
_pkgs = ["CSTParser", "Atom", "Juno"]
addusing(_pkgs)

Pkg.status()

# pre-download mnist
MLDatasets.FashionMNIST.traindata(Float32)
MLDatasets.MNIST.traindata(Float32)

exit(0)
