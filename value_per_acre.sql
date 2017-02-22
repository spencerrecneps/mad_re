-- create table
DROP TABLE IF EXISTS generated.value_per_acre;
CREATE TABLE generated.value_per_acre (
    id SERIAL PRIMARY KEY,
    geom geometry(polygon,2930),
    parcel_id TEXT,
    value INTEGER,
    acres FLOAT,
    value_per_acre INTEGER
);

-- add pins
INSERT INTO generated.value_per_acre (parcel_id, geom, value, acres, value_per_acre)
SELECT  parcel_id,
        geom,
        value_total,
        acres,
        CASE    WHEN acres = 0 AND ST_Area(geom) = 0 THEN 0
                WHEN acres = 0 THEN ( value_total / ST_Area(geom) ) / 43560
                ELSE value_total / acres
                END
FROM    parcels;

-- index
CREATE INDEX idx_parclids ON generated.value_per_acre (parcel_id);
CREATE INDEX sidx_pclgeoms ON generated.value_per_acre USING GIST (geom);
ANALYZE generated.value_per_acre;
