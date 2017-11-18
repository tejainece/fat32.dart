import 'package:meta/meta.dart';
import 'dart:typed_data';

class Fat32 {
  static const int badCluster = 0x0FFFFFF7;

  static const int endOfCluster = 0x0FFFFFF8;

  static void init() {
    // TODO
  }
}

/// Information about FAT32 filesystem read from the boot sector
class Fat32Info {
  final int sectorsPerCluster;

  final int firstDataSector;

  final int totalSectors;

  final int reservedSectors;

  final int currentSectors;

  final int sectorFlags;

  final int rootDirSize;

  /// Create an instance of [Fat32Info] from constituent fields
  const Fat32Info(
      {@required this.sectorsPerCluster,
      @required this.firstDataSector,
      @required this.totalSectors,
      @required this.reservedSectors,
      @required this.currentSectors,
      @required this.sectorFlags,
      @required this.rootDirSize});

  factory Fat32Info.read(Int8List buffer) {
    return const Fat32Info();
  }
}

class File {
  int parentStartCluster;

  int startCluster;

  int currentClusterIdx;

  int currentCluster;

  int currentSector;

  int currentByte;

  int pos;

  FileFlag flags;

  FileAttributes attributes;

  FileMode mode;

  int size;

  Int8List filename;
}

class FileAttributes {
  final int id;

  final String name;

  const FileAttributes(this.id, this.name);

  bool operator ==(other) {
    if (other is int) {
      return id == other;
    } else if (other is FileAttributes) {
      return other.id == id;
    }
    return false;
  }

  bool get isReadOnly => (id & readOnly.id) != 0;

  bool get isHidden => (id & hidden.id) != 0;

  bool get isDir => (id & directory.id) != 0;

  bool get isFile => (id & directory.id) == 0;

  static const FileAttributes readOnly = const FileAttributes(1, 'read only');

  static const FileAttributes hidden = const FileAttributes(2, 'hidden');

  static const FileAttributes system = const FileAttributes(4, 'system');

  static const FileAttributes volumeLabel =
      const FileAttributes(8, 'volume label');

  static const FileAttributes directory = const FileAttributes(16, 'directory');

  static const FileAttributes archive = const FileAttributes(32, 'archive');

  static const FileAttributes device = const FileAttributes(64, 'device');

  static const FileAttributes unused = const FileAttributes(128, 'unused');
}

class FileMode {
  final int id;

  final String name;

  const FileMode(this.id, this.name);

  bool operator ==(other) {
    if (other is int) {
      return id == other;
    } else if (other is FileMode) {
      return other.id == id;
    }
    return false;
  }

  static const FileMode read = const FileMode(1, 'read');

  static const FileMode write = const FileMode(2, 'write');

  static const FileMode append = const FileMode(4, 'append');

  static const FileMode overwrite = const FileMode(8, 'overwrite');
}

class FileFlag {
  final int id;

  final String name;

  const FileFlag(this.id, this.name);

  bool operator ==(other) {
    if (other is int) {
      return id == other;
    } else if (other is FileFlag) {
      return other.id == id;
    }
    return false;
  }

  static const FileFlag dirty = const FileFlag(1, 'dirty');

  static const FileFlag open = const FileFlag(2, 'open');

  static const FileFlag sizeChanged = const FileFlag(4, 'size changed');

  static const FileFlag root = const FileFlag(8, 'root');
}
