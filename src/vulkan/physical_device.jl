struct PhysicalDevice <: Handle
    name::AbstractString
    api_version::VersionNumber
    driver_version::VersionNumber
    vendor_id::UInt32
    device_id::UInt32
    device_type::VkPhysicalDeviceType
    pipeline_cache_uuid::AbstractString
    limits::VkPhysicalDeviceLimits
    sparse_properties::VkPhysicalDeviceSparseProperties
    handle::VkPhysicalDevice
end

function Base.show(io::IO, pdevice::PhysicalDevice)
    println(io, "Physical device $(pdevice.name)")
    println(io, " ↪ $(pdevice.device_type)")
    println(io, " ↪ Driver: $(pdevice.driver_version)")
    print(io, " ↪ Supported Vulkan API: $(pdevice.api_version)")
end

function Base.convert(T::Type{PhysicalDevice}, device::VkPhysicalDevice)
    dp = properties(device)
    PhysicalDevice(int_to_str(dp.deviceName), int_to_version(dp.apiVersion), int_to_version(dp.driverVersion), dp.vendorID, dp.deviceID, dp.deviceType, int_to_str(dp.pipelineCacheUUID), dp.limits, dp.sparseProperties, device)
end

function properties(device::VkPhysicalDevice)
    device_props = Ref{VkPhysicalDeviceProperties}()
    vkGetPhysicalDeviceProperties(device, device_props)
    return device_props[]
end

function available_physical_devices(inst::Instance)
    device_count = Ref{UInt32}(0)
    @check vkEnumeratePhysicalDevices(inst.handle, device_count, C_NULL)
    devices = Array{VkPhysicalDevice}(undef, device_count[])
    @check vkEnumeratePhysicalDevices(inst.handle, device_count, devices)
    return Base.convert.(PhysicalDevice, devices)
end
