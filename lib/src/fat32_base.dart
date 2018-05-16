import 'dart:async';
import 'dart:typed_data';
import 'package:meta/meta.dart';

import 'package:fat32/fat32.dart';
import 'info/info.dart';
import 'utils/str.dart';

abstract class Fat32Item {
  List<String> get segments;

  String get path;

  Future<bool> get exists;

  // TODO rename

  Future<FileStat> get stat;

  // TODO delete

  bool get isFile;

  bool get isDir;

  Fat32Dir get parent;
}

class Fat32File implements Fat32Item {
  final List<String> segments;

  factory Fat32File(String path) {
    final List<String> parts = path.split('\\');
    return new Fat32File.fromSegments(parts);
  }

  Fat32File.fromSegments(List<String> segments) : segments = segments.toList();

  String get path => '\\' + segments.join('\\');

  Future<bool> get exists {
    // TODO
    throw new UnimplementedError();
  }

  Future<FileStat> get stat {
    // TODO
    throw new UnimplementedError();
  }

  bool get isFile => true;

  bool get isDir => false;

  Fat32Dir get parent {
    // TODO
    throw new UnimplementedError();
  }
}

class Fat32Dir implements Fat32Item {
  final List<String> segments;

  factory Fat32Dir(String path) {
    final List<String> parts =
        path.split('\\').where((s) => s.isNotEmpty).toList();
    return new Fat32Dir.fromSegments(parts);
  }

  Fat32Dir.fromSegments(List<String> segments) : segments = segments.toList();

  String get path => '\\' + segments.join('\\');

  Future<bool> get exists {
    // TODO
    throw new UnimplementedError();
  }

  Future<FileStat> get stat {
    // TODO
    throw new UnimplementedError();
  }

  bool get isFile => false;

  bool get isDir => true;

  Fat32Dir get parent {
    // TODO
    throw new UnimplementedError();
  }
}

class Fat32FileSystem {
  static const int badCluster = 0x0FFFFFF7;

  static const int endOfCluster = 0x0FFFFFF8;

  final Backend backend;

  /// Information about the Fat32 file system read from boot record
  final Fat32Info info;

  Fat32FileSystem(this.backend, this.info);

  static Future<Fat32FileSystem> mount(Backend backend) async {
    final Uint8List rec = await backend.readSector(0);
    final info = await new Fat32Info.read(rec);
    return new Fat32FileSystem(backend, info);
  }

  /// Opens file with path [filename] with file mode [mode]
  Future<ReadOnlyFileHandle> open(String filename,
      [Fat32FileMode mode = Fat32FileMode.read]) async {
    // TODO
  }

  DirHandle __root;

  DirHandle get _root => __root ??= new DirHandle(this, info.rootCluster);

  Future<List<Fat32Item>> list(Fat32Dir dir) async {
    DirHandle handle = _root;
    for (String segment in dir.segments) {
      handle = await handle.childDir(segment);
      if (handle == null) return null;
    }
    return handle.list(dir.segments);
  }

  /// Returns next cluster of the file given its current cluster
  Future<int> getNextCluster(int currentCluster) async {
    if (currentCluster > endOfCluster) return 0xffffffff;

    // TODO check that [currentCluster] is in range

    final int sectorOffset = currentCluster ~/ (info.bytesPerSector ~/ 4);
    final int sector = info.numReservedSectors + sectorOffset;

    final Uint8List data = await backend.readSector(sector);
    final int rec = currentCluster % (info.bytesPerSector ~/ 4);
    return new ByteData.view(data.buffer).getUint32(rec * 4);
  }

  Future<int> getNthCluster(int currentCluster, int n) async {
    int ret = currentCluster;
    for (int i = 0; i < n; i++) {
      ret = await getNextCluster(currentCluster);
      if (ret >= endOfCluster) {
        return 0xffffffff;
      }
    }
    return ret;
  }
}

class DirHandle {
  final Fat32FileSystem filesystem;

  final int startCluster;

  DirHandle(this.filesystem, this.startCluster) {
    reset();
  }

  void reset() {
    _pos = 0;
    _currentCluster = startCluster;
  }

