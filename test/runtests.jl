using JGE
using SafeTestsets
using Test

@testset "Core" begin include("core/runtests.jl") end
@testset "Utils" begin include("utils/runtests.jl") end
