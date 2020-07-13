function create_logical_device(physical_device::VkPhysicalDevice, cqueue_infos::Container; features = nothing)
    device_ref = Ref{VkDevice}()
    if isnothing(features)
        features = Ref(VkPhysicalDeviceFeatures(values(DEFAULT_VK_PHYSICAL_DEVICE_FEATURES)...))
    end
    queue_infos = cqueue_infos[]
    @warn "VkDeviceCreateInfo"
    cdevice_info = @safe_contain Ref(VkDeviceCreateInfo(VK_STRUCTURE_TYPE_DEVICE_CREATE_INFO, C_NULL, 0, length(queue_infos), unsafe_pointer(queue_infos), 0, C_NULL, 0, C_NULL, unsafe_pointer(features)))
    append!(cdevice_info.deps, cqueue_infos.deps)
    @warn "vkCreateDevice"
    return
    @vkcheck vkCreateDevice(physical_device, cdevice_info[], C_NULL, device_ref)
    @warn "Device created"
    cdevice = Container(device_ref[], [cdevice_info, cqueue_infos])
    finalizer(x->vkDestroyDevice(x[], C_NULL), cdevice)
    @warn "Return"

    cdevice
end