  Future<FileStat> nextEntry() async {
    Uint8List data = new Uint8List(FatEntry.entrySize);
    await read(data);
    if (data.first == 0) {
      return null;
    }
    if (data.first == 0xE5) {
      return nextEntry();
    }
    FatEntry entry = new FatEntry(new ByteData.view(data.buffer));
    if (!entry.isVolumeId) {
      return new FileStat.fromFatEntry(entry, null);
    }

    if (!entry.isLongFilename) {
      return nextEntry();
    }

    LFNEntry lfn = entry.toLFN;
    if (!lfn.isFirst) {
      throw new Exception("Directory is corrupt!");
    }

    int order = lfn.order;
    // TODO validate start order

    int checksum = lfn.checksum;
    final name = new List<int>(order * 13);
    lfn.copyAt(name);

    while (--order >= 1) {
      await read(data);
      if (data.first == 0 || data.first == 0xE5) {
        throw new Exception("Directory is corrupt!");
      }
      lfn = new LFNEntry(new ByteData.view(data.buffer));
      if (!lfn.isLongFilename ||
          lfn.isFirst ||
          lfn.order != order ||
          lfn.checksum != checksum) {
        throw new Exception("Directory is corrupt!");
      }

      lfn.copyAt(name);
    }

    await read(data);

    if (data.first == 0 || data.first == 0xE5) {
      throw new Exception("Directory is corrupt!");
    }
    entry = new FatEntry(new ByteData.view(data.buffer));
    if (entry.isVolumeId || entry.isLongFilename) {
      throw new Exception("Directory is corrupt!");
    }

    if (_calcChkSum(data) != checksum) {
      throw new Exception("Directory is corrupt!");
    }

    return new FileStat.fromFatEntry(entry, stringFromList(data));
  }

  int _calcChkSum(List<int> entry) {
    int sum = 0;
    for (int i = 0; i < 11; i++) {
      sum = ((sum & 1 != 0) ? 0x80 : 0) + (sum >> 1) + entry[i];
    }
    return sum;
  }

  Future<void> read(Uint8List data) async {
    if (data.length < FatEntry.entrySize) {
      throw new Exception("Not enough space!");
    }
    if (_currentCluster == 0xffffffff) {
      data[0] = 0;
      return;
    }

    List<int> sector = await filesystem.backend.readSector(_currentSector);

    int start = _byteInSector;
    for (int i = 0; i < FatEntry.entrySize; i++) {
      data[i] = sector[start + i];
    }

    _pos += FatEntry.entrySize;
    if (_byteInCluster == _fatInfo.bytesPerCluster) {
      _currentCluster = await filesystem.getNextCluster(_currentCluster);
    }
  }

  Future<DirHandle> childDir(String name) async {
    reset();
    FileStat entry = await nextEntry();
    while (entry != null) {
      if (entry.shortName == name) {
        return new DirHandle(filesystem, entry.startCluster);
      }
      if (entry.longName == name) {
        return new DirHandle(filesystem, entry.startCluster);
      }
    }
    return null;
  }

  Future<List<Fat32Item>> list(List<String> base) async {
    final ret = <Fat32Item>[];
    reset();
    FileStat entry = await nextEntry();
    while (entry != null) {
      if (entry.isFile) {
        // TODO long filename
        ret.add(
            new Fat32File.fromSegments(base.toList()..add(entry.shortName)));
      } else {
        // TODO long filename
        ret.add(new Fat32Dir.fromSegments(base.toList()..add(entry.shortName)));
      }
    }
    return ret;
  }

  /// Current cluster index
  int _currentCluster;

  /// Byte offset of the pointer
  int _pos;

  Fat32Info get _fatInfo => filesystem.info;

  /// Current sector
  int get _currentSector =>
      _fatInfo.firstSectorOf(_currentCluster) + _sectorInCluster;

  int get _sectorInCluster => _byteInCluster ~/ _fatInfo.bytesPerSector;

  /// Current byte inside current cluster
  int get _byteInCluster => _pos % _fatInfo.bytesPerCluster;

  int get _byteInSector => _pos % _fatInfo.bytesPerSector;

/* int get _currentClusterInFile =>
      _pos ~/ (_fatInfo.sectorsPerCluster * _fatInfo.bytesPerSector); */
}

class ReadOnlyFileHandle {
  final Fat32FileSystem filesystem;

