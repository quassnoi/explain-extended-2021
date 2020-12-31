WITH	spikes AS
	(
	SELECT	i, spherical.*
	FROM	(
		SELECT	40 AS spikes
		) constants
	CROSS JOIN LATERAL
		GENERATE_SERIES(0, spikes - 1) AS i
	CROSS JOIN LATERAL
		(
		SELECT	ACOS(2 * i / spikes::DOUBLE PRECISION - 1) AS theta,
			PI() * (3 - SQRT(5)) * i AS phi
		) spherical
	),
	spike_parameters AS
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
	),
	spike_vertices AS
	(
	SELECT	i, rotated
	FROM	spikes
	CROSS JOIN
		spike_origin_vertices
	CROSS JOIN LATERAL
		(
		SELECT	((origin_vertex).x * COS(theta) + (origin_vertex).z * SIN(theta), (origin_vertex).y, (origin_vertex).z * COS(theta) - (origin_vertex).x * SIN(theta))::VEC3 AS rotated_y
		) y
	CROSS JOIN LATERAL
		(
		SELECT	((rotated_y).x * COS(phi) - (rotated_y).y * SIN(phi), (rotated_y).y * COS(phi) + (rotated_y).x * SIN(phi), (rotated_y).z)::VEC3 AS rotated
		) rotated
	)
SELECT	*
FROM	spike_vertices

