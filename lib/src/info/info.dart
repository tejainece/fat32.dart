import 'package:meta/meta.dart';
import 'dart:typed_data';

import '../bpb.dart';
import '../utils/str.dart';

/// Information about FAT32 filesystem read from the boot sector
class Fat32Info {
  // Number of bytes per sector
  final int bytesPerSector;

  /// Number of sectors per cluster
  final int sectorsPerCluster;

  /// Reserved sectors in this FAT32 partition
  final int numReservedSectors;

  /// Number of copies of FATs on the storage media
  final int numFatCopies;

  /// Total number of sectors in this FAT32 partition
  final int totalSectors;

  /// Sectors per file allocation table
  final int sectorsPerFat;

  /// Number of the root cluster
  final int rootCluster;

  // TODO final int currentSectors;
  // TODO final int sectorFlags;

  /// Create an instance of [Fat32Info] from constituent fields
  const Fat32Info(
      {@required this.bytesPerSector,
      @required this.sectorsPerCluster,
      @required this.numReservedSectors,
      @required this.numFatCopies,
      @required this.totalSectors,
      @required this.sectorsPerFat,
      @required this.rootCluster});

  factory Fat32Info.fromBpb(Bpb bpb) {
    return new Fat32Info(
      bytesPerSector: bpb.bytePerSector,
      sectorsPerCluster: bpb.sectorsPerCluster,
      numReservedSectors: bpb.reservedSectorCount,
      numFatCopies: bpb.numFATs,
      totalSectors: bpb.totalSectors,
      sectorsPerFat: bpb.fatSize,
      rootCluster: bpb.rootCluster,
    );
  }

  factory Fat32Info.read(Uint8List buffer) {
    final bpb = new Bpb.fromUInt8List(buffer);

    // TODO Validate
    // Check for correct JumpBoot field
    if (!bpb.isValidJumpBoot) throw BadBpb.badJumpBoot;

    // TODO support other sector sizes
    if (bpb.bytePerSector != 512)
      throw new UnsupportedError('Only bytes per sector of 512 are allowed!');

    if (bpb.reservedSectorCount == 0) throw BadBpb.invalidReservedSectorCount;

    if (bpb.media != 0xF0 && (bpb.media < 0xF8 || bpb.media > 0xFF))
      throw BadBpb.invalidMedia;

    if (bpb.signature != 0xAA55) throw BadBpb.invalidBootSignature;

    // TODO other validations

    return new Fat32Info.fromBpb(bpb);
  }

  int get bytesPerCluster => bytesPerSector * sectorsPerCluster;

  int get numDataSectors => totalSectors - firstDataSector;

  int get clusterCount => numDataSectors ~/ sectorsPerCluster;

  /// Sector number of the first data sector
  int get firstDataSector =>
      numReservedSectors + (numFatCopies * sectorsPerFat);

  int firstSectorOf(int cluster) {
    return firstDataSector + ((cluster - 2) * sectorsPerCluster);
  }

  String toString() {
    final sb = new StringBuffer();

    sb.writeln('Bytes/Sectors: $bytesPerSector');
    sb.writeln('Sectors/Cluster: $sectorsPerCluster');
    sb.writeln('First data sector: $firstDataSector');
    sb.writeln('# Sectors: $totalSectors');
    sb.writeln('Reserved sectors: $numReservedSectors');
    sb.writeln('# FATs: $numFatCopies');
    sb.writeln('# FATs: $sectorsPerFat');

    return sb.toString();
  }
}

class FatEntry {
  final ByteData buffer;

  FatEntry(this.buffer) {
    if (buffer.lengthInBytes != entrySize)
      throw new Exception('FatEntry must be $entrySize bytes long!');
  }

  static const int entrySize = 32;

  List<int> get filename =>
      new List<int>.generate(8, (i) => buffer.getUint8(0 + i));

  List<int> get extension =>
      new List<int>.generate(3, (i) => buffer.getUint8(8 + i));

  int get attributes => buffer.getUint8(11);

  int get creationTime => buffer.getUint16(14, Endian.little);

  int get creationDate => buffer.getUint16(16, Endian.little);

