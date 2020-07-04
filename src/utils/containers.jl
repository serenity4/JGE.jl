mutable struct Container
    obj
    deps::AbstractArray
end


function Container(obj, deps)
    deps_cont = filter(x -> typeof(x) == Container, deps)
    deps_notcont = filter(x -> typeof(x) != Container, deps)
    if !isempty(deps_cont)
        return Container(obj, deps_notcont..., (map((x -> getfield(x, :deps)), deps_cont)...)...)
    else
        return Container(obj, deps)
    end
end

# this function has to be generated so that there is no change in scope, which may invalide pointers
@generated function unsafe_pointer(obj)
    quote
        if typeof(obj) == Container
            unsafe_pointer(obj.obj)
        elseif typeof(obj) <: Base.RefValue
            Base.unsafe_convert(Ptr{typeof(obj[])}, obj)
        end
    end
end

macro safe_contain(expr)
    str_expr = repr(expr)
    unsafe_ptr_vars_regex = r"unsafe_pointer\((.*?)\)"
    vars = Any[Symbol(x.captures[1]) for x in eachmatch(unsafe_ptr_vars_regex, str_expr)]
    quote
        main_obj_cont = $(esc(expr))
        loc = Base.@locals()
        deps = [loc[symbol] for symbol in $vars]
        container = Container(main_obj_cont, deps)
    end
end