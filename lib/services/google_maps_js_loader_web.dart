import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

Completer<void>? _loader;

bool _isGoogleMapsAvailable() {
  final google = globalContext['google'];
  if (google == null) return false;
  if (google is! JSObject) return false;
  return google['maps'] != null;
}

Future<void> _waitUntilAvailable({required Duration timeout}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    if (_isGoogleMapsAvailable()) return;
    await Future<void>.delayed(const Duration(milliseconds: 50));
  }
  throw TimeoutException('Google Maps JS chưa sẵn sàng sau ${timeout.inSeconds}s');
}

void _ensureScriptInjected({required String apiKey}) {
  final document = globalContext['document'];
  if (document == null || document is! JSObject) return;

  final existing = document.callMethod<JSAny?>(
    'querySelector'.toJS,
    'script[data-google-maps="true"]'.toJS,
  );
  if (existing != null) return;

  final script = document.callMethod<JSAny?>(
    'createElement'.toJS,
    'script'.toJS,
  );
  if (script == null || script is! JSObject) return;

  final encodedKey = Uri.encodeQueryComponent(apiKey);
  script['type'] = 'text/javascript'.toJS;
  script['async'] = true.toJS;
  script['defer'] = true.toJS;
  script['src'] = 'https://maps.googleapis.com/maps/api/js?key=$encodedKey'.toJS;
  script.callMethod<JSAny?>('setAttribute'.toJS, 'data-google-maps'.toJS, 'true'.toJS);

  final head = (document['head'] is JSObject) ? (document['head'] as JSObject) : null;
  (head ?? document).callMethod<JSAny?>('appendChild'.toJS, script);
}

Future<void> ensureGoogleMapsJsLoadedImpl({required String apiKey}) async {
  if (_isGoogleMapsAvailable()) return;

  _ensureScriptInjected(apiKey: apiKey);

  _loader ??= Completer<void>();
  if (_loader!.isCompleted) return;

  try {
    await _waitUntilAvailable(timeout: const Duration(seconds: 20));
    _loader!.complete();
  } catch (e) {
    final c = _loader!;
    _loader = null;
    if (!c.isCompleted) {
      c.completeError(e);
    }
    rethrow;
  }
}
