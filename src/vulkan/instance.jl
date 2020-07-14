mutable struct Instance <: Handle
    application_name::AbstractString
    application_version::VersionNumber
    engine_name::AbstractString
    engine_version::VersionNumber
    api_version::VersionNumber
    layers::AbstractArray
    exts::AbstractArray
    handle::VkInstance
    inst_info::VkInstanceCreateInfo
    app_info::VkApplicationInfo
    deps::AbstractArray
end

function Instance(application_name::AbstractString, application_version::VersionNumber, engine_name::AbstractString, engine_version::VersionNumber, api_version::VersionNumber, layers::AbstractArray, exts::AbstractArray)
    app_info_ref = Ref(VkApplicationInfo(VK_STRUCTURE_TYPE_APPLICATION_INFO, C_NULL, pointer(application_name), vk_version(application_version), pointer(engine_name), vk_version(engine_version), vk_version(api_version)))

    layers = typeof(layers) <: AbstractArray{T} where T <: Layer ? getproperty.(layers, :name) : layers
    exts = typeof(exts) <: AbstractArray{T} where T <: Extension ? getproperty.(exts, :name) : exts
    p_layers = isempty(layers) ? C_NULL : pointer(pointer.(layers))
    p_exts = isempty(exts) ? C_NULL : pointer(pointer.(exts))

    inst_info = VkInstanceCreateInfo(VK_STRUCTURE_TYPE_INSTANCE_CREATE_INFO, C_NULL, 0, unsafe_pointer(app_info_ref), length(layers), p_layers, length(exts), p_exts)
    handle = Ref{VkInstance}()
    @check vkCreateInstance(Ref(inst_info), C_NULL, handle)
    inst = Instance(application_name, application_version, engine_name, engine_version, api_version, layers, exts, handle[], inst_info, app_info_ref[], [])
    Base.finalizer(destroy_handle(vkDestroyInstance), inst)

    inst
end

function Base.show(io::IO, inst::Instance)
    println(io, "$(inst.application_name) $(inst.application_version)")
    println(io, " ↪ $(inst.engine_name) $(inst.engine_version)")
    println(io, " ↪ Vulkan API $(inst.api_version)")
    println(io, "  ↪ Layers: $(inst.layers)")
    println(io, "  ↪ Extensions: $(inst.exts)")
end