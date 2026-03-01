module Interact

using ..CategoricalStructures

using Catlab.Graphics
import Catlab.Graphics: to_graphviz
import Catlab
using Catlab.Graphics.Graphviz

export get_data, with_spinner, print_graph_to_file, pretty_print

const RESET = "\e[0m"
const BOLD  = "\e[1m"
const CYAN  = "\e[36m"
const DIM   = "\e[2m"
const BRIGHT_GREEN = "\e[92m"

function with_spinner(msg, func)
    print(DIM, "  [ ] ", CYAN, msg)
    spinner = ["|", "/", "-", "\\"]
    i = 1
    
    task = @async func()
    
    while !istaskdone(task)
        print("\r", DIM, "  [$(spinner[i])] ", RESET, msg)
        i = (i % 4) + 1
        sleep(0.1)
    end
    
    println("\r", CYAN, "  [✓] ", RESET, msg)
    return fetch(task)
end


Base.show(io::IO, v::Var) = print(io, v.name)

_fmt_args(d) = d === nothing ? "" : "($(join(d, ", ")))"

function Base.show(io::IO, f::T) where T <: Fact
    print(io, "$(f.name)$(_fmt_args(f.data))")
end

Base.show(io::IO, e::BaseCatEdge) = print(io, "$(e.source) -[$(e.what)]→ $(e.target)")

function pretty_print(heading, quivers)

println(DIM, heading, RESET, "\n")
for (i, rule) in enumerate(quivers)
    println(BRIGHT_GREEN, "\t  ($i) ", RESET, rule)
end
println(DIM, "—" ^ 45, RESET)
end

function print_graph_to_file(fn, quivers)

    pretty = with_spinner("Drawing The Rule Graph", () -> begin
        to_graphviz(quivers)
    end)

    open("$fn.png", "w") do io
        run_graphviz(io, pretty, format="png")
    end

    println(DIM, "Saved to $fn.png.", RESET, "\n")
end

function Catlab.Graphics.to_graphviz(quivers::Vector{BaseCatEdge})
    gv = Graphviz.Graph("G", directed=true)
    safe_str(obj) = "\"$(sprint(show, obj))\""
    for wq in quivers
        edge_label = sprint(show, wq.what)
          p = wq.source
          c = wq.target
          push!(gv.stmts, 
          Graphviz.Edge(safe_str(p), safe_str(c), 
          label=edge_label))
    end
    return gv
end

function get_data()
    file_idx = findfirst(==("-file"), ARGS)
    isnothing(file_idx) && (println("Please provide a -file argument"); exit(1))

    filename = ARGS[file_idx + 1]
    trace = read(filename, String) |> 
            (s -> replace(s, r"\s+" => " ")) |> 
            strip
    return trace,filename
end

end