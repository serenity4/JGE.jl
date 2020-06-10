using GLFW

function test_mod(mods, name, expected)
    event = JGE.KeyEvent(GLFW.KEY_E, 0, GLFW.PRESS, mods)
    @test JGE.ismod(name, event) == expected
end

mods = ["shift", "ctrl", "alt"]

mod_matrix = [
    false false false;
    true false false;
    false true false;
    true true false;
    false false true;
    true false true;
    false true true;
    true true true
]

for value in 0:(size(mod_matrix)[1] - 1)
    for pair_mod_expected in zip(mods, mod_matrix[value + 1, :])
        m, expected = pair_mod_expected
        test_mod(value, m, expected)
    end
end