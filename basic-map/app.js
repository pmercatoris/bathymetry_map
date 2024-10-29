import maplibregl from "maplibre-gl";

new maplibregl.Map({
  container: "map-container",
  style: {
    version: 8,
    sources: {
      carto: {
        type: "raster",
        tiles: [
          "https://basemaps.cartocdn.com/rastertiles/dark_all/{z}/{x}/{y}@2x.png",
        ],
        tileSize: 256,
      },
      bathymetry: {
        type: "vector",
        tiles: ["http://localhost:3000/bathymetry_contours/{z}/{x}/{y}"],
        minzoom: 5,
        maxzoom: 15,
      },
    },
    layers: [
      {
        id: "basemap",
        type: "raster",
        source: "carto",
      },
      {
        id: "bathymetry-contours",
        type: "fill",
        source: "bathymetry",
        "source-layer": "bathymetry_contours",
        paint: {
          "fill-color": [
            "interpolate",
            ["linear"],
            ["get", "depth"],
            -8,
            "#0000FF",
            -4,
            "#0000CD",
            0,
            "#87CEFA",
            0.1,
            "#008000",
            7,
            "#FFFF00",
            15,
            "#FF4500",
            30,
            "#FF0000",
          ],
          "fill-opacity": 0.6,
        },
      },
    ],
  },
  center: [-74.73616323130763, 39.07913073723607],
  zoom: 12,
});
