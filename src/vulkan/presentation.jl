function create_surface(cinst, window; glfw = true)
    if glfw
        surface_ptr = GLFW.CreateWindowSurface(cinst[], window, C_NULL)
    end
    
    surface_ptr
end

function has_presentation_support(physical_device, queue_index, surface)
    is_supported = Ref(VkBool32(true))
    @check vkGetPhysicalDeviceSurfaceSupportKHR(physical_device, queue_index, surface, is_supported)
    Bool(is_supported[])
end