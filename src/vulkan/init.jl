
struct NotFoundError <: Exception
    msg
end


Base.showerror(io::Core.IO, e::NotFoundError) = print(io, "NotFoundError: $(e.msg)")

function convert(field::NTuple{256,UInt8}, ::Type{String})
    return String(filter(x->x != 0, UInt8[field...]))
end

function String(field::NTuple{256,UInt8})
    return String(filter(x->x != 0, UInt8[field...]))
end


toversion(version::Cuint) = VersionNumber(VK_VERSION_MAJOR(version),
										  VK_VERSION_MINOR(version),
										  VK_VERSION_PATCH(version))

function Base.show(io::IO, pdp::VkPhysicalDeviceProperties)
	println(io, "Physical Device Properties: ")
	println(io, "    API Version: ", toversion(pdp.apiVersion))
	println(io, "    Driver Version: ", toversion(pdp.driverVersion))

	println(io, "    Vendor ID ", pdp.vendorID)
	println(io, "    Device ID: ", pdp.deviceID)
	println(io, "    Device Type: ", pdp.deviceType)
	println(io, "    Device Name: ", String(pdp.deviceName))
	println(io, "    Pipeline Cache UUID: ", String(collect(pdp.pipelineCacheUUID)))
	println(io, "    Limits: ", pdp.limits)
	println(io, "    Sparse Properties: \n    ", pdp.sparseProperties)
end

function create_appinfo(; name = "Vulkan Instance", exts = C_NULL, version = VK_MAKE_VERSION(0, 0, 1), engine_name = "NoEnngine", engine_version = VK_MAKE_VERSION(0, 0, 1), api_version = VK_API_VERSION_1_0())
    app_info = VkApplicationInfo(VK_STRUCTURE_TYPE_APPLICATION_INFO, exts, pointer(name), version, pointer(engine_name), engine_version, api_version)
    return app_info
end

function available_extensions()
    ext_names = GLFW.GetRequiredInstanceExtensions()
    avail_exts_count = Ref{UInt32}()
    @vkcheck vkEnumerateInstanceExtensionProperties(C_NULL, avail_exts_count, C_NULL)
    avail_exts = Array{VkExtensionProperties}(undef, avail_exts_count[])
    @vkcheck vkEnumerateInstanceExtensionProperties(C_NULL, avail_exts_count, avail_exts)
    return avail_exts
end

function available_layers()
    layer_count = Ref{UInt32}(0)
    @vkcheck vkEnumerateInstanceLayerProperties(layer_count, C_NULL)
    avail_layers = Array{VkLayerProperties}(undef, layer_count[])
    @vkcheck vkEnumerateInstanceLayerProperties(layer_count, avail_layers)
    return avail_layers
end

function check_extensions(ext_names::AbstractArray{T} where T <: AbstractString, avail_exts)
    avail_ext_names = map(x->convert(x.extensionName, String), avail_exts)
    @assert issubset(ext_names, avail_ext_names) "The following extensions are not available: $(symdiff(intersect(avail_layer_names, layer_names), layer_names))"
end

function check_layers(layer_names::AbstractArray{T} where T <: AbstractString, avail_layers)
    avail_layer_names = map(x->convert(x.layerName, String), avail_layers)
    @assert issubset(layer_names, avail_layer_names) "The following layers are not available: $(symdiff(intersect(avail_layer_names, layer_names), layer_names))"
end

@inline function required_extensions(glfw, debug)
    avail_exts = available_extensions()
    ext_names = []
    if glfw
        ext_names = [ext_names..., GLFW.GetRequiredInstanceExtensions()...]
    end
    if debug
        push!(ext_names, "VK_EXT_debug_utils")
    end
    if ext_names != []
        check_extensions(ext_names, available_extensions())
        @debug "Enabled extensions:$(map(x->"\n          $x", ext_names)...)"
        exts = Base.unsafe_convert(Ptr{Cstring}, pointer.(ext_names))
        return exts, length(ext_names)
    else
        return C_NULL, 0
    end
end

@inline function required_layers(debug)
    layer_names = []
    if debug
        push!(layer_names, "VK_LAYER_KHRONOS_validation")
    end
    if layer_names != []
        check_layers(Vector{String}(layer_names), available_layers())
        @debug "Enabled layers:$(map(x->"\n          $x", layer_names)...)"
        layers = Base.unsafe_convert(Ptr{Cstring}, pointer.(layer_names))
        layers_count = length(layers)
    else
        layers = C_NULL
        layers_count = 0
    end
    return layers, layers_count
end

