import 'dart:js_interop';

import 'storage_contract.dart';

@JS('window.localStorage')
external LocalStorage get localStorage;

extension type LocalStorage(JSObject _) implements JSObject {
  external JSString? getItem(JSString key);
  external void setItem(JSString key, JSString value);
}

class BrowserStorage implements SnapshotStorage {
  static const key = 'iskedyul.data.v1';
  @override
  String? read() => localStorage.getItem(key.toJS)?.toDart;
  @override
  void write(String value) => localStorage.setItem(key.toJS, value.toJS);
}

SnapshotStorage createStorage() => BrowserStorage();
