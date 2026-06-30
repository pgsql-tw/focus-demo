CREATE OR REPLACE FUNCTION business.normdist(
    x double precision,
    mean double precision,
    standard_dev double precision,
    cumulative boolean DEFAULT true
)
RETURNS double precision
LANGUAGE sql
IMMUTABLE
PARALLEL SAFE
RETURNS NULL ON NULL INPUT
AS $function$
WITH normalized AS (
    SELECT
        (x - mean) / NULLIF(standard_dev, 0.0) AS z,
        standard_dev AS standard_dev
),
normal_terms AS (
    SELECT
        z,
        standard_dev,
        abs(z) AS abs_z,
        1.0 / (1.0 + 0.2316419 * abs(z)) AS t,
        CASE
            WHEN abs(z) > 37.0 THEN 0.0
            ELSE exp(-0.5 * abs(z) * abs(z)) / sqrt(2.0 * pi())
        END AS standard_density
    FROM normalized
    WHERE standard_dev > 0.0
),
distribution AS (
    SELECT
        standard_density / standard_dev AS probability_density,
        CASE
            WHEN z > 37.0 THEN 1.0
            WHEN z < -37.0 THEN 0.0
            WHEN z >= 0.0 THEN
                1.0 - (
                    standard_density
                    * (
                        0.319381530 * t
                        - 0.356563782 * t ^ 2
                        + 1.781477937 * t ^ 3
                        - 1.821255978 * t ^ 4
                        + 1.330274429 * t ^ 5
                    )
                )
            ELSE
                standard_density
                * (
                    0.319381530 * t
                    - 0.356563782 * t ^ 2
                    + 1.781477937 * t ^ 3
                    - 1.821255978 * t ^ 4
                    + 1.330274429 * t ^ 5
                )
        END AS cumulative_probability
    FROM normal_terms
)
SELECT
    CASE
        WHEN cumulative THEN cumulative_probability
        ELSE probability_density
    END
FROM distribution;
$function$;

COMMENT ON FUNCTION business.normdist(double precision, double precision, double precision, boolean) IS
    '模擬 Excel NORM.DIST 函數：輸入 x、平均數、標準差與 cumulative 旗標，回傳常態分布的累積機率或機率密度。';
