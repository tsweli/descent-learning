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

pretty_print("Walking Quiver (Rule Schema)", universal_base)
print_graph_to_file(fn,universal_base)