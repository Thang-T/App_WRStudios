class MapConfig {
  static const mapboxToken = String.fromEnvironment('MAPBOX_TOKEN', defaultValue: '');
  static const mapboxStyleId = String.fromEnvironment('MAPBOX_STYLE_ID', defaultValue: 'mapbox/streets-v12');
}

