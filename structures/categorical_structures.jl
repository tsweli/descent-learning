module CategoricalStructures

import Base: == 
export base_cat_edge_eq ,Var, Op, Fact, Term, ActionFact, SpecialFact, StateFact, BaseCatEdge

abstract type Fact end
abstract type Term end
abstract type Edge end

# handles == and hash for EVERYTHING that subtypes Fact or Term
# hash makes stuff like unique() work and == makes '==' work. 

for T in (Fact, Term, Edge)
    @eval begin
        Base.:(==)(a::T, b::T) where {T<:$T} = 
            all(f -> getfield(a, f) == getfield(b, f), fieldnames(typeof(a)))
        
        Base.hash(a::T, h::UInt) where {T<:$T} = 
            foldr(hash, [getfield(a, f) for f in fieldnames(typeof(a))], init=h)
    end
end

struct Var <: Term
    name::Symbol
end

struct Op <: Term
    name::Symbol
    args::Vector{Term}
end

struct ActionFact <: Fact
    name::Symbol
    data::Union{Vector{Var}, Nothing}
end

struct SpecialFact <: Fact
    name::Symbol
    data::Union{Vector{Var}, Nothing}
end

struct StateFact <: Fact
    name::Symbol
    data::Union{Vector{Var}, Nothing}
end

struct BaseCatEdge <: Edge
    what :: ActionFact
    source :: StateFact
    target :: StateFact
end



end