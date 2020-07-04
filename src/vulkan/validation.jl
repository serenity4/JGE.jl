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

const message_types_r = reverse(message_types)
const message_severities_r = reverse(message_severities)

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

function debug_callback(message_severity::VkDebugUtilsMessageSeverityFlagBitsEXT,
    message_type::VkDebugUtilsMessageTypeFlagsEXT,
    message,
    )
    @vk_log message_severity "$message_type: $message"
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


function debug_utils_messenger(inst; severity = "debug", types = ["general", "validation", "performance"])
    severity_hierarchy = ["debug", "info", "warn", "error"]
    index = findfirst(severity_hierarchy .== severity)
    severity_bits = [message_severities[key] for key in severity_hierarchy[index:end]]
    type_bits = [message_types[key] for key in types]
    messenger_info = Ref(VkDebugUtilsMessengerCreateInfoEXT(VK_STRUCTURE_TYPE_DEBUG_UTILS_MESSENGER_CREATE_INFO_EXT, C_NULL, 0, |(severity_bits...), |(type_bits...), @cfunction(generate_debug_callback_interface(debug_callback), Cint, (UInt32, UInt32, Ptr{Cvoid}, Ptr{Cvoid})), C_NULL))
    func = vkGetInstanceProcAddr(inst, pointer("vkCreateDebugUtilsMessengerEXT"))
    messenger = Ref{VkDebugUtilsMessengerEXT}()
    @vkcheck ccall(func, VkResult, (Core.Any, Core.Any, Core.Any, Core.Any), inst, unsafe_pointer(messenger_info), C_NULL, messenger)
    # @vkcheck unsafe_load(func)(inst, unsafe_pointer(messenger_info), C_NULL, messenger)
    Container(messenger[], messenger_info[])
end

# using Libdl
# find_library("libVkLayer_khronos_validation.so", ["/home/belmant/.julia/dev/Builders/Vulkan-ValidationLayers/build/layers/", "/home/belmant/.julia/dev/Builders/Vulkan-ValidationLayers/build/"])
