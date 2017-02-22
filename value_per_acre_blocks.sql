-- create table
DROP TABLE IF EXISTS generated.value_per_acre_blocks;
CREATE TABLE generated.value_per_acre_blocks (
    id SERIAL PRIMARY KEY,
    geom geometry(multipolygon,2930),
    value_per_acre INTEGER
);

-- add blocks
INSERT INTO generated.value_per_acre_blocks (geom)
SELECT  ST_CollectionExtract(unnest(ST_ClusterWithin(geom,50)),3)
FROM    generated.value_per_acre;

-- index
CREATE INDEX idx_valpacblksgeom ON generated.value_per_acre_blocks USING GIST (geom);
ANALYZE generated.value_per_acre_blocks (geom);

-- value_per_acre
UPDATE  generated.value_per_acre_blocks
SET     value_per_acre = (
            SELECT  CASE    WHEN SUM(acres) = 0 THEN 0
                            ELSE SUM(value) / SUM(acres)
                            END
            FROM    value_per_acre
            WHERE   value_per_acre_blocks.geom && value_per_acre.geom
            AND     ST_Intersects(value_per_acre_blocks.geom,ST_Centroid(value_per_acre.geom))
        );
