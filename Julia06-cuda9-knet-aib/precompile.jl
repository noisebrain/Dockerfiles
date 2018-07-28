println("running precompile.jl")

using Knet

_pkgs = ["ArgParse","TextWrap","GZip", "ImageMagick", "Images", "FileIO"]
for p in _pkgs
  Pkg.add(p)
end

using ArgParse,TextWrap, Images, FileIO

exit(0)