  final int startCluster;

  final int size;

  ReadOnlyFileHandle(this.filesystem, this.size, this.startCluster) {
    reset();
  }

  void reset() {
    _pos = 0;
    _currentCluster = startCluster;
  }

  Future<void> seek(int position) async {
    if (position >= size) {
      throw new Exception("Outside file size!");
    }

    final int skipClusters = position ~/ _fatInfo.bytesPerCluster;
    int newCluster = await filesystem.getNthCluster(startCluster, skipClusters);
    if (newCluster == 0xffffffff) {
      throw new Exception("Corrupt file!");
    }
    _currentCluster = newCluster;
    _pos = position;
  }

  Future<void> moveReverse(int offset) async {
    if (offset == 0) return;

    if (offset > _pos) {
      throw new Exception("Offset cannot be greater than current position!");
    }

    if (_pos == size) {
      await seek(_pos - offset);
      return;
    }

    final int relOffset = _byteInCluster - offset;
    if (relOffset >= 0) {
      _pos -= offset;
      return;
    }

    await seek(_pos - offset);
  }

  Future<void> moveForward(int offset) async {
    if ((_pos + offset) >= size) {
      throw new Exception("Outside file size!");
    }

    final int relOffset = _byteInCluster + offset;
    if (relOffset < _fatInfo.bytesPerCluster) {
      _pos += offset;
      return;
    }

    final int skipClusters = relOffset ~/ _fatInfo.bytesPerCluster;
    int newCluster =
        await filesystem.getNthCluster(_currentCluster, skipClusters);
    if (newCluster == 0xffffffff) {
      throw new Exception("Corrupt file!");
    }
    _currentCluster = newCluster;
    _pos += offset;
  }

  Future<int> readChar() async {
    if (_pos >= size) {
      throw new Exception("Outside file size!");
    }

    List<int> data = await filesystem.backend.readSector(_currentSector);
    _pos++;
    if (_pos < size) {
      if (_byteInCluster == _fatInfo.bytesPerCluster) {
        _currentCluster = await filesystem.getNextCluster(_currentCluster);
      }
    }
    return data[_pos % _fatInfo.bytesPerSector];
  }

  Future<List<int>> read(int length) async {
    final ret = new Uint8List(length);
    for (int i = 0; i < length; i++) {
      ret[i] = await readChar();
    }
    return ret;
  }

  /// Current cluster index
  int _currentCluster;

  /// Byte offset of the pointer
  int _pos;

  Fat32Info get _fatInfo => filesystem.info;

  /// Current sector
  int get _currentSector =>
      _fatInfo.firstSectorOf(_currentCluster) + _sectorInCluster;

  int get _sectorInCluster => _byteInCluster ~/ _fatInfo.bytesPerSector;

  /// Current byte inside current cluster
  int get _byteInCluster =>
      _pos % (_fatInfo.sectorsPerCluster * _fatInfo.bytesPerSector);

  /* int get _currentClusterInFile =>
      _pos ~/ (_fatInfo.sectorsPerCluster * _fatInfo.bytesPerSector); */
}

class FileStat {
  final String shortName;

  final String longName;

  final DateTime creationTime;

  final DateTime writeTime;

  final DateTime lastAccessTime;

  final int size;

  final int startCluster;

  final bool isReadOnly;

  final bool isHidden;

  final bool isDir;

  final bool isSystem;

  bool get isFile => !isDir;

  FileStat({
    @required this.shortName,
    @required this.longName,
    @required this.creationTime,
    @required this.writeTime,
    @required this.lastAccessTime,
    @required this.size,
    @required this.startCluster,
    @required this.isReadOnly,
    @required this.isHidden,
    @required this.isDir,
    @required this.isSystem,
  });

  String get filename => longName ?? shortName;

  factory FileStat.fromFatEntry(FatEntry entry, String longName) {
    return new FileStat(
        shortName: entry.filenameStr,
        longName: longName ?? entry.filenameStr,
        creationTime: parseFatDateTime(entry.creationDate, entry.creationTime),
        writeTime: parseFatDateTime(entry.writeDate, entry.writeTime),
        lastAccessTime: parseFatDateTime(entry.lastAccessDate),
        size: entry.size,
        startCluster: entry.cluster,
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
