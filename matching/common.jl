abstract ProposingType
type Proposing <: ProposingType end
type ProposedTo <: ProposingType end

abstract Agent

abstract AbstractMatching

type UnmatchedError <: Exception end

abstract Game

function prefers(w::Agent, m1::Agent, m2::Agent)
    @assert typeof(w) != typeof(m1)
    @assert typeof(m1) == typeof(m2)
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
