println("running prebuild.jl")
# todo need to add FileIO, HDF5

using Pkg

_pkgs = ["GZip", "ArgParse","Images","ImageMagick","IJulia","FileIO","HDF5","CMakeWrapper"]
for p in _pkgs
  Pkg.add(p)
  Pkg.build(p)
end

using GZip,ArgParse,Images,ImageMagick,IJulia,HDF5,CMakeWrapper

Pkg.add(PackageSpec(url="https://github.com/denizyuret/AutoGrad.jl",rev="c3a91a8"))	# is 1.01
#Pkg.add(PackageSpec(url="https://github.com/denizyuret/Knet.jl",rev="348a2fe")) # is 1.0.0 30aug18
Pkg.add(PackageSpec(url="https://github.com/denizyuret/Knet.jl",rev="4342175")) # is 1.0.1
#Pkg.add(PackageSpec("Knet.jl",version="1.0.1"))	# 4342175
using Knet

exit(0)
