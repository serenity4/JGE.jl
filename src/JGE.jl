module JGE

using GLFW

function main()
    window = GLFW.CreateWindow(640, 480, "GLFW.jl")
end

export main

end # module