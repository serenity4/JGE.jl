
include("$(@__FILE__)/../src/utils/containers.jl")

c1 = Container("hello", [1, 5])
c2 = Container("myboy", ["hjo", "hi"])

c3 = append!(c1, c2)
c4 = append!(c2, c1)
