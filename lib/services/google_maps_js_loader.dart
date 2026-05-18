import 'google_maps_js_loader_stub.dart'
    if (dart.library.html) 'google_maps_js_loader_web.dart';

Future<void> ensureGoogleMapsJsLoaded({required String apiKey}) {
  return ensureGoogleMapsJsLoadedImpl(apiKey: apiKey);
}

