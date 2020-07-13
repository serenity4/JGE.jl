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

function create_appinfo(; name = "Vulkan Instance", exts = C_NULL, version = VK_MAKE_VERSION(0, 0, 1), engine_name = "NoEngine", engine_version = VK_MAKE_VERSION(0, 0, 1), api_version = VK_API_VERSION_1_0())
    capp_info = Container(VkApplicationInfo(VK_STRUCTURE_TYPE_APPLICATION_INFO, exts, pointer(name), version, pointer(engine_name), engine_version, api_version), Any[Ref(name), Ref(engine_name)])
    return capp_info
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
        @info "Enabled extensions:$(map(x->"\n          $x", ext_names)...)"
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
        @info "Enabled layers:$(map(x->"\n          $x", layer_names)...)"
        layers = Base.unsafe_convert(Ptr{Cstring}, pointer.(layer_names))
        layers_count = length(layers)
    else
        layers = C_NULL
        layers_count = 0
    end
    return layers, layers_count
end

function create_instance(; glfw = true, debug = true)
    capp_info = create_appinfo()
    exts, exts_count = required_extensions(glfw, debug)
    layers, layers_count = required_layers(debug)
    app_info_ref = Ref(capp_info[])
    cinfo = @safe_contain VkInstanceCreateInfo(VK_STRUCTURE_TYPE_INSTANCE_CREATE_INFO, C_NULL, 0, unsafe_pointer(app_info_ref), layers_count, layers, exts_count, exts)
    append!(cinfo, capp_info)
    inst_ref = Ref{VkInstance}()
    @vkcheck vkCreateInstance(Ref(cinfo[]), C_NULL, inst_ref)
    cinst = Container(inst_ref[], [cinfo])
    finalizer(x->vkDestroyInstance(x[], C_NULL), cinst)
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


function initialize(; glfw = true, debug = true)
    cinst = create_instance(;glfw = glfw, debug = debug)
    # # not working yet
    if debug
        cmessenger = debug_utils_messenger(cinst[])
        append!(cinst, cmessenger)
        @info "Activated debug callback"
    end
    pdevices = available_physical_devices(cinst[])
    pdps = properties(pdevices)
    @debug "Physical devices found:$(map(x->"\n          $(String(x.deviceName))", pdps)...)"
    pdp = select_physical_device(pdp->pdp.deviceType == VK_PHYSICAL_DEVICE_TYPE_DISCRETE_GPU, pdps)
    @info "Selected device \"$(String(pdp.deviceName))\""
    pdevice = pdevices[findfirst(x->x == pdp, pdps)]

    cinst, pdevice
end