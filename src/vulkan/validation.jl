mutable struct DebugCallback <: Handle
    f::Union{Base.CFunction,Ptr{Cvoid}}
    info::VkDebugUtilsMessengerCreateInfoEXT
    f_proc_addr
    f_proc_addr_name::AbstractString
    handle::VkDebugUtilsMessengerEXT
end

const severity_hierarchy = ["debug", "info", "warn", "error"]

const message_severities = Dict(
    "debug" => VK_DEBUG_UTILS_MESSAGE_SEVERITY_VERBOSE_BIT_EXT,
    "info" => VK_DEBUG_UTILS_MESSAGE_SEVERITY_INFO_BIT_EXT,
    "warn" => VK_DEBUG_UTILS_MESSAGE_SEVERITY_WARNING_BIT_EXT,
    "error" => VK_DEBUG_UTILS_MESSAGE_SEVERITY_ERROR_BIT_EXT,
)

const message_types = Dict(
    "general" => VK_DEBUG_UTILS_MESSAGE_TYPE_GENERAL_BIT_EXT,
    "validation" => VK_DEBUG_UTILS_MESSAGE_TYPE_VALIDATION_BIT_EXT,
    "performance" => VK_DEBUG_UTILS_MESSAGE_TYPE_PERFORMANCE_BIT_EXT,
)

const message_types_r = reverse_dict(message_types)
const message_severities_r = reverse_dict(message_severities)

function DebugCallback(instance::Instance; f::Union{Base.CFunction,Ptr{Cvoid}} = default_debug_callback, severity = "info", types = ["general", "validation", "performance"])
    index = findfirst(severity_hierarchy .== severity)
    severity_bits = collect(values(message_severities))[index:end]
    type_bits = [message_types[key] for key in types]
    messenger_info_ref = Ref(VkDebugUtilsMessengerCreateInfoEXT(VK_STRUCTURE_TYPE_DEBUG_UTILS_MESSENGER_CREATE_INFO_EXT, C_NULL, 0, |(severity_bits...), |(type_bits...), f, C_NULL))
    f_proc_addr_name = "vkCreateDebugUtilsMessengerEXT"
    f_proc_addr = vkGetInstanceProcAddr(instance.handle, pointer(f_proc_addr_name))
    messenger = Ref{VkDebugUtilsMessengerEXT}()
    @check ccall(f_proc_addr, VkResult, (VkInstance, Ptr{VkDebugUtilsMessengerCreateInfoEXT}, Ptr{Nothing}, Ptr{VkDebugUtilsMessengerEXT}), instance.handle, unsafe_pointer(messenger_info_ref), C_NULL, messenger)
    dcallback = DebugCallback(f, messenger_info_ref[], f_proc_addr, f_proc_addr_name, messenger[])
    finalizer(destroy_handle(x->vkDestroyDebugUtilsMessengerEXT(inst)), dcallback)

    dcallback
end

# necessary to avoid crashes if the debug callback goes out of scope
attach_debug_callback!(instance::Instance, debug_callback::DebugCallback) = push!(instance.deps, debug_callback) ; nothing
function attach_debug_callback!(instance::Instance; f::Union{Base.CFunction,Ptr{Cvoid}} = default_debug_callback, severity = "info", types = ["general", "validation", "performance"])
    dcallback = DebugCallback(instance; f = f, severity = severity, types = types)
    push!(instance.deps, dcallback)

    nothing
end

"""
    @vk_log VK_DEBUG_UTILS_MESSAGE_SEVERITY_VERBOSE_BIT_EXT str

Converts a Vulkan log to a Julia log
"""
macro vk_log(log_type_symbol, str)
    quote
        log_type = getfield(LibVulkan, log_type_symbol)
        if log_type == VK_DEBUG_UTILS_MESSAGE_SEVERITY_VERBOSE_BIT_EXT
            @debug($(esc(str)))
        elseif log_type == VK_DEBUG_UTILS_MESSAGE_SEVERITY_INFO_BIT_EXT
            @info($(esc(str)))
        elseif log_type == VK_DEBUG_UTILS_MESSAGE_SEVERITY_WARNING_BIT_EXT
            @warn($(esc(str)))
        elseif log_type == VK_DEBUG_UTILS_MESSAGE_SEVERITY_ERROR_BIT_EXT
            @error($(esc(str)))
        else
            throw(ArgumentError("Unknown logging type $log_type"))
        end
    end
end

function _default_debug_callback(message_severity::VkDebugUtilsMessageSeverityFlagBitsEXT,
message_type::VkDebugUtilsMessageTypeFlagsEXT,
message,
)
    # @vk_log message_severity "$message_type: $message"
    println(message)
    return 0
end

function generate_debug_callback_interface(callback_f::Function)
    function debug_callback_interface(message_severity::VkDebugUtilsMessageSeverityFlagBitsEXT,
    message_type::VkDebugUtilsMessageTypeFlagsEXT,
    pCallbackData::Ptr{VkDebugUtilsMessengerCallbackDataEXT},
    pUserData::Ptr{Cvoid})
        callback_f(message_severity, message_type, unsafe_load(pCallbackData).pMessage)
    end
end

default_debug_callback = generate_debug_callback_interface(_default_debug_callback)
default_debug_callback_c = @cfunction(default_debug_callback, Cint, (UInt32, UInt32, Ptr{Cvoid}, Ptr{Cvoid}))