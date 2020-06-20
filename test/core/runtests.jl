ENV["JULIA_DEBUG"] = "info"
@testset "GLFW" begin include("glfw.jl") end
@testset "Vulkan" begin include("vulkan.jl") end
