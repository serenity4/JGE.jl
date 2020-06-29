mutable struct Container
    obj
    deps::AbstractArray
end

@generated function unsafe_pointer(obj)
    quote
        # @assert typeof(obj) <: Ref
        Base.unsafe_convert(Ptr{typeof(obj)}, Ref(obj))
    end
end

macro safe_contain(expr)# this function has to be generated so that there is no change in scope, which may invalide pointers
    str_expr = repr(expr)
    unsafe_ptr_vars_regex = r"unsafe_pointer\((.*?)\)"
    vars = map(x -> Symbol(x.captures[1]), eachmatch(unsafe_ptr_vars_regex, str_expr))
    quote
        main_obj_cont = $(esc(expr))
        loc = Base.@locals()
        Container(main_obj_cont, [loc[x] for x in $vars])
    end
end

function test_case()
    function function_call(args...)
        println(args...)
    end
    e = "e"
    ako = "ako"
    x = Cint(1)
    troll = "troll"
    lana = Ptr{Cvoid}()
    container = @safe_contain function_call(e, ako, unsafe_pointer(x), troll, unsafe_pointer(lana))
end

test_case()