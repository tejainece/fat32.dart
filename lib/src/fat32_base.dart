import 'dart:async';
import 'dart:typed_data';
import 'package:meta/meta.dart';

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

  final Backend backend;

  /// Information about the Fat32 file system read from boot record
  final Fat32Info info;

  Fat32(this.backend, this.info);

  /// Opens file with path [filename] with file mode [mode]
  Future<Fat32Item> open(String filename, Fat32FileMode mode) async {
    // TODO
  }

  /// Non-recursively finds file or directory named [name] in given directory
  /// [dir]
  Future<dynamic> findEntryInDirectory(String name) {}

  static Future<Fat32> mount(Backend backend) async {
    final Uint8List rec = await backend.readSector(0);
    final info = await new Fat32Info.read(rec);
    return new Fat32(backend, info);
  }
}

class Fat32Item {
  FileStat stat;

  int parentStartCluster;

  int startCluster;

  FileContentPointer state;

  Fat32FileFlag flags;

  Fat32FileMode mode;
}

class FileContentPointer {
  final Fat32Info fatInfo;

  /// Current cluster index
  int currentCluster;

  /// Byte offset of the pointer
  int pos;

  FileContentPointer(this.fatInfo, {this.currentCluster: 2, this.pos: 0});

  /// Current sector
  int get currentSector =>
      fatInfo.firstSectorOf(currentCluster) + sectorInCluster;

  int get sectorInCluster => byteInCluster ~/ fatInfo.bytesPerSector;

  /// Current byte inside current cluster
  int get byteInCluster =>
      pos % (fatInfo.sectorsPerCluster * fatInfo.bytesPerSector);

  int get currentClusterInFile =>
      pos ~/ (fatInfo.sectorsPerCluster * fatInfo.bytesPerSector);
}

class FileStat {
  final List<int> filename;

  final DateTime creationTime;

  final DateTime writeTime;

  final DateTime lastAccessTime;

  final int size;

  final bool isReadOnly;

  final bool isHidden;

  final bool isDir;

  final bool isSystem;

  bool get isFile => !isDir;

  // TODO final bool isArchive;

  FileStat({
    @required this.filename,
    @required this.creationTime,
    @required this.writeTime,
    @required this.lastAccessTime,
    @required this.size,
    @required this.isReadOnly,
    @required this.isHidden,
    @required this.isDir,
    @required this.isSystem,
  });

  factory FileStat.fromFatEntry(FatEntry entry) {
    // TODO long filename
    return new FileStat(
        filename: entry.filename,
        creationTime: parseFatDateTime(entry.creationDate, entry.creationTime),
        writeTime: parseFatDateTime(entry.writeDate, entry.writeTime),
        lastAccessTime: parseFatDateTime(entry.lastAccessDate),
        size: entry.size,
        isReadOnly: entry.isReadOnly,
        isHidden: entry.isHidden,
        isDir: entry.isDir,
        isSystem: entry.isSystemFile);
  }
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
