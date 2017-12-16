import 'dart:async';
import 'dart:typed_data';

import 'package:fat32/fat32.dart';
import 'info/info.dart';

class Reader {
  final Backend backend;

  final int startCluster;

  Reader(this.backend, this.startCluster);

  List<int> read(int position, int length) {
    // TODO
  }

  // TODO
}

class Fat32 {
  static const int badCluster = 0x0FFFFFF7;

  static const int endOfCluster = 0x0FFFFFF8;

  Backend backend;

  /// Information about the Fat32 file system read from boot record
  Fat32Info _info;

  Fat32(this.backend);

  Future init() async {
    if (_info == null) {
      final Uint8List rec = await backend.readSector(0);
      _info = await new Fat32Info.read(rec);
    }
  }

  /// Opens file with path [filename] with file mode [mode]
  Future<Fat32File> open(String filename, Fat32FileMode mode) async {
    // TODO
  }
}

class Fat32File {
  int parentStartCluster;

  int startCluster;

  int currentClusterIdx;

  int currentCluster;

  int currentSector;

  int currentByte;

  int pos;

  Fat32FileFlag flags;

  Fat32FileAttributes attributes;

  Fat32FileMode mode;

  int size;

  Int8List filename;
}

class Fat32FileAttributes {
  final int id;

  final String name;

  const Fat32FileAttributes(this.id, this.name);

  bool operator ==(other) {
    if (other is int) {
      return id == other;
    } else if (other is Fat32FileAttributes) {
      return other.id == id;
    }
    return false;
  }

  bool get isReadOnly => (id & readOnly.id) != 0;

  bool get isHidden => (id & hidden.id) != 0;

  bool get isDir => (id & directory.id) != 0;

  bool get isFile => (id & directory.id) == 0;

  static const Fat32FileAttributes readOnly =
      const Fat32FileAttributes(1, 'read only');

  static const Fat32FileAttributes hidden =
      const Fat32FileAttributes(2, 'hidden');

  static const Fat32FileAttributes system =
      const Fat32FileAttributes(4, 'system');

  static const Fat32FileAttributes volumeLabel =
      const Fat32FileAttributes(8, 'volume label');

  static const Fat32FileAttributes directory =
      const Fat32FileAttributes(16, 'directory');

  static const Fat32FileAttributes archive =
      const Fat32FileAttributes(32, 'archive');

  static const Fat32FileAttributes device =
      const Fat32FileAttributes(64, 'device');

  static const Fat32FileAttributes unused =
      const Fat32FileAttributes(128, 'unused');
}

class Fat32FileMode {
  final int id;

  final String name;

  const Fat32FileMode(this.id, this.name);

  bool operator ==(other) {
    if (other is int) {
      return id == other;
    } else if (other is Fat32FileMode) {
      return other.id == id;
    }
    return false;
  }

  static const Fat32FileMode read = const Fat32FileMode(1, 'read');

  static const Fat32FileMode write = const Fat32FileMode(2, 'write');

  static const Fat32FileMode append = const Fat32FileMode(4, 'append');

  static const Fat32FileMode overwrite = const Fat32FileMode(8, 'overwrite');
}

class Fat32FileFlag {
  final int id;

  final String name;

  const Fat32FileFlag(this.id, this.name);

  bool operator ==(other) {
    if (other is int) {
      return id == other;
    } else if (other is Fat32FileFlag) {
      return other.id == id;
    }
    return false;
  }

  static const Fat32FileFlag dirty = const Fat32FileFlag(1, 'dirty');

  static const Fat32FileFlag open = const Fat32FileFlag(2, 'open');

  static const Fat32FileFlag sizeChanged =
      const Fat32FileFlag(4, 'size changed');

  static const Fat32FileFlag root = const Fat32FileFlag(8, 'root');
}
