using VulkanCore.LibVulkan # for autocompletion on VSCode, else VulkanCore alone is fine
using GLFW
import Base:findfirst

function findfirst(value, A)
    return findfirst(map(x->x == value, A))
end

include("defaults.jl")

ENV["JULIA_DEBUG"] = "all"

struct NotFoundError <: Exception
    msg
end
struct VulkanError <: Exception
    msg::AbstractString
    errorcode
end

Base.showerror(io::Core.IO, e::NotFoundError) = print(io, "NotFoundError: $(e.msg)")
Base.showerror(io::Core.IO, e::VulkanError) = print(io, "$(e.errorcode): ", e.msg)


"""
    @vkcheck vkFunctionSomething()

Checks whether the expression returned VK_SUCCESS. Else, throw an error printing the corresponding code."""
macro vkcheck(expr)
    quote
        local expr_return_code = $(esc(expr))
        if typeof(expr_return_code) != VkResult
            throw(ErrorException("the return value is not a valid code"))
        end
        if expr_return_code != VK_SUCCESS
            local str_error = $(string(expr))
            throw(VulkanError("failed to execute $str_error", expr_return_code))
        end
    end
end


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

function create_appinfo(; name="Vulkan Instance", exts=C_NULL, version=VK_MAKE_VERSION(0, 0, 1), engine_name="NoEnngine", engine_version=VK_MAKE_VERSION(0, 0, 1), api_version=VK_API_VERSION_1_0())
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

function create_instance(; glfw=true, debug=true)
    app_info_ref = Ref(create_appinfo())
    exts, exts_count = required_extensions(glfw, debug)
    layers, layers_count = required_layers(debug)
    info = Ref(VkInstanceCreateInfo(VK_STRUCTURE_TYPE_INSTANCE_CREATE_INFO, C_NULL, 0, unsafe_pointer(app_info_ref), layers_count, layers, exts_count, exts))
    inst_ref = Ref{VkInstance}()
    @vkcheck vkCreateInstance(info, C_NULL, inst_ref)
    return inst_ref[]
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

# this function has to be generated so that there is no change in scope, which may invalide pointers
@generated function unsafe_pointer(obj)
    quote
        @assert typeof(obj) <: Ref
        Base.unsafe_convert(Ptr{typeof(obj[])}, obj)
    end
end

function create_logical_device(physical_device, queue_family_index;features=nothing, queue_count=1, queue_priorities=[1.0])
    device = Ref{VkDevice}()
    @assert typeof(physical_device) == VkPhysicalDevice
    if isnothing(features)
        features = Ref(VkPhysicalDeviceFeatures(values(DEFAULT_VK_PHYSICAL_DEVICE_FEATURES)...))
    end
    device_queue_info = Ref(VkDeviceQueueCreateInfo(VK_STRUCTURE_TYPE_DEVICE_QUEUE_CREATE_INFO, C_NULL, 0, queue_family_index, queue_count, Base.unsafe_convert(Ptr{Float32}, Array{Float32,1}(queue_priorities))))
    @GC.preserve device_queue_info features begin
        device_info = Ref(VkDeviceCreateInfo(VK_STRUCTURE_TYPE_DEVICE_CREATE_INFO, C_NULL, 0, 1, unsafe_pointer(device_queue_info), 0, C_NULL, 0, C_NULL, unsafe_pointer(features)))
        @vkcheck vkCreateDevice(physical_device, device_info, C_NULL, device)
    end
    return device, device_info, device_queue_info, features
end



function initialize(; glfw=true, debug=true)
    inst = create_instance(;glfw=glfw, debug=debug)
    pdevices = available_physical_devices(inst)
    pdps = properties(pdevices)
    @debug "Physical devices found:$(map(x->"\n          $(String(x.deviceName))", pdps)...)"
    pdp = select_physical_device(pdp->pdp.deviceType == VK_PHYSICAL_DEVICE_TYPE_DISCRETE_GPU, pdps)
    @debug "Selected device \"$(String(pdp.deviceName))\""
    pdevice = pdevices[findfirst(pdp, pdps)]
    avail_qf = available_queue_families(pdevice)
    qf = select_queue_family(qf->qf.queueFlags & VK_QUEUE_GRAPHICS_BIT, avail_qf)
    device, device_info, device_queue_info, features = create_logical_device(pdevice, findfirst(qf, avail_qf))
    # vkDestroyDevice(device, C_NULL)
    return inst, device
end

function cleanup(instance, device)
    vkDestroyInstance(instance, C_NULL)
    
    # causes segfault at the moment
    # vkDestroyDevice(device, C_NULL)
end

function test(; kwargs...)
    inst, device = initialize(; kwargs...)
    cleanup(inst, device)
    return true
end

function test_manytimes(; kwargs...)
    for i in 1:20
        test(; kwargs...)
    end
end