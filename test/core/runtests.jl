using JGE
using SafeTestsets
using Test

@safetestset "New" begin include("new.jl") end
@testset "GLFW" begin include("glfw.jl") end
