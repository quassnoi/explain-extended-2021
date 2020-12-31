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
SELECT	*
FROM	spikes;
