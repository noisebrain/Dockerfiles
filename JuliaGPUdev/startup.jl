println("................startup.jl................")
#ENV["LD_LIBRARY_PATH"] = ENV["LD_LIBRARY_PATH"]*":/root/.julia/packages/Conda/m7vem/deps/usr/lib"
println(ENV["LD_LIBRARY_PATH"])

#if !isdir("/root/.julia/packages")
#  run(`cp -r /PREBUILT /root/.julia`)
#end
