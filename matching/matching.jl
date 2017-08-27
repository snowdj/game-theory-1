module Matching

using DataStructures: OrderedDict, OrderedSet, SortedSet

export
    ismatched, getmatch, propose!, iterate!, play!,

    # Stable marriage
    Man, Woman, OneToOneMatching, OneToOneGame,

    # College admissions
    Student, College, ManyToOneMatching, ManyToOneGame, getleastpref

include("common.jl")
include("stable_marriage.jl")
include("college_admissions.jl")

end # of module
