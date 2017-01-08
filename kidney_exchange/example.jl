include("kidney_exchange.jl")
using KidneyExchange

b_dist = BloodTypeDist(0.34, 0.04, 0.14, 0.48)
t_dist = PRADist(0.20, 0.02, 0.5)
graph = CompatibilityGraph(b_dist, t_dist, 5)

show(Graphs.vertices(graph))
println()
show(Graphs.edges(graph))
