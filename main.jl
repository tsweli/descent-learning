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
#because we don't actually learn this directly....
function serialize(t::Var)
    return string(t.name)
end

function serialize(t::Op)
    args = join([serialize(a) for a in t.args], ", ")
    return "$(t.name)($args)"
end

function serialize(f::Fact, is_persistent::Bool)
    prefix = is_persistent ? "!" : ""
    name = f.name
    data_str = f.data === nothing ? "" : join([serialize(d) for d in f.data], ", ")
    return "$prefix$name($data_str)"
end

function serialize_state(s::StateFact, is_persistent::Bool)
    if isempty(s.data) return "" end
    prefix = is_persistent ? "!" : ""
    data_str = join([serialize(d) for d in s.data], ", ")
    return "$prefix$(s.name)($data_str)"
end

function process_to_tamarin(edges::Vector{BaseCatEdge})
    fact_usage_count = Dict{Tuple{Symbol, Vector{Term}}, Int}()
    
    for e in edges
        k_what = (e.what.name, e.what.data === nothing ? Term[] : e.what.data)
        fact_usage_count[k_what] = get(fact_usage_count, k_what, 0) + 1
        
        # Count state facts
        k_src = (e.source.name, e.source.data)
        fact_usage_count[k_src] = get(fact_usage_count, k_src, 0) + 1
    end

    persistent_facts = Set([k for (k, v) in fact_usage_count if v > 1])

    function is_p(f::Fact)
        k = (f.name, f.data === nothing ? Term[] : (f isa StateFact ? f.data : f.data))
        return k in persistent_facts && f.name != :Fr # 'Fr' is never persistent in Tamarin
    end

    # Step B: Merge Edges by Source and Target
    # In the categorical view, these are components of the same state transition
    groups = Dict{Tuple{StateFact, StateFact}, Vector{BaseCatEdge}}()
    for e in edges
        key = (e.source, e.target)
        push!(get!(groups, key, BaseCatEdge[]), e)
    end

    # Step C: Generate Rules
    rules = String[]
    for (idx, ((src, tgt), group)) in enumerate(groups)
        premises = String[]
        actions = String[]
        conclusions = String[]

        # Add State Flow
        s_src = serialize_state(src, is_p(src))
        s_tgt = serialize_state(tgt, is_p(tgt))
        !isempty(s_src) && push!(premises, s_src)
        !isempty(s_tgt) && push!(conclusions, s_tgt)

        for e in group
            f_str = serialize(e.what, is_p(e.what))
            
            if e.what isa SpecialFact
                if e.what.name in (:In, :Fr)
                    push!(premises, f_str)
                elseif e.what.name == :Out
                    push!(conclusions, f_str)
                end
            elseif e.what isa ActionFact
                push!(actions, f_str)
            end
        end

        # Format Tamarin Rule
        l = join(unique(premises), ", ")
        a = join(unique(actions), ", ")
        r = join(unique(conclusions), ", ")
        
        push!(rules, """
        rule Learned_Rule_$idx:
        [ $l ]
        --[ $a ]->
        [ $r ]
    """)
    end

    return join(rules, "\n")
end

println(process_to_tamarin(universal_base))