using JGE
using SafeTestsets
using Test

@safetestset "Core" begin include("core/runtests.jl") end
@safetestset "Utils" begin include("utils/runtests.jl") end
