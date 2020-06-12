function keyprinter(window::GLFW.Window, event::KeyEvent)
    if isaction("PRESS", event)
        println("Key: $(event.key), scancode: $(event.scancode), action: $(event.action), mods: $(event.mods)")
    end
end

function main(window::GLFW.Window, event::KeyEvent)
    if iskey("ctrl+a", "press", event)
        GLFW.SetWindowShouldClose(window, true)
    else
        keyprinter(window, event)
    end
end