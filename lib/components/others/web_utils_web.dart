import 'dart:js_interop';

@JS('window.open')
external void openNewTab(String url, String name);
