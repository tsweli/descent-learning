module MSRTranslation

import Base: convert
using ..CategoricalStructures

export covert, Rule


@enum LogicType Product Coproduct
@enum Availability Permanent Linear

#under construction

# struct Rule
#     action :: ActionFact
#     premise :: StateFact
#     conclusion :: StateFact
# end

# function Rule(a::BaseCatEdge)
#     conc = isempty(a.source.data) ? intersect(a.target.data, a.what.data) : a.target.data
#     return Rule(a.what, a.source, StateFact(:S,conc))
# end


# Base.show(io::IO, e::Rule) = print(io, "$(e.premise) -[$(e.action)]→ $(e.conclusion)")

end