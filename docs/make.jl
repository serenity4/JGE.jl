using Documenter, JGE

makedocs(;
    modules = [JGE],
    format = Documenter.HTML(
        prettyurls = get(ENV, "CI", nothing) == "true",
        collapselevel = 1,
        sidebar_sitename = false
    ),
    pages = [
        "Home" => "index.md",
        "JGE" => "jge.md",
        "Developer" => [
            "dev.md",
            "Core" => "dev/core.md",
            "Audio" => "dev/audio.md",
            "Graphics" => "dev/graphics.md",
            "Networks" => "dev/networks.md",
            "Profiling" => "dev/profiling.md",
            "Debugging" => "dev/debugging.md",
            "Build" => "dev/build.md",
        ]
    ],
    repo = "https://github.com/serenity4/JGE.jl/blob/{commit}{path}#L{line}",
    sitename = "JGE.jl",
    authors = "Cédric Belmant",
)

deploydocs(;
    repo = "github.com/serenity4/JGE.jl",
)
