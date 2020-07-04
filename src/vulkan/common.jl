struct VulkanError <: Exception
    msg::AbstractString
    errorcode
end
Base.showerror(io::Core.IO, e::VulkanError) = print(io, "$(e.errorcode): ", e.msg)

"""
    @vkcheck vkFunctionSomething()

Checks whether the expression returned VK_SUCCESS. Else, throw an error printing the corresponding code."""
macro vkcheck(expr)
    quote
        local expr_return_code = $(esc(expr))
        if typeof(expr_return_code) != VkResult
            throw(ErrorException("the return value is not a valid code"))
        end
        if expr_return_code != VK_SUCCESS
            local str_error = $(string(expr))
            throw(VulkanError("failed to execute $str_error", expr_return_code))
        end
    end
end
