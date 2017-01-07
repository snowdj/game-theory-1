include("kidney_exchange.jl")
using KidneyExchange

dist = BloodTypeDist(0.34, 0.04, 0.14, 0.48)
graph = CompatibilityGraph(dist, 5)

show(Graphs.vertices(graph))
println()
show(Graphs.edges(graph))
