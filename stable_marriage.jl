abstract Person

"""
```
Man(id, prefs)
```

### Fields

- `id::Int`
- `prefs::Vector{Int}`: ordered list of women's IDs, where `prefs[1]` is the
  man's most-preferred woman and `prefs[end]` his least
- `match::Nullable{Int}`: if not null, `get(match)` is the ID of the woman to
  whom the man is currently matched
- `next_proposal::Int`: the man will next propose to the woman whose ID is
  `prefs[next_proposal]`
"""
type Man <: Person
    id::Int
    prefs::Vector{Int}
    match::Nullable{Int}
    next_proposal::Int
end

Man(id::Int, prefs::Vector{Int}) = Man(id, prefs, Nullable{Int}(), 1)

"""
```
Woman(id, prefs)
```

### Fields

- `id::Int`
- `prefs::Vector{Int}`: ordered list of men's IDs, where `prefs[1]` is the
  woman's most-preferred man and `prefs[end]` her least
- `match::Nullable{Int}`: if not null, `get(match)` is the ID of the man to whom
  the woman is currently matched
"""
type Woman <: Person
    id::Int
    prefs::Vector{Int}
    match::Nullable{Int}
end

Woman(id::Int, prefs::Vector{Int}) = Woman(id, prefs, Nullable{Int}())

"""
```
ismatched(p::Person)
```
Returns `true` is `p` is matched.
"""
ismatched(p::Person) = !isnull(p.match)

"""
```
prefers(w::Woman, m1::Man, m2::Man)
```

Returns `true` if `w` prefers `m1` to `m2`.
"""
function prefers(w::Woman, m1::Man, m2::Man)
    return findfirst(w.prefs, m1.id) < findfirst(w.prefs, m2.id)
end

"""
```
Game(N)
```

### Fields

- `N::Int`: number of men (and number of women)
- `round::Int`
- `men::Vector{Man}`
- `women::Vector{Woman}`
"""
type Game
    N::Int
    round::Int
    men::Vector{Man}
    women::Vector{Woman}
end

function Game(N::Int)
    men   = Vector{Man}(N)
    women = Vector{Woman}(N)
    for i = 1:N
        men[i]   = Man(i, randperm(N))
        women[i] = Woman(i, randperm(N))
    end

    return Game(N, 0, men, women)
end

"""
```
propose!(g::Game, m::Man, w::Woman)
```

Increments `m.next_proposal` and returns `true` if `m` successfully proposes to
`w`. Updates the `match` fields of `m`, `w`, and `g.men[get(w.match)]`
(i.e. `w`'s old match, if necessary) to reflect new matches.
"""
function propose!(g::Game, m::Man, w::Woman)
    print("* Man $(m.id) proposes to Woman $(w.id)... ")
    @assert !ismatched(m)
    @assert m.prefs[m.next_proposal] == w.id
    m.next_proposal += 1

    if ismatched(w)
        m_old = g.men[get(w.match)]
        if prefers(w, m, m_old)
            # Woman prefers new suitor
            w.match = Nullable(m.id)
            m.match = Nullable(w.id)
            m_old.match = Nullable{Int}()
            println("she accepts, discarding Man $(m_old.id)")
            return true
        else
            # Woman prefers existing match
            println("she rejects, remaining with Man $(m_old.id)")
            return false
        end
    else
        # Woman accepts first suitor
        w.match = Nullable(m.id)
        m.match = Nullable(w.id)
        println("she accepts")
        return true
    end
end

"""
```
find_matches(g::Game)
```

Returns a vector of tuples indicating the IDs of the men and women who are
currently matched in `g`.
"""
function find_matches(g::Game)
    matched_men_ids = find(m -> ismatched(m), g.men)
    matched_men = g.men[matched_men_ids]
    return [(m.id, get(m.match)) for m in matched_men]
end

"""
```
iterate!(g::Game)
```

Executes one iteration of the deferred acceptance algorithm:

1. Each of the unmatched men proposes to his most-preferred woman to whom he has
   not yet proposed (i.e. to the women whose ID is `m.prefs[m.next_proposal]`).
2. If she accepts (i.e. he is her most-preferred man who has already proposed to
   her), he is tentatively matched to her.
3. If she rejects him, then he proposes again to the next woman on his list.
4. This continues until all of the unmatched men are either matched or have run
   out of women to propose to.
"""
function iterate!(g::Game)
    g.round += 1
    println("Start of round $(g.round):")

    unmatched_men_ids = find(m -> !ismatched(m), g.men)
    unmatched_men = g.men[unmatched_men_ids]
    for m in unmatched_men
        unproposed_women_inds = m.prefs[m.next_proposal:end]
        unproposed_women = g.women[unproposed_women_inds]
        for w in unproposed_women
            success = propose!(g, m, w)
            success ? break : nothing
        end
    end

    unmatched_men_ids   = find(m -> !ismatched(m), g.men)
    unmatched_women_ids = find(w -> !ismatched(w), g.women)

    println("End of round $(g.round):")
    println("* Matches: $(find_matches(g))")
    println("* Unmatched men: $unmatched_men_ids")
    println("* Unmatched women: $unmatched_women_ids")
    println()
end

"""
```
isdone(g::Game)
```

Returns `true` if all men and women in `g` are matched.
"""
function isdone(g::Game)
    return all(ismatched, g.men) && all(ismatched, g.women)
end

"""
```
play!(g::Game)
```

Executes the Gale-Shapley deferred acceptance algorithm.
"""
function play!(g::Game)
    while !isdone(g)
        iterate!(g)
    end
end