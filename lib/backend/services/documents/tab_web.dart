import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

/// Opening a document in a browser tab.
///
/// A browser only lets a page open a tab while it is handling a click, and
/// the document arrives later. So the tab is opened empty during the click
/// ([openPendingTab]) and pointed at the document when it has been fetched
/// ([showInTab]).
Object? openPendingTab() {
  final tab = web.window.open('', '_blank');
  tab?.document.title = 'Opening document…';
  return tab;
}

/// Show [bytes] in the tab opened by [openPendingTab]. The document exists
/// only in this browser's memory; the address in the tab works nowhere else.
void showInTab(Object? tab, Uint8List bytes, String contentType) {
  final blob = web.Blob(
    [bytes.toJS].toJS,
    web.BlobPropertyBag(type: contentType),
  );
  final url = web.URL.createObjectURL(blob);
  final window = tab as web.Window?;
  if (window != null && !window.closed) {
    window.location.href = url;
  } else {
    web.window.open(url, '_blank');
  }
}

void closeTab(Object? tab) => (tab as web.Window?)?.close();
