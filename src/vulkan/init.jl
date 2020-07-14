struct NotFoundError <: Exception
    msg
end

Base.showerror(io::Core.IO, e::NotFoundError) = print(io, "NotFoundError: $(e.msg)")


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