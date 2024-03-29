using DataGraphs
using Dictionaries
using Graphs
using NamedGraphs
using Suppressor
using Test

using DataGraphs: is_arranged

@testset "DataGraphs.jl" begin
  @testset "Examples" begin
    examples_path = joinpath(pkgdir(DataGraphs), "examples")
    @testset "Run examples: $filename" for filename in readdir(examples_path)
      if endswith(filename, ".jl")
        @suppress include(joinpath(examples_path, filename))
      end
    end
  end

  @testset "is_arranged" begin
    for (a, b) in [
      (1, 2),
      ([1], [2]),
      ([1, 2], [2, 1]),
      ([1, 2], [2]),
      ([2], [2, 1]),
      ((1,), (2,)),
      ((1, 2), (2, 1)),
      ((1, 2), (2,)),
      ((2,), (2, 1)),
      ("X", 1),
      (("X",), (1, 2)),
    ]
      @test is_arranged(a, b)
      @test !is_arranged(b, a)
    end
  end

  @testset "Basics" begin
    g = grid((4,))
    dg = DataGraph{<:Any,String,Symbol}(g)
    @test !isassigned(dg, Edge(1, 2))
    @test !isassigned(dg, 1 => 2)
    @test !isassigned(dg, Edge(1 => 2))
    @test !isassigned(dg, 1 => 3)
    @test !isassigned(dg, 1)
    @test !isassigned(dg, 2)
    @test !isassigned(dg, 3)
    @test !isassigned(dg, 4)

    @test degree(g, 1) == 1
    @test indegree(g, 1) == 1
    @test outdegree(g, 1) == 1
    @test degree(g, 2) == 2
    @test indegree(g, 2) == 2
    @test outdegree(g, 2) == 2

    @test has_edge(dg, 1, 2)
    @test has_edge(dg, 1 => 2)
    @test !has_edge(dg, 1, 3)
    @test !has_edge(dg, 1 => 3)
    @test has_vertex(dg, 1)
    @test has_vertex(dg, 4)
    @test !has_vertex(dg, 0)
    @test !has_vertex(dg, 5)

    dg[1] = "V1"
    dg[2] = "V2"
    dg[3] = "V3"
    dg[4] = "V4"
    @test isassigned(dg, 1)
    @test dg[1] == "V1"
    @test dg[2] == "V2"
    @test dg[3] == "V3"
    @test dg[4] == "V4"

    dg[1 => 2] = :E12
    dg[2 => 3] = :E23
    dg[Edge(3, 4)] = :E34
    #@test isassigned(dg, (1, 2))
    @test isassigned(dg, Edge(2, 3))
    @test isassigned(dg, 3 => 4)
    @test dg[Edge(1, 2)] == :E12
    @test dg[2 => 3] == :E23
    @test dg[3 => 4] == :E34

    # Regression test
    # g = NamedGraph([(1, 1), (1, (1, 1))])
    dg = DataGraph(NamedGraph([(1, 1), (1, (1, 1))]))
    dg[(1, 1) => (1, (1, 1))] = "X"
    @test dg[(1, 1) => (1, (1, 1))] == "X"

    vdata = map(v -> "V$v", Indices(1:4))
    edata = map(e -> "E$(src(e))$(dst(e))", Indices([Edge(1, 2), Edge(2, 3), Edge(3, 4)]))
    dg = DataGraph(g, vdata, edata)

    @test dg[1] == "V1"
    @test dg[2] == "V2"
    @test dg[3] == "V3"
    @test dg[4] == "V4"

    @test dg[1 => 2] == "E12"
    @test dg[2 => 3] == "E23"
    @test dg[3 => 4] == "E34"

    @test DataGraph(g) isa
      DataGraph{Int,Any,Any,SimpleGraph{Int},Graphs.SimpleGraphs.SimpleEdge{Int}}
    @test DataGraph{<:Any,String}(g) isa
      DataGraph{Int,String,Any,SimpleGraph{Int},Graphs.SimpleGraphs.SimpleEdge{Int}}
    @test DataGraph{<:Any,Any,String}(g) isa
      DataGraph{Int,Any,String,SimpleGraph{Int},Graphs.SimpleGraphs.SimpleEdge{Int}}

    # TODO: is this needed?
    #@test DataGraph{<:Any,String}(g) isa DataGraph{Any,String}

    # Vertices with mixed types
    dg = DataGraph(NamedGraph(grid((4,)), [1, "X", 2, "Y"]))
    @test nv(dg) == 4
    @test ne(dg) == 3
    dg[1] = "vertex_1"
    dg["X"] = "vertex_X"
    dg[2] = "vertex_2"
    dg["Y"] = "vertex_Y"
    @test dg[1] == "vertex_1"
    @test dg["X"] == "vertex_X"
    @test dg[2] == "vertex_2"
    @test dg["Y"] == "vertex_Y"

    dg[1 => "X"] = "edge_1X"
    dg["X" => 2] = "edge_X2"
    dg[2 => "Y"] = "edge_2Y"
    @test dg[1 => "X"] == "edge_1X"
    @test dg["X" => 1] == "edge_1X"
    @test dg["X" => 2] == "edge_X2"
    @test dg[2 => "X"] == "edge_X2"
    @test dg[2 => "Y"] == "edge_2Y"
    @test dg["Y" => 2] == "edge_2Y"

    dg["X" => 1] = "edge_X1"
    dg[2 => "X"] = "edge_2X"
    dg["Y" => 2] = "edge_Y2"
    @test dg[1 => "X"] == "edge_X1"
    @test dg["X" => 1] == "edge_X1"
    @test dg["X" => 2] == "edge_2X"
    @test dg[2 => "X"] == "edge_2X"
    @test dg[2 => "Y"] == "edge_Y2"
    @test dg["Y" => 2] == "edge_Y2"
  end

  @testset "Disjoint unions" begin
    g = DataGraph{<:Any,String,String}(named_grid((2, 2)))

    for v in vertices(g)
      g[v] = "V$v"
    end
    for e in edges(g)
      g[e] = "E$e"
    end

    gg = g ⊔ g

    @test has_vertex(gg, ((1, 1), 1))
    @test has_vertex(gg, ((1, 1), 2))
    @test has_edge(gg, ((1, 1), 1) => ((1, 2), 1))
    @test has_edge(gg, ((1, 1), 2) => ((1, 2), 2))
    @test nv(gg) == 2nv(g)
    @test ne(gg) == 2ne(g)

    # TODO: Define `vcat`, `hcat`, `hvncat`?
    gg = [g; g]

    @test_broken has_vertex(gg, (1, 1))
    @test_broken has_vertex(gg, (2, 1))
    @test_broken has_vertex(gg, (3, 1))
    @test_broken has_vertex(gg, (4, 1))
    @test_broken has_edge(gg, (1, 1) => (1, 2))
    @test_broken has_edge(gg, (3, 1) => (3, 2))
    @test_broken nv(gg) == 2nv(g)
    @test_broken ne(gg) == 2ne(g)

    gg = [g;; g]

    @test_broken has_vertex(gg, (1, 1))
    @test_broken has_vertex(gg, (1, 2))
    @test_broken has_vertex(gg, (1, 3))
    @test_broken has_vertex(gg, (1, 4))
    @test_broken has_edge(gg, (1, 1) => (1, 2))
    @test_broken has_edge(gg, (1, 3) => (1, 4))
    @test_broken nv(gg) == 2nv(g)
    @test_broken ne(gg) == 2ne(g)
  end

  @testset "union" begin
    g1 = DataGraph(grid((4,)))
    g1[1] = ["A", "B", "C"]
    g1[1 => 2] = ["E", "F"]

    g2 = DataGraph(Graph(5))
    add_edge!(g2, 1 => 5)
    g2[1] = ["C", "D", "E"]

    # Same as:
    # union(g1, g2; merge_data=(x, y) -> y)
    g = union(g1, g2)
    @test nv(g) == 5
    @test ne(g) == 4
    @test has_edge(g, 1 => 2)
    @test has_edge(g, 2 => 3)
    @test has_edge(g, 3 => 4)
    @test has_edge(g, 1 => 5)
    @test g[1] == ["C", "D", "E"]
    @test g[1 => 2] == ["E", "F"]

    g = union(g1, g2; merge_data=union)
    @test nv(g) == 5
    @test ne(g) == 4
    @test has_edge(g, 1 => 2)
    @test has_edge(g, 2 => 3)
    @test has_edge(g, 3 => 4)
    @test has_edge(g, 1 => 5)
    @test g[1] == ["A", "B", "C", "D", "E"]
    @test g[1 => 2] == ["E", "F"]
  end
  @testset "reverse" begin
    g = DataGraph(SimpleDiGraph(4))
    add_edge!(g, 1 => 2)
    add_edge!(g, 3 => 4)
    g[1 => 2] = :A
    g[3 => 4] = "X"
    rg = reverse(g)
    @test has_edge(rg, 2 => 1)
    @test has_edge(rg, 4 => 3)
    @test rg[2 => 1] == :A
    @test isassigned(rg, 2 => 1)
    @test !isassigned(rg, 1 => 2)
    @test rg[4 => 3] == "X"
    @test !isassigned(rg, 3 => 4)
    @test isassigned(rg, 4 => 3)
  end
  @testset "Tree traversal" begin
    g = DataGraph(named_grid(4))

    t = bfs_tree(g, 2)
    es = [2 => 1, 2 => 3, 3 => 4]
    @test t isa NamedDiGraph{Int}
    @test nv(t) == nv(g)
    @test ne(t) == nv(g) - 1
    @test all(e -> has_edge(t, e), es)

    t = dfs_tree(g, 2)
    @test t isa NamedDiGraph{Int}
    @test nv(t) == nv(g)
    @test ne(t) == nv(g) - 1
    @test all(e -> has_edge(t, e), es)

    g = DataGraph(named_grid((4, 2)))

    t = bfs_tree(g, (1, 1))
    es = [
      (1, 1) => (1, 2),
      (1, 1) => (2, 1),
      (2, 1) => (2, 2),
      (2, 1) => (3, 1),
      (3, 1) => (3, 2),
      (3, 1) => (4, 1),
      (4, 1) => (4, 2),
    ]
    @test t isa NamedDiGraph{Tuple{Int,Int}}
    @test nv(t) == nv(g)
    @test ne(t) == nv(g) - 1
    @test all(e -> has_edge(t, e), es)

    t = dfs_tree(g, (1, 1))
    es = [
      (1, 1) => (2, 1),
      (2, 1) => (3, 1),
      (3, 1) => (4, 1),
      (4, 1) => (4, 2),
      (4, 2) => (3, 2),
      (3, 2) => (2, 2),
      (2, 2) => (1, 2),
    ]
    @test t isa NamedDiGraph{Tuple{Int,Int}}
    @test nv(t) == nv(g)
    @test ne(t) == nv(g) - 1
    @test all(e -> has_edge(t, e), es)
  end
  @testset "dijkstra_shortest_paths" begin
    g = DataGraph(named_grid(4))
    ps = dijkstra_shortest_paths(g, [1])
    @test ps.dists == dictionary([1 => 0, 2 => 1, 3 => 2, 4 => 3])
    @test ps.parents == dictionary([1 => 1, 2 => 1, 3 => 2, 4 => 3])
    @test ps.pathcounts == dictionary([1 => 1.0, 2 => 1.0, 3 => 1.0, 4 => 1.0])
  end
end
