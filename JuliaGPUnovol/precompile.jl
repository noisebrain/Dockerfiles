println("running precompile.jl")

using Knet

_pkgs = ["ArgParse","TextWrap","GZip"]
for p in _pkgs
  Pkg.add(p)
end

using ArgParse,TextWrap

exit(0)
