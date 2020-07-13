# JGE.initialize(glfw = true, debug = false)
# JGE.test(debug = true)

inst = Instance("JuliaApp", VersionNumber(0, 1, 0), "JuliaEngine", VersionNumber(0, 1, 0), VersionNumber(1, 0, 0), ["VK_LAYER_MESA_overlay"], ["VK_EXT_display_surface_counter"])
inst = Instance("JuliaApp", VersionNumber(0, 1, 0), "JuliaEngine", VersionNumber(0, 1, 0), VersionNumber(1, 0, 0), available_layers(), available_extensions())
