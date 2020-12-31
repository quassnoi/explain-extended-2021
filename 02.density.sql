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
	)
SELECT	MIN(hemisphere_neighbors), MAX(hemisphere_neighbors)
FROM	spikes s1
CROSS JOIN LATERAL
	(
	SELECT	COUNT(*) hemisphere_neighbors
	FROM	spikes s2
	WHERE	|((1, s1.theta, s1.phi)::SPHERICAL::VEC3 - (1, s2.theta, s2.phi)::SPHERICAL::VEC3) <= SQRT(2)
	) s2
