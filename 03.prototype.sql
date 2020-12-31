WITH	spike_parameters AS
	(
	SELECT	0.3 AS height, 0.1 AS width
	),
	spike_origin_vertices AS
	(
	SELECT	1 AS j, (0, 0, 1)::VEC3 AS origin_vertex
	UNION ALL
	SELECT	i + 2 AS j, (0, 0, 1 + height)::VEC3 + (SIN(2 * PI() * i / 3), COS(2 * PI() * i / 3), 0)::VEC3 * width AS origin_vertex
	FROM	spike_parameters
	CROSS JOIN
		GENERATE_SERIES(0, 2) i
	)
SELECT	*
FROM	spike_origin_vertices
