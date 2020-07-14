using JGE
# using GLFW
inst = Instance("JuliaApp", VersionNumber(0, 1, 0), "JuliaEngine", VersionNumber(0, 1, 0), VersionNumber(1, 1, 109), available_layers(), available_extensions())
pdevice = available_physical_devices(inst)[1]
qf = select_queue_family(pdevice)

# exts = [Extension("VK_KHR_swapchain")]
exts = available_extensions(pdevice)
device = Device(pdevice, [], [qf], exts)
q = Queue(device, qf, 0)

window = create_window((1000, 720), "JGE", VulkanContext())
surface = create_surface(inst, window)
SwapChainSupportDetails(pdevice, surface)
# attach_debug_callback!(inst; f = default_debug_callback_c) # SEGFAULTS
