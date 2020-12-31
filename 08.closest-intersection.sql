WITH	origin AS
	(
	SELECT	(0, 0, 0)::VEC3 AS origin
	),
	pixels AS
	(
	SELECT	*
	FROM	GENERATE_SERIES(-5, 4) x
	CROSS JOIN
		GENERATE_SERIES(-5, -4) y
	CROSS JOIN LATERAL
		(
		SELECT	||((x, y, 100)::VEC3) AS pixel_unit
		) pixel_unit
	),
	sphere AS
	(
	SELECT 120 AS radius, (0, 0, 300)::VEC3 AS center
	),
	spikes AS
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
	SELECT	i, j, vertex
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
	CROSS JOIN LATERAL
		(
		SELECT	(sphere.radius * rotated) + sphere.center AS vertex
		FROM	sphere
		) mapped
	),
	spike_triangles AS
	(
	SELECT	i,
		sv1.j + sv2.j + sv3.j - 5 AS j,
		sv1.vertex AS one, sv2.vertex AS two, sv3.vertex AS three
	FROM	spike_vertices sv1
	JOIN	spike_vertices sv2
	USING	(i)
	JOIN	spike_vertices sv3
	USING	(i)
	WHERE	sv2.j > sv1.j
		AND sv3.j > sv2.j
	),
	spike_intersections AS
	(
	SELECT	i, j, one, two, three, x, y, pixel_unit, intersection_distance
	FROM	pixels
	CROSS JOIN
		origin
	CROSS JOIN
		spike_triangles
	CROSS JOIN LATERAL
		(
		SELECT	two - one AS edge1, three - one AS edge2
		) edges
	CROSS JOIN LATERAL
		(
		SELECT	pixel_unit ** edge2 AS p_vector
		) normal
	CROSS JOIN LATERAL
		(
		SELECT	edge1 * p_vector AS determinant
		) det
	CROSS JOIN LATERAL
		(
		SELECT	origin - one AS t_vector
		) t
	CROSS JOIN LATERAL
		(
		SELECT	(t_vector * p_vector) / determinant AS u
		WHERE	determinant NOT BETWEEN -1e-8 AND 1e-8
		) u
	CROSS JOIN LATERAL
		(
		SELECT	t_vector ** edge1 AS q_vector
		WHERE	u BETWEEN 0 AND 1
		) q
	CROSS JOIN LATERAL
		(
		SELECT	(pixel_unit * q_vector) / determinant AS v
		) v
	CROSS JOIN LATERAL
		(
		SELECT	(edge2 * q_vector) / determinant AS intersection_distance
		WHERE	v >= 0 AND u + v <= 1
		) intersection
	),
	sphere_intersection_coefficients AS
	(
	SELECT	*
	FROM	pixels
	CROSS JOIN
		sphere
	CROSS JOIN
		origin
	CROSS JOIN LATERAL
		(
		SELECT	1 AS a, 2 * pixel_unit * (origin - center) AS b, (|(origin - center))^2 - radius^2 AS c
		) q3
	CROSS JOIN LATERAL
		(
		SELECT b ^ 2 - 4 * a * c AS discriminant
		) q4
	WHERE	discriminant > 0
	),
	sphere_intersections AS
	(
	SELECT	x, y, pixel_unit, intersection_distance
	FROM	sphere_intersection_coefficients
	CROSS JOIN LATERAL
		(
		SELECT	t AS intersection_distance
		FROM	(VALUES (1), (-1)) q (sign)
		CROSS JOIN LATERAL
			(
			SELECT	(-b + SQRT(discriminant) * sign) / (2 * a) AS t
			WHERE	discriminant > 0
			) q2
		WHERE	t > 0
		ORDER BY
			t
		LIMIT	1
		) q
	),
	closest_intersections AS
	(
	SELECT	object, i, j, x, y, pixel_unit, intersection_distance
	FROM	(
		SELECT	q.*,
			ROW_NUMBER() OVER (PARTITION BY x, y ORDER BY intersection_distance) rn
		FROM	(
			SELECT	'sphere' AS object, 0 AS i, 0 AS j, x, y, pixel_unit, intersection_distance
			FROM	sphere_intersections
			UNION ALL
			SELECT	'spike', i, j, x, y, pixel_unit, intersection_distance
			FROM	spike_intersections
			) q
		) q
	WHERE	rn = 1
	)
SELECT	*
FROM	closest_intersections
ORDER BY
	x, y