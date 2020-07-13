function available_queue_families(device)
    qf_count = Ref{UInt32}(0)
    vkGetPhysicalDeviceQueueFamilyProperties(device, qf_count, C_NULL)
    # vkGetPhysicalDeviceQueueFamilyProperties(C_NULL, qf_count, C_NULL)
    qf_props = Array{VkQueueFamilyProperties}(undef, qf_count[])
    vkGetPhysicalDeviceQueueFamilyProperties(device, qf_count, qf_props)
    return qf_props
end

function select_queue_family(physical_device; predicate = qf->qf.queueFlags & VK_QUEUE_GRAPHICS_BIT)
    avail_qf = available_queue_families(physical_device)
    for (index, qf) in enumerate(avail_qf)
        # @warn Bool(predicate(qf))
        if Bool(predicate(qf))
            return index
        end
    end
    throw(ErrorException("No suitable queue family found"))
end


function create_queue_info(queue_family_index; queue_count = 1, queue_priorities = [1.0])
    cqueue_info = Container(Ref(VkDeviceQueueCreateInfo(VK_STRUCTURE_TYPE_DEVICE_QUEUE_CREATE_INFO, C_NULL, 0, queue_family_index, queue_count, Base.unsafe_convert(Ptr{Float32}, Array{Float32,1}(queue_priorities)))), [queue_priorities])

    cqueue_info
end