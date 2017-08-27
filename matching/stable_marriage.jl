immutable Man <: Agent
    id::Int
    prefs::Vector{Int}
end

immutable Woman <: Agent
    id::Int
    prefs::Vector{Int}
end

type OneToOneMatching <: AbstractMatching
    d::OrderedDict{Man, Woman}
end
OneToOneMatching() = OneToOneMatching(OrderedDict{Man, Woman}())

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
    @assert !ismatched(m, μ) "Man is already matched"
    μ.d[m] = w
end

function unmatch!(μ::OneToOneMatching, m::Man, w::Woman)
    @assert getmatch(m, μ) == w "Man and woman are not currently matched"
    delete!(μ.d, m)
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

    matches = OneToOneMatching()
    next_proposals = OrderedDict(m => 1 for m in values(men))

    return OneToOneGame(0, men, women, matches, next_proposals)
end

function propose!(g::OneToOneGame, m::Man, w::Woman)
    print(" * Man " * string(m.id) * " proposes to Woman " * string(w.id) * "... ")
    μ = g.matches
    @assert !ismatched(m, μ)
    @assert m.prefs[g.next_proposals[m]] == w.id
    g.next_proposals[m] += 1

    if ismatched(w, μ)
        m_old = getmatch(w, μ)
        if prefers(w, m, m_old)
            # Woman prefers new suitor
            unmatch!(μ, m_old, w)
            match!(μ, m, w)
            println("she accepts, discarding Man " * string(m_old.id))
            return true
        else
            # Woman prefers existing match
            println("she rejects, remaining with Man " * string(m_old.id))
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

    unmatched_men = filter(m -> !ismatched(m, μ), values(g.men))
    for m in unmatched_men
        if can_propose(m, g)
            w_id = m.prefs[g.next_proposals[m]]
            w = g.women[w_id]
            propose!(g, m, w)
        else
            println(" * Man " * string(m.id) * " has no more women to propose to")
        end
    end

    unmatched_men = filter(m -> !ismatched(m, μ), values(g.men))
    unmatched_men_ids = map(m -> m.id, unmatched_men)
    unmatched_women = filter(w -> !ismatched(w, μ), values(g.women))
    unmatched_women_ids = map(w -> w.id, unmatched_women)

    println("End of round " * string(g.round) * ":")
    println(" * Matches: " * string(g.matches))
    println(" * Unmatched men: " * string(unmatched_men_ids))
    println(" * Unmatched women: " * string(unmatched_women_ids))
    println()
end

function can_propose(m::Man, g::OneToOneGame)
    n_women = length(g.women)
    return g.next_proposals[m] <= n_women
end

function isdone(g::OneToOneGame)
    μ = g.matches

    all_matched = all(m -> ismatched(m, μ), values(g.men))

    unmatched_men = filter(m -> !ismatched(m, μ), values(g.men))
    no_proposals = all(m -> !can_propose(m, g), unmatched_men)

    return all_matched || no_proposals
end