function keyprinter(window::GLFW.Window, event::KeyEvent)
    if isaction("PRESS", event)
        println(event.scancode)
    end
end