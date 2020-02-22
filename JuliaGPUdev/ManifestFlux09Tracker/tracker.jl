using Flux, Tracker

track(m) = fmap(x -> x isa AbstractArray ? Tracker.param(x) : x, m)

model = Chain(Dense(10, 5, relu), Dense(5, 2), softmax) |> track

gs = Tracker.gradient(params(model)) do
  Flux.mse(model(rand(10)), rand(2))
end

IdDict(p=>gs[p] for p in params(model))
