module CategoricalPlumbing

#assume we're in a category where products and coproducts coincincide. 

using MacroTools, ..CategoricalStructures, BipartiteMatching

export parse_to_exec_steps, gen_base_edge, empty_state, create_universal_objects

function build(x)::Term
    @capture(x, f_(a__)) ? 
        Op(Symbol(f), Term[build(arg) for arg in a]) : 
        Var(Symbol(x))
end

function parse_to_exec_steps(trace::AbstractString)
    trace |> 
        Meta.parse |> 
        (x -> (x isa Expr && x.head == :tuple) ? x.args : [x]) |>
        (args -> map(args) do e
            @capture(e, (op_expr_, out_)) ? 
                (build(op_expr), Var(Symbol(out))) : 
                error("Invalid ExecutionStep format")
        end)
end

function make_state(fact :: Tuple{Op, Var}) :: StateFact
        isempty(fact[1].args) ? StateFact(:S, [fact[2]]) :
        StateFact(:S, fact[1].args)
end

empty_state = StateFact(:S, Var[])

function gen_base_edge(parsed_trace :: Vector{Tuple{Op, Var}})
    dep(x,y) =  x[2] ∈ y[1].args
    n = length(parsed_trace)
    base_cat_edge = BaseCatEdge[]
    for i in 1:n
        for j in i+1:n
            if dep(parsed_trace[i], parsed_trace[j])
                the_data = !isempty(parsed_trace[i][1].args) ? 
                            parsed_trace[i][1].args : [parsed_trace[i][2]]
                push!(base_cat_edge, BaseCatEdge(
                   ActionFact(parsed_trace[i][1].name, 
                                the_data),
                   StateFact(:S, parsed_trace[i][1].args),
                   make_state(parsed_trace[j])
                ))

                if parsed_trace[j][1].name == :Out #forces adding the terminal object
                    push!(base_cat_edge, BaseCatEdge(
                    ActionFact(:Out, 
                                    parsed_trace[j][1].args),
                    make_state(parsed_trace[j]),
                    StateFact(:S, Var[])
                    ))
                end
            end
        end
    end
    return unique(base_cat_edge)
end

function states_eq(d::Dict{StateFact, Vector{ActionFact}}, s::StateFact, q:: StateFact)
     if length(s.data) != length(q.data) return false end 

    data_s = [k for act_f in d[s] for k in act_f.data]
    data_q = [k for act_f in d[q] for k in act_f.data]

    if length(data_s) != length(data_q) return false end 

    z = Dict(a => b for (a,b) in zip(data_s, data_q)) #unique map making universal
    return [ActionFact(act_f.name, map(x -> z[x], act_f.data)) for act_f in d[s]] == d[q]
end

function create_universal_objects(base_edges :: Vector{BaseCatEdge})

    state_to_actions_coproduct = Dict{StateFact, Vector{ActionFact}}()
    state_to_actions_product = Dict{StateFact, Vector{ActionFact}}()


    for edge in base_edges
        push!(get!(state_to_actions_product, edge.source, ActionFact[]), edge.what)
        push!(get!(state_to_actions_coproduct, edge.target, ActionFact[]), edge.what)
    end    
    
    states_coproduct = collect(keys(state_to_actions_coproduct))
    states_product = collect(keys(state_to_actions_product))
    
    btmtrx_source = BitMatrix([   
            i == j ? false : states_eq(state_to_actions_product, i,j)
            for i in states_product, j in states_product
        ])
    btmtrx_target = BitMatrix([   
            i == j ? false : states_eq(state_to_actions_coproduct, i, j)
            for i in states_coproduct, j in states_coproduct
        ])

    btmtrx = btmtrx_target .&& btmtrx_source

    d, _ = findmaxcardinalitybipartitematching(btmtrx)
    modifier = [k for (k,i) in d if k <= i] #tells me the index of what I should keep from matched
    to_remove = unique(vcat([states_product[i] for i in modifier], [states_coproduct[i] for i in modifier]))
    filter(b -> b.source ∉ to_remove && b.target ∉ to_remove, base_edges)

end


end 