using GLFW

struct KeyEvent
    key::GLFW.Key
    scancode::Int32
    action::GLFW.Action
    mods::Int32
end

abstract type AbstractContext end
struct VulkanContext <: AbstractContext end
struct OpenGLContext <: AbstractContext end

shift = 1
ctrl = 2
alt = 4

function ismod(name::AbstractString, event::KeyEvent)
    if name == "alt"
        return div(event.mods, 4) == 1
    elseif name == "ctrl"
        return div(mod(event.mods, 4), 2) == 1
    elseif name == "shift"
        return mod(mod(event.mods, 4), 2) == 1
    end
end

function iskey(name::AbstractString, event::KeyEvent)
    if occursin("+", name)
        if occursin("ctrl", name)
            consumed_name = replace(name, "ctrl+" => "")
            return ismod("ctrl", event)  && iskey(consumed_name, event)
        elseif occursin("shift", name)
            consumed_name = replace(name, "shift+" => "")
            return ismod("shift", event)  && iskey(consumed_name, event)
        elseif occursin("alt", name)
            consumed_name = replace(name, "alt+" => "")
            return ismod("alt", event)  && iskey(consumed_name, event)
        end
    else
        return getfield(GLFW, Symbol(uppercase("key_$name"))) == event.key
    end
end

function iskey(name::AbstractString, action::AbstractString, event::KeyEvent)
    if action == "released"
        action = "release"
    elseif action == "pressed"
        action = "press"
    end
    return iskey(name, event) && isaction(action, event)
end

function isaction(name::AbstractString, event::KeyEvent)
    getfield(GLFW, Symbol(uppercase(name))) == event.action
end

function wrap_key_callback(f::Function)
    function callback(window::GLFW.Window, key::GLFW.Key, scancode::Int32, action::GLFW.Action, mods::Int32)
        event = KeyEvent(key, scancode, action, mods)
        f(window, event)
    end
    return callback
end

function window_loop(context::OpenGLContext, renderer::Function)
    function loop(window::GLFW.Window)
        renderer()
        GLFW.SwapBuffers(window)
        GLFW.PollEvents()
    end
end

function window_loop(context::VulkanContext, renderer::Function)
    function loop(window::GLFW.Window)
        renderer()
        GLFW.PollEvents()
    end
end


function provide_window_hints(context::VulkanContext)
    GLFW.WindowHint(GLFW.CLIENT_API, GLFW.NO_API)
end

function provide_window_hints(context::OpenGLContext)
end

function create_window(window_size::Tuple{Integer,Integer}, name, context::OpenGLContext)
    provide_window_hints(context)
    window = GLFW.CreateWindow(window_size..., name)
    GLFW.MakeContextCurrent(window)
    return window
end

function create_window(window_size::Tuple{Integer,Integer}, name, context::VulkanContext)
    provide_window_hints(context)
    window = GLFW.CreateWindow(window_size..., name)
    return window
end

function run_window(window, loop; key_callback = nothing)
    if !isnothing(key_callback)
        callback = wrap_key_callback(key_callback)
        GLFW.SetKeyCallback(window, callback)
    end
    while !GLFW.WindowShouldClose(window)
        loop(window)
    end
    println("Good bye!")
    GLFW.DestroyWindow(window)
end

function run_window(window_size::Tuple{Integer,Integer}; key_callback = nothing, renderer = ()->nothing, name::AbstractString = "Julia Game Engine", context::AbstractContext = OpenGLContext())
    window = create_window(window_size, name, context)
    loop = window_loop(context, renderer)
    run_window(window, loop, key_callback = key_callback)
end    