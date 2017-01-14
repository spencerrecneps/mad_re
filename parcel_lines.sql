-- create table
DROP TABLE IF EXISTS generated.parcel_lines;
CREATE TABLE generated.parcel_lines (
    id SERIAL PRIMARY KEY,
    geom geometry(linestring,2930),
    length_ft INTEGER
);

-- insert
WITH    boundaries AS (
    SELECT  id,
            (ST_Dump(ST_Boundary(geom))).geom
    FROM    parcels
),
        point_pairs AS (
    SELECT  id,
            ST_PointN(
                geom,
                generate_series(1,ST_NPoints(geom)-1)
            ) AS sp,
            ST_PointN(
                geom,
                generate_series(2,ST_NPoints(geom))
            ) AS ep
    FROM    boundaries
)
INSERT INTO generated.parcel_lines (geom)
SELECT DISTINCT ST_MakeLine(sp,ep)
FROM            point_pairs;

-- calculate lengths
UPDATE  parcel_lines
SET     length_ft = ST_Length(geom);

-- indexes
CREATE INDEX sidx_pcllines_geom ON generated.parcel_lines USING GIST (geom);
ANALYZE generated.parcel_lines;
