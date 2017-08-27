abstract ProposingType
type Proposing <: ProposingType end
type ProposedTo <: ProposingType end

abstract Agent

function Base.string{A<:Agent}(a::A)
    typename = replace(string(A), "Matching.", "")
    return typename * " " * string(a.id)
end
function Base.string{A<:Agent}(agents::Vector{A})
    agent_ids = map(a -> a.id, agents)
    isempty(agent_ids) ? "∅" : string(agent_ids)
end
Base.string{A<:Agent}(agents::OrderedSet{A}) = string(collect(agents))

abstract AbstractMatching

type UnmatchedError <: Exception end

abstract Game

function prefers{A<:Agent, B<:Agent}(w::A, m1::B, m2::B)
    @assert typeof(w) != typeof(m1)
    return findfirst(w.prefs, m1.id) < findfirst(w.prefs, m2.id)
end

type PrefOrdering{A<:Agent} <: Base.Ordering
    agent::A
end
Base.lt(o::PrefOrdering, a::Agent, b::Agent) = prefers(o.agent, a, b)

function play!(g::Game)
    while !isdone(g)
        iterate!(g)
    end
end
