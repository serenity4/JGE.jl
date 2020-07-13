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
include("vulkan/presentation.jl")
include("vulkan/queues.jl")
include("vulkan/logical_device.jl")

function main(;context::AbstractContext = VulkanContext())
    glfw = true
    debug = true
        # run_window((1000, 720); key_callback = main, context = context)
    window = create_window((1000, 720), "JGE", context)
    cinst, physical_device = initialize(; glfw = glfw, debug = debug)
    surface_ptr = create_surface(cinst, window, glfw = glfw)
    @info "Surface created"
    avail_qf = available_queue_families(physical_device)

        # # no queue family is found with this predicate
        # select_queue_predicate = qf->(Bool(qf.queueFlags & VK_QUEUE_GRAPHICS_BIT) && has_presentation_support(physical_device, findfirst(q->q == qf, avail_qf), surface_ptr))
        # queue_family_index = select_queue_family(select_queue_predicate, avail_qf)
        
    queue_family_index = select_queue_family(physical_device)
    cqueue_info = create_queue_info(queue_family_index)
    cqueue_infos = Container([cqueue_info[]], cqueue_info.deps)
    @info "Creating logical device"
    cdevice = create_logical_device(physical_device, cqueue_infos)
    @info "Everything ready!"
    run_window(window, window_loop(context, ()->nothing), key_callback = main_keymap)
    return nothing
    return cinst, cdevice # keep them alive until the end
end

function main_gl(; context::AbstractContext = VulkanContext())
    run_window((1000, 720), context = context, key_callback = main_keymap)
end

export main, main_gl, OpenGLContext, VulkanContext, Container, unsafe_pointer, initialize

end # module