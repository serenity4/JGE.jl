struct Extension
    name::AbstractString
    spec_version::VersionNumber
end

Base.convert(T::Type{Extension}, ext::VkExtensionProperties) = T(int_to_str(ext.extensionName), int_to_version(ext.specVersion))

function available_extensions()
    avail_exts_count = Ref{UInt32}()
    @check vkEnumerateInstanceExtensionProperties(C_NULL, avail_exts_count, C_NULL)
    avail_exts = Array{VkExtensionProperties}(undef, avail_exts_count[])
    @check vkEnumerateInstanceExtensionProperties(C_NULL, avail_exts_count, avail_exts)
    
    Base.convert.(Extension, avail_exts)
end

function check_extensions(ext_names::AbstractArray{T} where T <: AbstractString, avail_exts)
    avail_ext_names = getproperty(avail_exts, :name)
    @assert issubset(ext_names, avail_ext_names) "The following extensions are not available: $(symdiff(intersect(avail_layer_names, layer_names), layer_names))"
end
