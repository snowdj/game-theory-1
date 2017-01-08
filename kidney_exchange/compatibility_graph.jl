typealias CompatibilityGraph Graph{IncompatiblePair, CompatiblePair}

"""
```
get_donors(graph::CompatibilityGraph)
```

Given a `CompatibilityGraph`, return a vector of `Donor`s.
"""
function get_donors(graph::CompatibilityGraph)
    return [pair.donor for pair in Graphs.vertices(graph)]
end

"""
```
get_patients(graph::CompatibilityGraph)
```

Given a `CompatibilityGraph`, return a vector of `Patient`s.
"""
function get_patients(graph::CompatibilityGraph)
    return [pair.patient for pair in Graphs.vertices(graph)]
end

"""
```
get_pair(graph::CompatibilityGraph, donor::Donor)
```

Return the `Pair` in `graph` containing `donor`.
"""
function get_pair(graph::CompatibilityGraph, donor::Donor)
    for pair in Graphs.vertices(graph)
        if pair.donor == donor
            return pair
        end
    end
end

"""
```
get_pair(graph::CompatibilityGraph, patient::Patient)
```

Return the `Pair` in `graph` containing `patient`.
"""
function get_pair(graph::CompatibilityGraph, patient::Patient)
    for pair in Graphs.vertices(graph)
        if pair.patient == patient
            return pair
        end
    end
end

"""
```
CompatibilityGraph(b_dist::BloodTypeDist, t_dist::PRADist, n_vertices::Int)
```

Initialize a random `Compatibility Graph`, where there are `n_vertices`
incompatible pairs. All participants' blood types are drawn from blood type
distribution `b_dist`, while patients' PRAs are drawn from tissue type
distribution `t_dist`.
"""
function CompatibilityGraph(b_dist::BloodTypeDist, t_dist::PRADist, n_vertices::Int)
    # Initialize vertices
    vertices = Vector{IncompatiblePair}(n_vertices)
    for i = 1:n_vertices
        vertices[i] = IncompatiblePair(i, i, b_dist, t_dist)
    end

    # Initialize graph without edges
    graph = Graphs.graph(vertices, Vector{CompatiblePair}();
                is_directed = true)

    # Add edges by finding compatible pairs
    for donor in get_donors(graph)
        for patient in get_patients(graph)
            if are_compatible(donor, patient)
                from_pair = get_pair(graph, donor)
                to_pair   = get_pair(graph, patient)
                edge      = CompatiblePair(donor, patient)
                add_edge!(graph, from_pair, to_pair, edge)
            end
        end
    end

    return graph
end
