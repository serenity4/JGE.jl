module JGE

using GLFW, VulkanCore.LibVulkan
import Base: reverse

include("utils/containers.jl")
include("utils/structures.jl")
include("core/glfw.jl")
include("core/keymaps.jl")
include("vulkan/base_extensions.jl")
include("vulkan/defaults.jl")
include("vulkan/common.jl")
include("vulkan/validation.jl")
include("vulkan/init.jl")

function main(;context::AbstractContext = OpenGLContext())
    run_window((1000, 720); key_callback = main, context = context)
end

export main, OpenGLContext, VulkanContext, Container, unsafe_pointer

end # module