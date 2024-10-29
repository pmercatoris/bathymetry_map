# Set the base data directory
DATA_DIR = data
RAW_DIR = $(DATA_DIR)/raw
CONTOUR_DIR = $(DATA_DIR)/contour
UPLOAD_DIR = $(DATA_DIR)/upload

# Ensure Make treats these as precious files and doesn't delete them automatically
.PRECIOUS: $(RAW_DIR)/%.tif

# Set the list of TIFF files to download
TIFF_FILES = $(shell curl -s https://noaa-nos-coastal-lidar-pds.s3.amazonaws.com/dem/USACE_NJ_NY_DEM_2022_9851/nj/index.html | grep -oP 'href="\K[^"]+\.tif')

# PostgreSQL connection parameters
PG_HOST = localhost
PG_USER = myuser
PG_PORT = 5433
PG_DB = mydb
PG_PASSWORD = mypassword
PG_TABLE = bathymetry_contours  # Table to store each JSON as a new layer
PG_DATA_DIR = pg_data

# Default target to download all TIFF files, create contours, upload to PostGIS, and optimize the table
all: $(patsubst %.tif,$(UPLOAD_DIR)/%.json.upload,$(TIFF_FILES)) optimize_postgis

# Rule to download TIFF files into the data directory
$(RAW_DIR)/%.tif:
	@mkdir -p $(dir $@)  # Create the full directory structure for the TIFF file
	curl -o $@ https://noaa-nos-coastal-lidar-pds.s3.amazonaws.com/dem/USACE_NJ_NY_DEM_2022_9851/nj/$*.tif --no-progress-meter

# Rule to create contours from the DEM using Dockerized gdal_contour
$(CONTOUR_DIR)/%.json: $(RAW_DIR)/%.tif
	@mkdir -p $(dir $@)  # Create the full directory structure for the output file
	@docker run --rm -v $(PWD):/data osgeo/gdal:ubuntu-full-3.6.3 \
		gdal_contour -i 0.5 -amax depth -p -f "GeoJSON" /data/$< /data/$@

# Rule to upload each JSON file to PostGIS using Dockerized ogr2ogr
$(UPLOAD_DIR)/%.json.upload: $(CONTOUR_DIR)/%.json
	@mkdir -p $(dir $@)  # Ensure upload directory exists
	@docker run --rm --network="host" -v $(PWD):/data osgeo/gdal:ubuntu-full-3.6.3 \
		ogr2ogr -f "PostgreSQL" PG:"host=$(PG_HOST) user=$(PG_USER) dbname=$(PG_DB) password=$(PG_PASSWORD) port=$(PG_PORT)" \
		/data/$< -nln $(PG_TABLE) -lco GEOMETRY_NAME=geom -t_srs EPSG:4326
	@touch $@  # Create an empty .upload file to mark the target as done

# Optimize the PostGIS table by creating a spatial index and running ANALYZE and VACUUM
optimize_postgis:
	@docker run --rm --network="host" -v $(PWD):/data -e PGPASSWORD=$(PG_PASSWORD) osgeo/gdal:ubuntu-full-3.6.3 \
	psql -h $(PG_HOST) -U $(PG_USER) -d $(PG_DB) -p $(PG_PORT) -c \
		"CREATE INDEX IF NOT EXISTS bathymetry_contours_geom_idx ON bathymetry_contours USING GIST(geom); \
		ANALYZE bathymetry_contours; \
		VACUUM bathymetry_contours;"

# Clean up the data directory
clean:
	rm -rf $(CONTOUR_DIR)/* $(UPLOAD_DIR)/*
	rm -rf $(PG_DATA_DIR)/*

# Clean up the data directory and remove all downloaded files
clean_all: clean
	rm -rf $(DATA_DIR)/*
