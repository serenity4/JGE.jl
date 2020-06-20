module JGE

using GLFW, VulkanCore

include("core/glfw.jl")
include("core/keymaps.jl")
include("core/vulkan.jl")

function main(;context::AbstractContext = OpenGLContext())
    run_window((1000, 720); key_callback = main, context = context)
end

export main, OpenGLContext, VulkanContext

end # module