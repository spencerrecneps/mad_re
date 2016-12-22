DROP TABLE IF EXISTS generated.parcels;
CREATE TABLE generated.parcels (
    id SERIAL PRIMARY KEY,
    geom geometry(polygon,2930),
    parcel_id TEXT,
    address TEXT,
    zoning TEXT,
    use_category TEXT,
    use_specific TEXT,
    value_land INTEGER,
    value_imprvmnt INTEGER,
    value_total INTEGER,
    acres FLOAT,
    sq_ft INTEGER,
    zone_id INTEGER
);

-- insert
INSERT INTO generated.parcels (
    geom, parcel_id, address, use_category, use_specific, value_land,
    value_imprvmnt, value_total, acres, sq_ft, zone_id
)
SELECT  geom,
        parcel,
        address,
        propertycl,
        propertyus,
        currentlan,
        currentimp,
        currenttot,
        acres,
        ST_Area(geom),
        (
            SELECT      z.id
            FROM        zoning_districts z
            WHERE       ST_Intersects(z.geom,gmd.geom)
            ORDER BY    ST_Area(ST_Intersection(z.geom,gmd.geom)) DESC
            LIMIT       1
        )
FROM    general_map_data gmd;

-- indexes
CREATE INDEX sidx_parcels_geom ON generated.parcels USING GIST (geom);
CREATE INDEX idx_parcels_zoneid ON generated.parcels (zone_id);
ANALYZE generated.parcels;

-- zoning
UPDATE  generated.parcels
SET     zoning = z.zoning_cod
FROM    zoning_districts z
WHERE   parcels.zone_id = z.id;
