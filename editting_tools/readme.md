# Guide to editting subregions

1. Draw rough polygons in software of choice (e.g., Google Earth, QGIS, ArcGIS) and save in any geospatial format.
2. Open in QGIS and use [Geometry Editting Tools](https://docs.qgis.org/3.22/en/docs/user_manual/working_with_vector/editing_geometry_attributes.html) to snap borders with neighbouring polygons. The following tools are helpful to draw new or edit existing polygons:

	- Snapping with advanced configuration (snap to other layers and polygons)
	- Automatic tracing (for following other lines)
	- Vertex tool (move, snap, add, and remove vertices)

3. Load `canadian_subregions.geojson` in QGIS Editing mode and copy and paste new polygons. Update `polygon_name`, `creation_date`, and `last_updated` properties in the attribute table. Other attributes can be added automatically in step 5. The Geometry Paster plugin can be used to copy and paste a new polygon without overwriting attributes.
4. Validate and correct geometry with the QGIS [Topology Checker Plugin](https://docs.qgis.org/3.22/en/docs/user_manual/plugins/core_plugins/plugins_topology_checker.html). Helpful rules include:

	- Must not have duplicates
	- Must not have gaps
	- Must not have invalid geometries
	- Must not overlap

	Any errors can be corrected with Geometry Editting Tools.

5. Run the `subregion_metadata.R` script to automatically fill other required properties, centroids, and geometry corrections. This will write a file `canadian_subregions_updated.geojson`
6. Perform final validation test with [GeoJSONLint](https://geojsonlint.com/).
7. If content with updates then replace the official geojson file `mv canadian_subregions_updated.geojson canadian_subregions.geojson`.
8. Run `conversions.sh` to produce copies with different formats and subsets.
