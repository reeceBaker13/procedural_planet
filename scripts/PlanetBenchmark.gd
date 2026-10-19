extends Node

var csv_file: FileAccess
var settings: PlanetSettings

func _ready():
    settings = load("res://Assets/default_planet.tres")
    
    csv_file = FileAccess.open(
        "res://planet_benchmark.csv",
        FileAccess.WRITE
    )

    csv_file.store_line(
		"subdivisions,vertices,triangles,generation_time_ms,vertices_per_ms,triangles_per_ms,vertex_growth,triangle_growth,time_growth"
    )

    run_benchmarks()

    csv_file.close()

    print("Benchmark complete.")
    print("CSV saved to: ", "res://planet_benchmark.csv")


func run_benchmarks():
    var previous_time = 0.0
    var previous_vertices = 0
    var previous_triangles = 0

    for subdivisions in range(2, 8):

        var terrain_chunk = preload("res://scenes/TerrainChunk.tscn").instantiate()
        add_child(terrain_chunk)

        var generation_time = terrain_chunk.setup(12345, settings)

        var vertices = terrain_chunk.sphere_vertices.size()
        var triangles = terrain_chunk.sphere_triangles.size()

        var vertices_per_ms = vertices / max(generation_time, 0.001)
        var triangles_per_ms = triangles / max(generation_time, 0.001)

        var vertex_growth = 0.0
        var triangle_growth = 0.0
        var time_growth = 0.0

        if previous_vertices > 0:
            vertex_growth = float(vertices) / previous_vertices
            triangle_growth = float(triangles) / previous_triangles
            time_growth = generation_time / previous_time

        csv_file.store_line(
            "%d,%d,%d,%.3f,%.2f,%.2f,%.2f,%.2f,%.2f" % [
                subdivisions,
                vertices,
                triangles,
                generation_time,
                vertices_per_ms,
                triangles_per_ms,
                vertex_growth,
                triangle_growth,
                time_growth
            ]
        )

        print(
            "Subdivision: ", subdivisions,
            " | Vertices: ", vertices,
            " | Triangles: ", triangles,
            " | Generation: ", generation_time, " ms",
            " | Vert/ms: ", vertices_per_ms,
            " | Tri/ms: ", triangles_per_ms
        )

        previous_time = generation_time
        previous_vertices = vertices
        previous_triangles = triangles

        terrain_chunk.queue_free()
