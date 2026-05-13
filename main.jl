include("structures/categorical_structures.jl")
include("structures/plumbing.jl")
include("decorations/interact.jl")
include("structures/msr_translation.jl")

using .Interact, .CategoricalStructures, .CategoricalPlumbing, .MSRTranslation
using Combinatorics

data,fn = get_data()

logs = with_spinner("Parsing execution steps...", () -> parse_to_exec_steps(data))
base = with_spinner("Generating base quiver...", () -> gen_base_edge(logs))
universal_base = with_spinner("Determining universal objects...", () -> create_universal_objects(base))

pretty_print("Walking Dense Quiver (Rule Schema)", universal_base)
print_graph_to_file(fn,universal_base)

#A note on Tamarin convention: ~x for fresh, $x for public, x for bound... although we don't implement this here
#because we don't actually learn this directly...
function unwrap(sf::StateFact)
    (isnothing(sf.data) || isempty(sf.data)) && return ""
    return join(["$(sf.name)($v)" for v in sf.data], ", ")
end

function unwrap_target(target::StateFact, action::ActionFact)
    if isnothing(target.data) || length(target.data) <= 1
        return unwrap(target)
    end

    relevant_vars = unique(filter(v -> v in action.data, target.data))
    
    return join(["$(target.name)($v)" for v in relevant_vars], ", ")
end

function process_to_tamarin(dense_quiver::Vector{BaseCatEdge})
    rules_learned = String[]
    for (i, arrow) in enumerate(dense_quiver) 
        lhs = unwrap(arrow.source)
        action_label = arrow.what.name
        
        rhs = unwrap_target(arrow.target, arrow.what)
        
        push!(rules_learned, """
rule Rule_$i:
  [ $lhs ]
--[ $action_label ]-->
  [ $rhs ]
""")
    end
    return rules_learned
end

for a in process_to_tamarin(universal_base)
    println(a)
end