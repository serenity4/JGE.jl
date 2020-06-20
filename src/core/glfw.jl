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

function window_loop(window::GLFW.Window, context::OpenGLContext)
    GLFW.SwapBuffers(window)
    GLFW.PollEvents()
end

function window_loop(window::GLFW.Window, context::VulkanContext)
    GLFW.PollEvents()
end

function window_loop(window::GLFW.Window, renderer::Function, context::AbstractContext)
    renderer()
    window_loop(window, context)
end


function provide_window_hints(context::VulkanContext)
    GLFW.WindowHint(GLFW.CLIENT_API, GLFW.NO_API)
end

function provide_window_hints(context::OpenGLContext)
end

function create_window(window_size::Tuple{Integer,Integer}, name, context::OpenGLContext)
    window = GLFW.CreateWindow(window_size..., name)
    GLFW.MakeContextCurrent(window)
    return window
end

function create_window(window_size::Tuple{Integer,Integer}, name, context::VulkanContext)
    window = GLFW.CreateWindow(window_size..., name)
    return window
end

function run_window(window, context; key_callback = nothing, renderer = nothing)
    if !isnothing(key_callback)
        callback = wrap_key_callback(key_callback)
        GLFW.SetKeyCallback(window, callback)
    end

    if !isnothing(renderer)
        args = (window, renderer)
    else
        args = (window,)
    end
    while !GLFW.WindowShouldClose(window)
        window_loop(args..., context)
    end
    println("Good bye!")
    GLFW.DestroyWindow(window)
end

function run_window(window_size::Tuple{Integer,Integer}; key_callback = nothing, renderer = nothing, name::AbstractString = "Julia Game Engine", context::AbstractContext = OpenGLContext())
    provide_window_hints(context)
    window = create_window(window_size, name, context)
    run_window(window, context, key_callback = key_callback, renderer = renderer)
end