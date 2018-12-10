println("running prebuild.jl")

using Pkg

# dec18 suggested workaround for a problem building MAT, comes up while running vae-mnist.jl.
# did not help, though not clear if it correctly loaded the right version
Pkg.add(PackageSpec(url="https://github.com/jheinen/GR.jl", rev = "a25a7f1"))
Pkg.add("MAT")
Pkg.build("MAT")

_pkgs = ["GZip", "ArgParse","Images","ImageMagick","IJulia","FileIO","HDF5","CMakeWrapper"]
for p in _pkgs
  Pkg.add(p)
  Pkg.build(p)
end

using GZip,ArgParse,Images,ImageMagick,IJulia,HDF5,CMakeWrapper

# pull particular versions, was needed shortly after 1.0 release
#Pkg.add(PackageSpec(url="https://github.com/denizyuret/AutoGrad.jl",rev="c3a91a8"))	# is 1.01
#Pkg.add(PackageSpec(url="https://github.com/denizyuret/Knet.jl",rev="348a2fe")) # is 1.0.0 30aug18
#Pkg.add(PackageSpec(url="https://github.com/denizyuret/Knet.jl",rev="4342175")) # is 1.0.1
#Pkg.add(PackageSpec("Knet.jl",version="1.0.1"))	# 4342175
#using Knet

Pkg.add("Knet")
Pkg.build("Knet")
using Knet

exit(0)
