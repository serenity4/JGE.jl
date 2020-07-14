mutable struct Device <: Handle
    physical_device::PhysicalDevice
    features::AbstractArray
    queues::AbstractArray
    queue_priorities::AbstractArray
    queue_infos::AbstractArray{T} where T <: VkDeviceQueueCreateInfo
    exts::AbstractArray
    vk_features::VkPhysicalDeviceFeatures
    handle::VkDevice
end

function Device(physical_device, features, queues, exts; queue_priorities = nothing)
    features_dict = copy(DEFAULT_VK_PHYSICAL_DEVICE_FEATURES)
    for feat in keys(features)
        features_dict[feat] = 1
    end
    if isnothing(queue_priorities)
        queue_priorities = repeat([1.0], length(queues))
    else
        @assert length(queue_priorities) == length(queues)
    end
    p_exts = isempty(exts) ? C_NULL : pointer(pointer.(getproperty.(exts, :name)))
    queue_priorities ./= sqrt(sum(queue_priorities.^2)) # queue priorities must be normalized
    queue_infos = VkDeviceQueueCreateInfo.(Ref(VK_STRUCTURE_TYPE_DEVICE_QUEUE_CREATE_INFO), Ref(C_NULL), Ref(0), index.(Ref(physical_device), queues), getproperty.(queues, :count), Ref(Base.unsafe_convert(Ptr{Float32}, Array{Float32,1}(queue_priorities))))
    vk_features_ref = Ref(VkPhysicalDeviceFeatures(values(features_dict)...))
    device_info = VkDeviceCreateInfo(VK_STRUCTURE_TYPE_DEVICE_CREATE_INFO, C_NULL, 0, length(queues), pointer(queue_infos), 0, C_NULL, length(exts), p_exts,  unsafe_pointer(vk_features_ref))
    device_ref = Ref{VkDevice}()
    @check vkCreateDevice(physical_device.handle, Ref(device_info), C_NULL, device_ref)
    device = Device(physical_device, features, queues, queue_priorities, queue_infos, exts, vk_features_ref[], device_ref[])
    finalizer(destroy_handle(vkDestroyDevice), device)

    device
end

function Base.show(io::IO, device::Device)
    println(io, "Logical device")
    println(io, " ↪ Physical device: $(device.physical_device.name)")
    println(io, " ↪ Features: $(device.features)")
    print(io, " ↪ Extensions: $(device.exts)")
end