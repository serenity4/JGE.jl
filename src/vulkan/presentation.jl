mutable struct Surface <: Handle
    instance::Instance
    handle::VkSurfaceKHR
    function Surface(instance::Instance, handle::VkSurfaceKHR)
        surface = new(instance, handle)
        finalizer(x->vkDestroySurfaceKHR(instance.handle, x.handle, C_NULL), surface)

        surface
    end
end

struct SurfaceFormat
    format::VkFormat
    color_space::VkColorSpaceKHR
end

Base.convert(T::Type{SurfaceFormat}, x::VkSurfaceFormatKHR) = T(getproperty.(Ref(x), fieldnames(typeof(x)))...)

struct SurfaceCapabilities <: Handle
    min_image_count::UInt32
    max_image_count::UInt32
    current_extent::VkExtent2D
    min_image_extent::VkExtent2D
    max_image_extent::VkExtent2D
    max_image_array_layers::UInt32
    supported_transforms::UInt32
    current_transform::VkSurfaceTransformFlagBitsKHR
    supported_composite_alpha::UInt32
    supported_usage_flags::UInt32
end

struct SwapChainSupportDetails
    surface_capabilities::SurfaceCapabilities
    formats::AbstractArray{T} where T <: SurfaceFormat
    present_modes::AbstractArray
end

function SurfaceCapabilities(pdevice::PhysicalDevice, surface::Surface)
    surface_capabilities_ref = Ref{VkSurfaceCapabilitiesKHR}()
    vkGetPhysicalDeviceSurfaceCapabilitiesKHR(pdevice.handle, surface.handle, surface_capabilities_ref)
    return SurfaceCapabilities(getproperty.(surface_capabilities_ref, fieldnames(VkSurfaceCapabilitiesKHR))...)
end

function available_surface_formats(pdevice::PhysicalDevice, surface::Surface)
    formats_count = Ref{UInt32}()
    @check vkGetPhysicalDeviceSurfaceFormatsKHR(pdevice.handle, surface.handle, formats_count, C_NULL)
    formats = Array{VkSurfaceFormatKHR}(undef, formats_count[])
    @check vkGetPhysicalDeviceSurfaceFormatsKHR(pdevice.handle, surface.handle, formats_count, formats)

    Base.convert.(SurfaceFormat, formats)
end

function available_surface_presentation_modes(pdevice::PhysicalDevice, surface::Surface)
    pmodes_count = Ref{UInt32}()
    @check vkGetPhysicalDeviceSurfaceFormatsKHR(pdevice.handle, surface.handle, pmodes_count, C_NULL)
    pmodes = Array{VkPresentModeKHR}(undef, pmodes_count[])
    @check vkGetPhysicalDeviceSurfaceFormatsKHR(pdevice.handle, surface.handle, pmodes_count, pmodes)

    pmodes
end

function SwapChainSupportDetails(pdevice::PhysicalDevice, surface::Surface)
    args = (pdevice, surface)
    SwapChainSupportDetails(SurfaceCapabilities(args...), available_surface_formats(args...), available_surface_presentation_modes(args...))
end

function has_presentation_support(physical_device, queue_index, surface)
    is_supported = Ref(VkBool32(true))
    @check vkGetPhysicalDeviceSurfaceSupportKHR(physical_device, queue_index, surface, is_supported)
    Bool(is_supported[])
end