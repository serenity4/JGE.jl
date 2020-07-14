function create_surface(instance::Instance, window::GLFW.Window)
    surface_ptr = GLFW.CreateWindowSurface(instance.handle, window, C_NULL)
    Surface(instance, surface_ptr)
end