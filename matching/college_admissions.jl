abstract ManyToOneAgent <: Agent

immutable Student <: ManyToOneAgent
    id::Int
    prefs::Vector{Int}
end

immutable College <: ManyToOneAgent
    id::Int
    prefs::Vector{Int}
    capacity::Int

    function College(id::Int, prefs::Vector{Int}, capacity::Int)
        @assert capacity > 0 "Colleges must have positive capacity"
        return new(id, prefs, capacity)
    end
end

type ManyToOneMatching <: AbstractMatching
    d::OrderedDict{College, SortedSet{Student, PrefOrdering{College}}}
end
function ManyToOneMatching()
    d = OrderedDict{College, SortedSet{Student, PrefOrdering{College}}}()
    return ManyToOneMatching(d)
end

function Base.string(μ::ManyToOneMatching)
    id_pairs = [string(c.id) * "=>" * string(collect(ss)) for (c, ss) in μ.d]
    return "{" * join(id_pairs, ", ") * "}"
end

function ismatched(c::College, μ::ManyToOneMatching)
    return c in keys(μ.d) && length(μ.d[c]) == c.capacity
end
ismatched(s::Student, μ::ManyToOneMatching) = any(ss -> s in ss, values(μ.d))

function getmatch(c::College, μ::ManyToOneMatching)
    if haskey(μ.d, c)
        return μ.d[c]
    else
        throw(UnmatchedError)
    end
end
function getmatch(s::Student, μ::ManyToOneMatching)
    for (c, ss) in μ.d
        s in ss && return c
    end
    throw(UnmatchedError)
end

getleastpref(c::College, μ::ManyToOneMatching) = last(μ.d[c])

function match!(μ::ManyToOneMatching, c::College, s::Student)
    @assert !ismatched(c, μ) (string(c) * " is already full")
    @assert !ismatched(s, μ) (string(s) * " is already matched")
    if !haskey(μ.d, c)
        μ.d[c] = SortedSet{Student, PrefOrdering{College}}(PrefOrdering{College}(c))
    end
    insert!(μ.d[c], s)
end
match!(μ::ManyToOneMatching, s::Student, c::College) = match!(μ, c, s)

function unmatch!(μ::ManyToOneMatching, c::College, s::Student)
    @assert s in getmatch(c, μ) (string(c) * " and " * string(s) * " are not currently matched")
    delete!(μ.d[c], s)
end
unmatch!(μ::ManyToOneMatching, s::Student, c::College) = unmatch!(μ, c, s)

type ManyToOneGame{A<:ManyToOneAgent} <: Game
    round::Int
    students::OrderedDict{Int, Student}
    colleges::OrderedDict{Int, College}
    matches::ManyToOneMatching
    next_proposals::OrderedDict{A, Int}
end

function Base.rand{A<:ManyToOneAgent}(::Type{ManyToOneGame{A}},
                                      n_students::Int, n_colleges::Int,
                                      capacity::Int)

    students = OrderedDict{Int, Student}()
    for i = 1:n_students
        students[i] = Student(i, randperm(n_colleges))
    end

    colleges = OrderedDict{Int, College}()
    for j = 1:n_colleges
        colleges[j] = College(j, randperm(n_students), capacity)
    end

    matches = ManyToOneMatching()

    if A == Student
        proposers = values(students)
    elseif A == College
        proposers = values(colleges)
    end
    next_proposals = OrderedDict{A, Int}(p => 1 for p in proposers)

    return ManyToOneGame(0, students, colleges, matches, next_proposals)
end

function propose!{A<:ManyToOneAgent, B<:ManyToOneAgent}(g::ManyToOneGame{A},
                                                        p::A, q::B)
    print(" * " * string(p) * " proposes to " * string(q) * "... ")
    @assert typeof(p) != typeof(q) (string(p) * " and " * string(q) * " cannot be of the same type")

    if A == Student
        proposee_string = "college"
        pronoun_string = "it"
        leastmatch = getleastpref
    elseif A == College
        proposee_string = "student"
        pronoun_string = "she"
        leastmatch = getmatch
    end

    μ = g.matches
    @assert !ismatched(p, μ) (string(p) * " is already matched")
    @assert p.prefs[g.next_proposals[p]] == q.id (string(q) * " is not " * string(p) * "'s most-preferred remaining " * proposee_string)
    g.next_proposals[p] += 1

    if ismatched(q, μ)
        p_old = leastmatch(q, μ)
        if prefers(q, p, p_old)
            # Proposee prefers new proposer
            unmatch!(μ, p_old, q)
            match!(μ, p, q)
            println(pronoun_string * " accepts, discarding " * string(p_old))
            return true
        else
            # Proposee prefers existing match(es)
            println(pronoun_string * " rejects, remaining with " * string(p_old))
            return false
        end
    else
        # Proposee accepts proposal
        match!(μ, p, q)
        println(pronoun_string * " accepts")
        return true
    end
end

function iterate!{A<:ManyToOneAgent}(g::ManyToOneGame{A})
    g.round += 1
    println("Start of round " * string(g.round) * ":")
    μ = g.matches

    if A == Student
        proposers = g.students
        proposees = g.colleges
        proposee_string = "colleges"
    elseif A == College
        proposers = g.colleges
        proposees = g.students
        proposee_string = "students"
    end

    unmatched_proposers = filter(p -> !ismatched(p, μ), values(proposers))
    for p in unmatched_proposers
        if can_propose(p, g)
            q_id = p.prefs[g.next_proposals[p]]
            q = proposees[q_id]
            propose!(g, p, q)
        else
            println(" * " * string(p) * " has no more " * proposee_string * " to propose to")
        end
    end

    unmatched_students = collect(filter(s -> !ismatched(s, μ), values(g.students)))
    open_colleges = collect(filter(c -> !ismatched(c, μ), values(g.colleges)))

    println("End of round " * string(g.round) * ":")
    println(" * Matches: " * string(g.matches))
    println(" * Unmatched students: " * string(unmatched_students))
    println(" * Colleges with seats available: " * string(open_colleges))
    println()
end

function can_propose(s::Student, g::ManyToOneGame{Student})
    n_colleges = length(g.colleges)
    return g.next_proposals[s] <= n_colleges
end

function can_propose(s::College, g::ManyToOneGame{College})
    n_students = length(g.students)
    return g.next_proposals[s] <= n_students
end

function isdone{A<:ManyToOneAgent}(g::ManyToOneGame{A})
    μ = g.matches
    if A == Student
        proposers = g.students
    elseif A == College
        proposers = g.colleges
    end

    all_matched = all(p -> ismatched(p, μ), values(proposers))

    unmatched_proposers = filter(p -> !ismatched(p, μ), values(proposers))
    no_proposals = all(p -> !can_propose(p, g), unmatched_proposers)

    return all_matched || no_proposals
end
