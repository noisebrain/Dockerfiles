# version for julia1.0.2
println("running prebuild.jl")

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

# julia version 1.0.2: load imagemagick first, due to zlib version error
_pkgs = ["ImageMagick", "GZip", "ArgParse","Images","IJulia","FileIO","HDF5","MAT","CMakeWrapper"]
for p in _pkgs
  Pkg.add(p)
  Pkg.build(p)
end

using ImageMagick,GZip,ArgParse,Images,IJulia,HDF5,MAT,CMakeWrapper

# pin particular versions, was needed shortly after 1.0 release
#Pkg.add(PackageSpec(url="https://github.com/denizyuret/AutoGrad.jl",rev="c3a91a8"))	# is 1.01
Pkg.add(PackageSpec(name="AutoGrad",version="1.0.1"))	
#Pkg.add(PackageSpec(url="https://github.com/denizyuret/Knet.jl",rev="348a2fe")) # is 1.0.0 30aug18
#Pkg.add(PackageSpec(url="https://github.com/denizyuret/Knet.jl",rev="4342175")) # is 1.0.1
Pkg.add(PackageSpec(name="Knet",version="1.0.1"))	# 4342175

using Knet
# v1.0.1 segfaults on rnn test, but others were passing
Pkg.test("Knet")	#  Building the CUDAnative run-time library for your sm_61 device, this might take a while...
#Pkg.build("Knet")


using IJulia
notebook()
Pkg.add("Conda")
using Conda
Conda.add("jupyterlab") # runs conda install -y jupyterlabw


exit(0)
