struct QueueFamily
    flags::UInt32
    count::Integer
    timestamp_valid_bits::UInt32
    min_image_transfer_granularity::VkExtent3D
end

struct Queue <: Handle
    device::Device
    handle::VkQueue
end

function Queue(device::Device, qf_index::Integer, q_index::Integer)
    queue_ref = Ref{VkQueue}()
    vkGetDeviceQueue(device.handle, qf_index, q_index, queue_ref)

    Queue(device, queue_ref[])
end

Queue(device::Device, qf::QueueFamily, q_index::Integer) = Queue(device, index(device.physical_device, qf), q_index)


Base.convert(T::Type{QueueFamily}, vk_qf::VkQueueFamilyProperties) = QueueFamily(vk_qf.queueFlags, vk_qf.queueCount, vk_qf.timestampValidBits, vk_qf.minImageTransferGranularity)
Base.length(v::QueueFamily) = 1
Base.iterate(v::QueueFamily) = v, nothing
Base.iterate(v::QueueFamily, state::Nothing) = nothing

function index(device::PhysicalDevice, qf::QueueFamily)
    return findfirst(available_queue_families(device) .== qf)
end

function available_queue_families(device::PhysicalDevice)
    qf_count = Ref{UInt32}(0)
    vkGetPhysicalDeviceQueueFamilyProperties(device.handle, qf_count, C_NULL)
    # vkGetPhysicalDeviceQueueFamilyProperties(C_NULL, qf_count, C_NULL)
    qf_props = Array{VkQueueFamilyProperties}(undef, qf_count[])
    vkGetPhysicalDeviceQueueFamilyProperties(device.handle, qf_count, qf_props)
    return Base.convert.(Ref(QueueFamily), qf_props)
end

function select_queue_family(physical_device::PhysicalDevice; predicate = qf->Bool(qf.flags & VK_QUEUE_GRAPHICS_BIT))
    avail_qf = available_queue_families(physical_device)
    index = findfirst(map(predicate, avail_qf))
    if isnothing(index)
        throw(ErrorException("No suitable queue family found"))
    end
    avail_qf[index]
end


function create_queue_info(queue_family_index; queue_count = 1, queue_priorities = [1.0])
    cqueue_info = Container(Ref(VkDeviceQueueCreateInfo(VK_STRUCTURE_TYPE_DEVICE_QUEUE_CREATE_INFO, C_NULL, 0, queue_family_index, queue_count, Base.unsafe_convert(Ptr{Float32}, Array{Float32,1}(queue_priorities)))), [queue_priorities])

    cqueue_info
end