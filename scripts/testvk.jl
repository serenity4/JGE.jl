using JGE
# JGE.main()

inst = Instance("JuliaApp", VersionNumber(0, 1, 0), "JuliaEngine", VersionNumber(0, 1, 0), VersionNumber(1, 0, 0), available_layers(), available_extensions())
devices = available_physical_devices(inst)