immutable Student <: Agent
    id::Int
    prefs::Vector{Int}
end

immutable College <: Agent
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

function Base.string(ss::SortedSet{Student, PrefOrdering{College}})
    ss_ids = [s.id for s in ss]
    return string(ss_ids)
end
function Base.string(μ::ManyToOneMatching)
    id_pairs = [string(c.id) * "=>" * string(ss) for (c, ss) in μ.d]
    return "{" * join(id_pairs, ", ") * "}"
end

function isfull(c::College, μ::ManyToOneMatching)
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
    @assert !isfull(c, μ) "College is already full"
    if !haskey(μ.d, c)
        μ.d[c] = SortedSet{Student, PrefOrdering{College}}(PrefOrdering{College}(c))
    end
    insert!(μ.d[c], s)
end

function unmatch!(μ::ManyToOneMatching, c::College, s::Student)
    @assert s in getmatch(c, μ) "College and student are not currently matched"
    delete!(μ.d[c], s)
end

type ManyToOneGame <: Game
    round::Int
    students::OrderedDict{Int, Student}
    colleges::OrderedDict{Int, College}
    matches::ManyToOneMatching
    next_proposals::OrderedDict{Student, Int}
end

function Base.rand(::Type{ManyToOneGame}, n_students::Int, n_colleges::Int,
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
    next_proposals = OrderedDict(s => 1 for s in values(students))

    return ManyToOneGame(0, students, colleges, matches, next_proposals)
end

function propose!(g::ManyToOneGame, s::Student, c::College)
    print(" * Student " * string(s.id) * " proposes to College " * string(c.id) * string("... "))
    μ = g.matches
    @assert !ismatched(s, μ)
    @assert s.prefs[g.next_proposals[s]] == c.id
    g.next_proposals[s] += 1

    if isfull(c, μ)
        s_old = getleastpref(c, μ)
        if prefers(c, s, s_old)
            # College prefers new student
            unmatch!(μ, c, s_old)
            match!(μ, c, s)
            println("it accepts, discarding Student " * string(s_old.id))
            return true
        else
            # College prefers least-preferred student in existing match
            println("it rejects, remaining with Student " * string(s_old.id))
            return false
        end
    else
        # College accepts student
        match!(μ, c, s)
        println("it accepts")
        return true
    end
end

function iterate!(g::ManyToOneGame)
    g.round += 1
    println("Start of round " * string(g.round) * ":")
    μ = g.matches

    unmatched_students = filter(s -> !ismatched(s, μ), values(g.students))
    for s in unmatched_students
        if can_propose(s, g)
            c_id = s.prefs[g.next_proposals[s]]
            c = g.colleges[c_id]
            propose!(g, s, c)
        else
            println(" * Student " * string(s.id) * " has no more colleges to propose to")
        end
    end

    unmatched_students = filter(s -> !ismatched(s, μ), values(g.students))
    unmatched_student_ids = map(s -> s.id, unmatched_students)
    open_colleges = filter(c -> !isfull(c, μ), values(g.colleges))
    open_college_ids = map(c -> c.id, open_colleges)

    println("End of round " * string(g.round) * ":")
    println(" * Matches: " * string(g.matches))
    println(" * Unmatched students: " * string(unmatched_student_ids))
    println(" * Colleges with seats available: " * string(open_college_ids))
    println()
end

function can_propose(s::Student, g::ManyToOneGame)
    n_colleges = length(g.colleges)
    return g.next_proposals[s] <= n_colleges
end

function isdone(g::ManyToOneGame)
    μ = g.matches

    all_matched = all(s -> ismatched(s, μ), values(g.students))

    unmatched_students = filter(s -> !ismatched(s, μ), values(g.students))
    no_proposals = all(s -> !can_propose(s, g), unmatched_students)

    return all_matched || no_proposals
end
