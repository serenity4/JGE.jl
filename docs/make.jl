using Documenter, JGE

makedocs(;
    modules=[JGE],
    format=Documenter.HTML(),
    pages=[
        "Home" => "index.md",
    ],
    repo="https://github.com/serenity4/JGE.jl/blob/{commit}{path}#L{line}",
    sitename="JGE.jl",
    authors="Cédric Belmant",
    assets=String[],
)

deploydocs(;
    repo="github.com/serenity4/JGE.jl",
)
