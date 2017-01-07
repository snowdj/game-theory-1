module KidneyExchange

    using Distributions, Graphs
    import Base: show
    import Distributions: pdf, rand

    export
        # blood_types.jl
        BloodType, BloodTypeDist,

        # pairs.jl
        Person, Patient, Donor, are_compatible,
        Pair, IncompatiblePair, CompatiblePair,

        # hospitals.jl

        # compatibility_graph.jl
        CompatibilityGraph, get_donors, get_patients, get_pair

        # allocations.jl

    include("blood_type.jl")
    include("pairs.jl")
    include("hospitals.jl")
    include("compatibility_graph.jl")
    include("allocations.jl")

end