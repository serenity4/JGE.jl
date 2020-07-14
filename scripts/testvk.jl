using JGE
# using GLFW
inst = Instance("JuliaApp", VersionNumber(0, 1, 0), "JuliaEngine", VersionNumber(0, 1, 0), VersionNumber(1, 1, 109), available_layers(), available_extensions())

# attach_debug_callback!(inst; f = default_debug_callback_c) # SEGFAULTS
pdevice = available_physical_devices(inst)[1]
qf = select_queue_family(pdevice)
device = Device(pdevice, [], [qf], [])