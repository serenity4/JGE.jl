module JGE

using GLFW

include("core/glfw.jl")
include("core/keymaps.jl")

function main()
    create_window((1000, 720); key_callback = keyprinter)
end

export main

end # module