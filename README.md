# Bathymetry Contour Processing and Visualization

This project automates the retrieval, processing, and visualization of bathymetry (underwater topography) data for New Jersey. The Makefile automates data downloading, contour generation, and uploading to a PostGIS database, while the `docker-compose` file sets up the database and supporting services. Finally, a web-based visualization is created using MapLibre GL to display the bathymetry data on a map.

## Project Structure

- **Makefile**: Manages downloading, processing, and uploading data.
- **docker-compose.yml**: Defines the environment, including a PostGIS database, Martin (tile server), and Node.js for visualization.
- **basic-map/app.js**: Implements a MapLibre GL map to visualize the bathymetry contours.

---

## Prerequisites

- **Docker & Docker Compose**: To orchestrate services (PostGIS, Martin, and Node).
- **Make**: For running the processing tasks.

## Setup

### Step 1: Start Services

To initiate the environment with PostgreSQL (PostGIS) and other services, run:
```bash
docker compose up -d
```

This will:
1. Start a PostGIS-enabled PostgreSQL instance to store contour data.
2. Start a Martin tile server to serve data as vector tiles.
3. Start a Node.js server to serve the MapLibre-based web application.

### Step 2: Process Bathymetry Data

Download bathymetry DEM data, generate contour data, and upload it to PostGIS:
```bash
make all
```

This sequence:
1. **Downloads TIFF files** from the NOAA server.
2. **Generates contour GeoJSON** from TIFF files using `gdal_contour`.
3. **Uploads GeoJSON** to PostGIS using `ogr2ogr`.
4. **Optimizes** the PostGIS table by indexing spatial data.

### Step 3: Visualize Data

Access the MapLibre visualization at:
```plaintext
http://localhost:5173
```

The application displays:
- **Base Map**: Provided by CARTO dark map tiles.
- **Bathymetry Contours**: Colored contours representing underwater elevation, styled based on depth.

---

## Makefile Commands

- **`make all`**: Complete pipeline (data download, contour generation, upload to PostGIS, optimization).
- **`make clean`**: Clears intermediate files (contours and uploads).
- **`make clean_all`**: Removes all generated data.

## Directory Structure

- **data/**: Contains subdirectories for raw TIFF files, generated contours, and uploads.
- **basic-map/**: Holds the MapLibre app code.
- **pgdata/**: Stores PostGIS data (mounted in Docker).

---

## Docker Compose Services

- **PostGIS** (`postgis`): Hosts the bathymetry contour data.
- **Martin** (`martin`): Tile server for vector tiles, accessible at `http://localhost:3000`.
- **Node.js** (`node`): Serves the MapLibre visualization app.

## Environment Variables

To customize PostgreSQL settings, adjust `POSTGRES_USER`, `POSTGRES_PASSWORD`, and `POSTGRES_DB` in `docker-compose.yml`.

