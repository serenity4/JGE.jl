import Base:append!, getindex

mutable struct Container
    obj
    deps::AbstractArray
    function Container(obj, deps)
        deps_cont = filter(x->typeof(x) == Container, deps)
        deps_notcont = filter(x->typeof(x) != Container, deps)
        if !isempty(deps_cont) # add all previous container objects and dependencies to the new container
            return new(obj, [deps_notcont..., map((x->getfield(x, :obj)), deps_cont)..., (map((x->getfield(x, :deps)), deps_cont)...)...])
        else
            return new(obj, deps)
        end
    end
end

function append!(original::Container, new::Container...)
    append!(original.deps, (map((x->getfield(x, :deps)), new)...))
end

getindex(cont::Container) = cont.obj

function Base.show(io::IO, cont::Container)
    println("Container:")
    println("    Object: $(cont[])")
    println("    Dependencies:")
    for dep in cont.deps 
        println("        $dep")
    end
end

"""
    troubleshoot(container)

Recursively loads all pointers.
"""
function troubleshoot(obj)
    if typeof(obj) <: Ptr
        o = unsafe_load(obj)
        typeof(o) <: Ptr ? troubleshoot(o) : @warn o
    elseif typeof(obj) <: Ref
        troubleshoot(obj[])
    elseif typeof(obj) <: Union{Tuple,AbstractArray}
        for o in obj
            troubleshoot(o)
        end
    end
end


# this function has to be generated so that there is no change in scope, which may invalide pointers
@generated function unsafe_pointer(obj)
    quote
        if typeof(obj) == Container
            unsafe_pointer(obj[])
        elseif typeof(obj) <: Union{Base.RefValue,Base.AbstractArray}
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
        deps = Any[loc[symbol] for symbol in $vars]
        container = Container(main_obj_cont, deps)
    end
end