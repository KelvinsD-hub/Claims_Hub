import 'dart:typed_data';

/// Opening a document in a browser tab — the build for platforms without one.
Object? openPendingTab() => null;

void showInTab(Object? tab, Uint8List bytes, String contentType) {}

void closeTab(Object? tab) {}