function create_instance(; glfw = true, debug = true)
    app_info_ref = Ref(create_appinfo())
    exts, exts_count = required_extensions(glfw, debug)
    layers, layers_count = required_layers(debug)
    info = @safe_contain VkInstanceCreateInfo(VK_STRUCTURE_TYPE_INSTANCE_CREATE_INFO, C_NULL, 0, unsafe_pointer(app_info_ref), layers_count, layers, exts_count, exts)
    inst_ref = Ref{VkInstance}()
    @vkcheck vkCreateInstance(Ref(info.obj), C_NULL, inst_ref)
    cinst = Container(inst_ref[], [info])
    finalizer(x->vkDestroyInstance(x.obj, C_NULL), cinst)
    return cinst
end

function available_physical_devices(inst)
    device_count = Ref{UInt32}(0)
    @vkcheck vkEnumeratePhysicalDevices(inst, device_count, C_NULL)
    devices = Array{VkPhysicalDevice}(undef, device_count[])
    @vkcheck vkEnumeratePhysicalDevices(inst, device_count, devices)
    return devices
end

function properties(devices::AbstractArray{VkPhysicalDevice})
    return map(properties, devices)
end

function properties(device::VkPhysicalDevice)
    device_props = Ref{VkPhysicalDeviceProperties}()
    vkGetPhysicalDeviceProperties(device, device_props)
    return device_props[]
end

function select_physical_device(f, pdps)
    for pdp in pdps
        if Bool(f(pdp))
            return pdp
        end
    end
end

function available_queue_families(device)
    qf_count = Ref{UInt32}(0)
    vkGetPhysicalDeviceQueueFamilyProperties(device, qf_count, C_NULL)
    # vkGetPhysicalDeviceQueueFamilyProperties(C_NULL, qf_count, C_NULL)
    qf_props = Array{VkQueueFamilyProperties}(undef, qf_count[])
    vkGetPhysicalDeviceQueueFamilyProperties(device, qf_count, qf_props)
    return qf_props
end

function select_queue_family(f, queue_families)
    for qf in queue_families
        if Bool(f(qf))
            return qf
        end
    end
end

function create_logical_device(physical_device, queue_family_index;features = nothing, queue_count = 1, queue_priorities = [1.0])
    device_ref = Ref{VkDevice}()
    @assert typeof(physical_device) == VkPhysicalDevice
    if isnothing(features)
        features = Ref(VkPhysicalDeviceFeatures(values(DEFAULT_VK_PHYSICAL_DEVICE_FEATURES)...))
    end
    device_queue_info = Ref(VkDeviceQueueCreateInfo(VK_STRUCTURE_TYPE_DEVICE_QUEUE_CREATE_INFO, C_NULL, 0, queue_family_index, queue_count, Base.unsafe_convert(Ptr{Float32}, Array{Float32,1}(queue_priorities))))
    cdevice_info = @safe_contain Ref(VkDeviceCreateInfo(VK_STRUCTURE_TYPE_DEVICE_CREATE_INFO, C_NULL, 0, 1, unsafe_pointer(device_queue_info), 0, C_NULL, 0, C_NULL, unsafe_pointer(features)))
    @vkcheck vkCreateDevice(physical_device, cdevice_info.obj, C_NULL, device_ref)
    cdevice = Container(device_ref[], [cdevice_info, device_queue_info])
    finalizer(x->vkDestroyDevice(x.obj, C_NULL), cdevice)
    return cdevice, cdevice_info, device_queue_info, features
end



function initialize(; glfw = true, debug = true)
    cinst = create_instance(;glfw = glfw, debug = debug)
    # # not working yet
    # if debug
    #     messenger = debug_utils_messenger(cinst.obj)
    # end
    pdevices = available_physical_devices(cinst.obj)
    pdps = properties(pdevices)
    @debug "Physical devices found:$(map(x->"\n          $(String(x.deviceName))", pdps)...)"
    pdp = select_physical_device(pdp->pdp.deviceType == VK_PHYSICAL_DEVICE_TYPE_DISCRETE_GPU, pdps)
    @debug "Selected device \"$(String(pdp.deviceName))\""
    pdevice = pdevices[findfirst(x->x == pdp, pdps)]
    avail_qf = available_queue_families(pdevice)
    qf = select_queue_family(qf->qf.queueFlags & VK_QUEUE_GRAPHICS_BIT, avail_qf)
    cdevice, cdevice_info, device_queue_info, features = create_logical_device(pdevice, findfirst(x->x == qf, avail_qf))
    return cinst, cdevice
end

function test(; kwargs...)
    cinst, device = initialize(; kwargs...)
    return true
end

function test_manytimes(; times = 20, kwargs...)
    for i in 1:times
        test(; kwargs...)
    end
end

test()
# test_manytimes(;times=20)