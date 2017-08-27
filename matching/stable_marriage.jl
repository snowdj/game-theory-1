abstract OneToOneAgent <: Agent

immutable Man <: OneToOneAgent
    id::Int
    prefs::Vector{Int}
end

immutable Woman <: OneToOneAgent
    id::Int
    prefs::Vector{Int}
end

type OneToOneMatching <: AbstractMatching
    d::OrderedDict{Man, Woman}
    unmatched_men::OrderedSet{Man}
    unmatched_women::OrderedSet{Woman}
end
function OneToOneMatching(men::OrderedSet{Man}, women::OrderedSet{Woman})
    d = OrderedDict{Man, Woman}()
    return OneToOneMatching(d, men, women)
end

function Base.string(μ::OneToOneMatching)
    id_pairs = [string(m.id) * "=>" * string(w.id) for (m, w) in μ.d]
    return "{" * join(id_pairs, ", ") * "}"
end

ismatched(m::Man, μ::OneToOneMatching) = m in keys(μ.d)
ismatched(w::Woman, μ::OneToOneMatching) = w in values(μ.d)

function getmatch(m::Man, μ::OneToOneMatching)
    if haskey(μ.d, m)
        return μ.d[m]
    else
        throw(UnmatchedError)
    end
end
function getmatch(w::Woman, μ::OneToOneMatching)
    for (m, w1) in μ.d
        w1 == w && return m
    end
    throw(UnmatchedError)
end

function match!(μ::OneToOneMatching, m::Man, w::Woman)
    @assert !ismatched(m, μ) (string(m) * " is already matched")
    @assert !ismatched(w, μ) (string(w) * " is already matched")
    delete!(μ.unmatched_men, m)
    delete!(μ.unmatched_women, m)
    μ.d[m] = w
end

function unmatch!(μ::OneToOneMatching, m::Man, w::Woman)
    @assert getmatch(m, μ) == w (string(m) * " and " * string(w) * " are not currently matched")
    delete!(μ.d, m)
    push!(μ.unmatched_men, m)
    push!(μ.unmatched_women, w)
end

type OneToOneGame <: Game
    round::Int
    men::OrderedDict{Int, Man}
    women::OrderedDict{Int, Woman}
    matches::OneToOneMatching
    next_proposals::OrderedDict{Man, Int}
end

function Base.rand(::Type{OneToOneGame}, n_men::Int, n_women::Int)
    men = OrderedDict{Int, Man}()
    for i = 1:n_men
        men[i] = Man(i, randperm(n_women))
    end

    women = OrderedDict{Int, Woman}()
    for j = 1:n_women
        women[j] = Woman(j, randperm(n_men))
    end

    matches = OneToOneMatching(OrderedSet(values(men)), OrderedSet(values(women)))
    next_proposals = OrderedDict(m => 1 for m in values(men))

    return OneToOneGame(0, men, women, matches, next_proposals)
end

function propose!(g::OneToOneGame, m::Man, w::Woman)
    print(" * " * string(m) * " proposes to " * string(w) * "... ")
    μ = g.matches
    @assert !ismatched(m, μ) (string(m) * " is already matched")
    @assert m.prefs[g.next_proposals[m]] == w.id (string(w) * " is not " * string(m) * "'s most-preferred remaining woman")
    g.next_proposals[m] += 1

    if ismatched(w, μ)
        m_old = getmatch(w, μ)
        if prefers(w, m, m_old)
            # Woman prefers new suitor
            unmatch!(μ, m_old, w)
            match!(μ, m, w)
            println("she accepts, discarding " * string(m_old))
            return true
        else
            # Woman prefers existing match
            println("she rejects, remaining with " * string(m_old))
            return false
        end
    else
        # Woman accepts first suitor
        match!(μ, m, w)
        println("she accepts")
        return true
    end
end

function iterate!(g::OneToOneGame)
    g.round += 1
    println("Start of round " * string(g.round) * ":")
    μ = g.matches

    # Need to copy, or else we'd be iterating through a set as some elements are
    # being deleted by `match!`
    for m in copy(μ.unmatched_men)
        if can_propose(m, g)
            w_id = m.prefs[g.next_proposals[m]]
            w = g.women[w_id]
            propose!(g, m, w)
        else
            println(" * " * string(m) * " has no more women to propose to")
        end
    end

    println("End of round " * string(g.round) * ":")
    println(" * Matches: " * string(g.matches))
    println(" * Unmatched men: " * string(μ.unmatched_men))
    println(" * Unmatched women: " * string(μ.unmatched_women))
    println()
end

function can_propose(m::Man, g::OneToOneGame)
    n_women = length(g.women)
    return g.next_proposals[m] <= n_women
end

function isdone(g::OneToOneGame)
    μ = g.matches

    all_matched = isempty(μ.unmatched_men)
    no_proposals = all(m -> !can_propose(m, g), μ.unmatched_men)

    return all_matched || no_proposals
end
