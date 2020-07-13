struct Layer
    name::AbstractString
    spec_version::VersionNumber
    implementation_version::VersionNumber
    description::AbstractString
end

Base.convert(T::Type{Layer}, layer::VkLayerProperties) = Layer(int_to_str(layer.layerName), int_to_version(layer.specVersion), int_to_version(layer.implementationVersion), int_to_str(layer.description))

function available_layers()
    layer_count = Ref{UInt32}(0)
    @check vkEnumerateInstanceLayerProperties(layer_count, C_NULL)
    avail_layers = Array{VkLayerProperties}(undef, layer_count[])
    @check vkEnumerateInstanceLayerProperties(layer_count, avail_layers)
    Base.convert.(Ref(Layer), avail_layers)
end

function check_layers(layer_names::AbstractArray{T} where T <: AbstractString, avail_layers::AbstractArray{T} where T <: Layer)
    avail_layer_names = getproperty.(avail_layers, :layer_name)
    @assert issubset(layer_names, avail_layer_names) "The following layers are not available: $(symdiff(intersect(avail_layer_names, layer_names), layer_names))"
end