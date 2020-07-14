struct VulkanError <: Exception
    msg::AbstractString
    errorcode
end
Base.showerror(io::Core.IO, e::VulkanError) = print(io, "$(e.errorcode): ", e.msg)

"""
    @check vkFunctionSomething()

Checks whether the expression returned VK_SUCCESS. Else, throw an error printing the corresponding code."""
macro check(expr)
    quote
        local expr_return_code = $(esc(expr))
        if typeof(expr_return_code) != LibVulkan.VkResult
            throw(ErrorException("the return value is not a valid code"))
        end
        if expr_return_code != LibVulkan.VK_SUCCESS
            local str_error = $(string(expr))
            throw(VulkanError("failed to execute $str_error", expr_return_code))
        end
    end
end

# this function has to be generated so that there is no change in scope, which may invalide pointers
@generated function unsafe_pointer(obj)
    quote
        typeof(obj) <: Union{Base.RefValue,Base.AbstractArray}
        Base.unsafe_convert(Ptr{typeof(obj[])}, obj)
    end
end

function vk_version(version::VersionNumber)
    VK_MAKE_VERSION(getfield.(Ref(version), [:major, :minor, :patch])...)
end

int_to_version(version::Cuint) = VersionNumber(VK_VERSION_MAJOR(version),
										  VK_VERSION_MINOR(version),
										  VK_VERSION_PATCH(version))

abstract type Handle end

function destroy_handle(f)
    function destroy(x::Handle)
        f(x.handle, C_NULL)
    end
end

int_to_str(field) = String(filter(x->x != 0, UInt8[field...]))
reverse_dict(d::Dict) = Dict(v => k for (k, v) in d)