  int get lastAccessDate => buffer.getUint16(18, Endian.little);

  int get clusterHi => buffer.getUint16(20, Endian.little);

  int get writeTime => buffer.getUint16(22, Endian.little);

  int get writeDate => buffer.getUint16(24, Endian.little);

  int get clusterLo => buffer.getUint16(26, Endian.little);

  int get size => buffer.getUint32(28, Endian.little);

  int get cluster => (clusterHi << 16) | clusterLo;

  String get fullname => stringFromShortFn(filename, extension);

  bool get isReadOnly => (attributes & FileAttributesMask.readOnly.id) != 0;

  bool get isHidden => (attributes & FileAttributesMask.hidden.id) != 0;

  bool get isVolumeId => (attributes & FileAttributesMask.volumeLabel.id) != 0;

  bool get isDir => (attributes & FileAttributesMask.directory.id) != 0;

  bool get isFile => (attributes & FileAttributesMask.directory.id) == 0;

  bool get isArchive => (attributes & FileAttributesMask.archive.id) != 0;

  bool get isSystemFile => (attributes & FileAttributesMask.system.id) != 0;

  bool get isLongFilename => FileAttributesMask.isLongFilename(attributes);

  LFNEntry get toLFN => new LFNEntry(buffer);
}

class LFNEntry {
  final ByteData buffer;

  LFNEntry(this.buffer);

  int get checksum => buffer.getUint8(13);

  bool get isFirst => (buffer.getUint8(0) & 0x40) != 0;

  int get order => (buffer.getUint8(0) & 0x3F);

  int get attributes => buffer.getUint8(11);

  bool get isLongFilename => FileAttributesMask.isLongFilename(attributes);

  void copyAt(List<int> data) {
    int pos = (order - 1) * 13;

    for (int i = 0; i < 5; i++) {
      data[pos++] = buffer.getUint16(1 + (i * 2), Endian.little);
    }

    for (int i = 0; i < 6; i++) {
      data[pos++] = buffer.getUint16(14 + (i * 2), Endian.little);
    }

    data[pos++] = buffer.getUint16(28, Endian.little);
    data[pos++] = buffer.getUint16(30, Endian.little);
  }

  List<int> get longFilename {
    final ret = <int>[];

    for (int i = 0; i < 5; i++) {
      ret.add(buffer.getUint16(1 + (i * 2), Endian.little));
    }

    for (int i = 0; i < 6; i++) {
      ret.add(buffer.getUint16(14 + (i * 2), Endian.little));
    }

    ret.add(buffer.getUint16(28, Endian.little));
    ret.add(buffer.getUint16(30, Endian.little));

    return ret;
  }

  static const int numChars = 13;
}

class FileAttributesMask {
  final int id;

  final String name;

  const FileAttributesMask(this.id, this.name);

  static const FileAttributesMask readOnly =
      const FileAttributesMask(1, 'read only');

  static const FileAttributesMask hidden =
      const FileAttributesMask(2, 'hidden');

  static const FileAttributesMask system =
      const FileAttributesMask(4, 'system');

  static const FileAttributesMask volumeLabel =
      const FileAttributesMask(8, 'volume label');

  static const FileAttributesMask directory =
      const FileAttributesMask(16, 'directory');

  static const FileAttributesMask archive =
      const FileAttributesMask(32, 'archive');

  static const FileAttributesMask device =
      const FileAttributesMask(64, 'device');

  static const FileAttributesMask unused =
      const FileAttributesMask(128, 'unused');

  static int lfnMask = readOnly.id | hidden.id | system.id | volumeLabel.id;

  static bool isLongFilename(int attributes) =>
      (attributes & lfnMask) == lfnMask;
}

DateTime parseFatDateTime(int date, [int time = 0]) {
  int year = 1980 + ((date & 0xFE00) >> 9);
  int month = (date & 0x1E0) >> 5;
  int day = date & 0x1F;

  int hour = (time & 0xF100) >> 11;
  int minute = (time & 0x7E0) >> 5;
  int second = (time & 0x1F) * 2;

  return new DateTime(year, month, day, hour, minute, second);
}
