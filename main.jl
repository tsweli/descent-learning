include("structures/categorical_structures.jl")
include("structures/plumbing.jl")
include("decorations/interact.jl")

using .Interact, .CategoricalStructures, .CategoricalPlumbing
using Combinatorics

data,fn = get_data()

logs = with_spinner("Parsing execution steps...", () -> parse_to_exec_steps(data))
base = with_spinner("Generating base quiver...", () -> gen_base_edge(logs))
universal_base = with_spinner("Determining universal objects...", () -> create_universal_objects(base))

pretty_print("Walking Dense Quiver (Rule Schema)", universal_base)
print_graph_to_file(fn,universal_base)

#A note on Tamarin convention: ~x for fresh, $x for public, x for bound... although we don't implement this here
#because we don't actually learn this directly...


function process_to_tamarin(dense_quiver::Vector{BaseCatEdge}, logs)
    # println(logs)
    subscript(i) = join(Char(0x2080 + d) for d in reverse!(digits(i)))
    rules_learned = String[]
    labelled_sates = StateFact[]

    states = unique([a.source for a in dense_quiver])
    states_out = unique(
        [
            StateFact(:S, a.what.data) for a in dense_quiver
            if a.what.data ⊆ a.target.data
        ]
    )
    union!(states, states_out)

    for (i, s) in enumerate(states)
        push!(labelled_sates, StateFact(Symbol("\$\\factsymbol{S}_{$i}\$"), s.data))
    end

    function mapsaccordingly(out, in)
        function comp(x)
            # println("compare: ", x[1].name, "==", in.name)
            # println("compare: ", x[1].args , "==", in.data)
            # println("compare: ", x[2], "==", get(out.data,1, nothing))
            x[1].name == in.name && all(x[1].args .== in.data) && x[2] == get(out.data,1, nothing)
        end
        any(x -> comp(x), logs)
    end

    for arrow in dense_quiver
        lhs = filter(x-> x.data == arrow.source.data, labelled_sates)
        action_label = arrow.what 
        rhs = filter(x -> mapsaccordingly(x, action_label), labelled_sates)
        rhsr = filter(x -> length(rhs) == 1 ? true : x.data == action_label.data, rhs)
        rule = """
        $lhs
        -[ $action_label ]->
        $rhsr
        """
        if rule ∉ rules_learned
            push!(rules_learned, rule)
        end

    end
    return rules_learned
end


for a in process_to_tamarin(universal_base, logs)
    println(a)
end
