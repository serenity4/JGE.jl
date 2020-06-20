using VulkanCore.LibVulkan # for autocompletion on VSCode, else VulkanCore alone is fine
using GLFW

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
	println(io, "    Device Name: ", String(filter(x->x != 0, UInt8[pdp.deviceName...])))
	println(io, "    Pipeline Cache UUID: ", String(collect(pdp.pipelineCacheUUID)))
	println(io, "    Limits: ", pdp.limits)
	println(io, "    Sparse Properties: \n    ", pdp.sparseProperties)
end

function create_appinfo(; name="Vulkan Instance", exts=C_NULL, version=VK_MAKE_VERSION(0, 0, 1), engine_name="NoEnngine", engine_version=VK_MAKE_VERSION(0, 0, 1), api_version=VK_API_VERSION_1_0())
    app_info = VkApplicationInfo(VK_STRUCTURE_TYPE_APPLICATION_INFO, exts, pointer(name), version, pointer(engine_name), engine_version, api_version)
    return app_info
end

function check_glfw_compat()
    ext_names = GLFW.GetRequiredInstanceExtensions()
    avail_exts_count = Ref{UInt32}()
    @vkcheck vkEnumerateInstanceExtensionProperties(C_NULL, avail_exts_count, C_NULL)
    avail_exts = Array{VkExtensionProperties}(undef, avail_exts_count[])
    @vkcheck vkEnumerateInstanceExtensionProperties(C_NULL, avail_exts_count, avail_exts)
    avail_exts_names = map(ext->String(filter(x->x != 0, UInt8[ext.extensionName...])), avail_exts)
    @assert issubset(ext_names, avail_exts_names) "GLFW requires extensions that are not available: $(symdiff(intersect(avail_exts_names, ext_names), ext_names))"
end


function available_layers()
    layer_count = Ref{UInt32}(0)
    @vkcheck vkEnumerateInstanceLayerProperties(layer_count, C_NULL)
    avail_layers = Array{VkLayerProperties}(undef, layer_count[])
    @vkcheck vkEnumerateInstanceLayerProperties(layer_count, avail_layers)
    return avail_layers
end

function check_layers(layer_names::AbstractArray{T} where T <: AbstractString, avail_layers)
    avail_layer_names = map(x->convert(x.layerName, String), avail_layers)
    @assert issubset(layer_names, avail_layer_names) "The following layers are not available: $(symdiff(intersect(avail_layer_names, layer_names), layer_names))"
end

function create_instance(; glfw=true, debug=true)
    app_info_ref = Ref(create_appinfo())
    exts_count = Ref{UInt32}(0)
    if glfw
        check_glfw_compat()
        exts = GLFW.GetRequiredInstanceExtensions(exts_count)
    else
        exts = C_NULL
    end
    if debug
        layer_names = ["VK_LAYER_KHRONOS_validation"]
        check_layers(layer_names, available_layers())
        @debug "Enabled layers:$(map(x->"\n          $x", layer_names)...)"
        enabled_layer_names = Base.unsafe_convert(Ptr{Cstring}, pointer.(layer_names))
        enabled_layers_count = length(enabled_layer_names)
    else
        enabled_layer_names = C_NULL
        enabled_layers_count = 0
    end

    info = Ref(VkInstanceCreateInfo(VK_STRUCTURE_TYPE_INSTANCE_CREATE_INFO, C_NULL, 0, Base.unsafe_convert(Ptr{VkApplicationInfo}, app_info_ref), enabled_layers_count, enabled_layer_names, exts_count[], exts))
    inst_ref = Ref{VkInstance}()
    @vkcheck vkCreateInstance(info, C_NULL, inst_ref)
    return inst_ref[]
end

function check_devices(inst)
    device_count = Ref{UInt32}(0)
    @vkcheck vkEnumeratePhysicalDevices(inst, device_count, C_NULL)
    devices = Array{VkPhysicalDevice}(undef, device_count[])
    @assert device_count[] != 0
    # @vkcheck vkEnumeratePhysicalDevices(inst_ref[], device_count, devices)
    # device_props = Ref{VkPhysicalDeviceProperties}()
    # vkGetPhysicalDeviceProperties(devices[], device_props)
end

function initialize(; glfw=true, debug=true)
    inst_ref = create_instance(;glfw=glfw, debug=debug)
    return inst_ref
end

function cleanup(instance)
    vkDestroyInstance(instance, C_NULL)
end

function test(; kwargs...)
    inst = initialize(; kwargs...)
    check_devices(inst)
    cleanup(inst)
    return true
end