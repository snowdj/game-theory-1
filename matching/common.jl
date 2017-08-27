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

function ispairstable(g::Game)
    if isa(g, OneToOneGame)
        side1 = g.men
        side2 = g.women
        mymatch = getmatch
        pronoun = "his"
    elseif isa(g, ManyToOneGame)
        side1 = g.colleges
        side2 = g.students
        pronoun = "its"
        mymatch = getleastpref
    end

    μ = g.matches

    for p in values(side1)
        for q in values(side2)
            if (!ismatched(p, μ) || prefers(p, q, mymatch(p, μ))) &&
                (!ismatched(q, μ) || prefers(q, p, getmatch(q, μ)))

                println("Blocking pair: ")

                print(" * " * string(p))
                !ismatched(p, μ) ? println(" is unmatched") :
                    println(" prefers " * string(q) * "to " * pronoun * " match, " * string(getmatch(p, μ)))

                print(" * " * string(q))
                !ismatched(q, μ) ? println(" is unmatched") :
                    println(" prefers " * string(p) * "to her match, " * string(getmatch(q, μ)))
                println()
                return false
            end
        end
    end

    println("No blocking pairs")
    println()
    return true
end
