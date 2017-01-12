-- urban design district source data comes from
-- http://maps.cityofmadison.com/arcgis/rest/services/Planning/Zoning/MapServer/0
-- historic district source data comes from
-- http://maps.cityofmadison.com/arcgis/rest/services/Planning/Zoning/MapServer/1

DROP TABLE IF EXISTS generated.parcels;
CREATE TABLE generated.parcels (
    id SERIAL PRIMARY KEY,
    geom geometry(polygon,2930),
    parcel_id TEXT,
    address TEXT,
    zoning TEXT,
    urban_design_district TEXT,
    historic_district TEXT,
    use_category TEXT,
    use_specific TEXT,
    value_land INTEGER,
    value_imprvmnt INTEGER,
    value_total INTEGER,
    acres FLOAT,
    sq_ft INTEGER,
    zone_id INTEGER,
    udd_id INTEGER,
    hist_id INTEGER
);

-- insert
INSERT INTO generated.parcels (
    geom, parcel_id, address, use_category, use_specific, value_land,
    value_imprvmnt, value_total, acres, sq_ft, zone_id, udd_id, hist_id
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
        ),
        (
            SELECT      udd.id
            FROM        urban_design_districts udd
            WHERE       ST_Intersects(udd.geom,gmd.geom)
            AND         ST_Area(ST_Intersection(udd.geom,gmd.geom)) > (0.5 * ST_Area(gmd.geom))
            ORDER BY    ST_Area(ST_Intersection(udd.geom,gmd.geom)) DESC
            LIMIT       1
        ),
        (
            SELECT      h.id
            FROM        historic_districts h
            WHERE       ST_Intersects(h.geom,gmd.geom)
            AND         ST_Area(ST_Intersection(h.geom,gmd.geom)) > (0.5 * ST_Area(gmd.geom))
            ORDER BY    ST_Area(ST_Intersection(h.geom,gmd.geom)) DESC
            LIMIT       1
        )
FROM    general_map_data gmd;

-- indexes
CREATE INDEX sidx_parcels_geom ON generated.parcels USING GIST (geom);
CREATE INDEX idx_parcels_zoneid ON generated.parcels (zone_id);
CREATE INDEX idx_parcels_uddid ON generated.parcels (udd_id);
CREATE INDEX idx_parcels_histid ON generated.parcels (hist_id);
ANALYZE generated.parcels;

-- zoning
UPDATE  generated.parcels
SET     zoning = z.zoning_cod
FROM    zoning_districts z
WHERE   parcels.zone_id = z.id;

-- urban_design_district
UPDATE  generated.parcels
SET     urban_design_district = udd.long_name
FROM    urban_design_districts udd
WHERE   parcels.udd_id = udd.id;

-- historic_district
UPDATE  generated.parcels
SET     historic_district = h.long_name
FROM    historic_districts h
WHERE   parcels.hist_id = h.id;
