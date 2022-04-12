using DataGraphs
using Dictionaries
using Graphs

g = grid((4,))
dg = DataGraph{String,Symbol}(g)
@show !isassigned(dg, Edge(1, 2))
@show !isassigned(dg, 1 => 2)
@show !isassigned(dg, Edge(1 => 2))
@show !isassigned(dg, 1 => 3)
@show !isassigned(dg, 1)
@show !isassigned(dg, 2)
@show !isassigned(dg, 3)
@show !isassigned(dg, 4)

@show has_edge(dg, 1, 2)
@show has_edge(dg, 1 => 2)
@show !has_edge(dg, 1, 3)
@show !has_edge(dg, 1 => 3)
@show has_vertex(dg, 1)
@show has_vertex(dg, 4)
@show !has_vertex(dg, 0)
@show !has_vertex(dg, 5)

dg[1] = "V1"
dg[2] = "V2"
dg[3] = "V3"
dg[4] = "V4"
@show isassigned(dg, 1)
@show dg[1] == "V1"
@show dg[2] == "V2"
@show dg[3] == "V3"
@show dg[4] == "V4"

dg[1 => 2] = :E12
dg[2 => 3] = :E23
dg[Edge(3, 4)] = :E34
#@show isassigned(dg, (1, 2))
@show isassigned(dg, Edge(2, 3))
@show isassigned(dg, 3 => 4)
@show dg[Edge(1, 2)] == :E12
@show dg[2 => 3] == :E23
@show dg[3 => 4] == :E34
