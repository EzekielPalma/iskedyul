abstract class SnapshotStorage {
  String? read();
  void write(String value);
}

class MemoryStorage implements SnapshotStorage {
  String? value;
  @override
  String? read() => value;
  @override
  void write(String value) => this.value = value;
}
