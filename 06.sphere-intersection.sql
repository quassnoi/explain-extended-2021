WITH	origin AS
	(
	SELECT	(0, 0, 0)::VEC3 AS origin
	),
	sphere AS
	(
	SELECT 120 AS radius, (0, 0, 300)::VEC3 AS center
	),
	pixels AS
	(
	SELECT	*
	FROM	GENERATE_SERIES(-70, 70) x
	CROSS JOIN
		GENERATE_SERIES(-70, 70) y
	CROSS JOIN LATERAL
		(
		SELECT	||((x, y, 100)::VEC3) AS pixel_unit
		) pixel_unit
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
	)
SELECT	*
FROM	sphere_intersections
LIMIT 10;
