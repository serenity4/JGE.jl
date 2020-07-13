using JGE:unsafe_pointer, @safe_contain

function test_function_call(args...)
    return args
end

@noinline function test_case_nomacro()
    x = Ref(Cint(1))
    y = Ref(Ptr{Cvoid}())
    test_function_call(unsafe_pointer(x), unsafe_pointer(y))
end

@noinline function test_case()
    x = Ref(Cint(1))
    y = Ref(Ptr{Cvoid}())
    @safe_contain test_function_call(unsafe_pointer(x), unsafe_pointer(y))
end


@noinline function test_impl(ptrs, expected_values, fail)
    for (ptrs, expected) in zip(ptrs, expected_values)
        comp = unsafe_load(ptrs) == expected[] 
        if fail
            @test !comp
        else
            @test comp
        end
    end
end

function test_feature_nomacro()
    # pointed values are not kept by Julia, so unsafe_load does not return the expected value
    test_impl(test_case_nomacro(), [Ref(Cint(1)), Ref(Ptr{Cvoid}())], true)
end

function test_feature()
    # pointed values kept in the deps field of the container object, so unsafe_load returns the expected value
    test_impl(test_case()[], [Ref(Cint(1)), Ref(Ptr{Cvoid}())], false)
end

test_feature_nomacro()
test_feature()