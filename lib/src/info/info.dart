import 'package:meta/meta.dart';
import 'dart:typed_data';

import '../bpb.dart';
import '../utils/str.dart';

/// Information about FAT32 filesystem read from the boot sector
class Fat32Info {
  final int sectorsPerCluster;

  final int firstDataSector;

  final int totalSectors;

  final int reservedSectors;

  final int currentSectors;

  final int sectorFlags;

  /// Create an instance of [Fat32Info] from constituent fields
  const Fat32Info(
      {@required this.sectorsPerCluster,
      @required this.firstDataSector,
      @required this.totalSectors,
      @required this.reservedSectors,
      @required this.currentSectors,
      @required this.sectorFlags});

  factory Fat32Info.read(Uint8List buffer) {
    final bpb = new Bpb(new ByteData.view(buffer.buffer));

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
    // TODO

    return new Fat32Info(
        sectorsPerCluster: bpb.sectorsPerCluster,
        firstDataSector: bpb.firstDataSector,
        totalSectors: bpb.totalSectors,
        reservedSectors: bpb.reservedSectorCount);
  }

  String toString() {
    final sb = new StringBuffer();

    sb.writeln('Sectors/Cluster: $sectorsPerCluster');
    sb.writeln('First data sector: $firstDataSector');
    sb.writeln('# Sectors: $totalSectors');
    sb.writeln('Reserved sectors: $reservedSectors');

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

  int get attributes =>  buffer.getUint8(11);

  int get time => buffer.getUint16(22, Endianness.LITTLE_ENDIAN);

  int get date => buffer.getUint16(24, Endianness.LITTLE_ENDIAN);

  int get cluster => buffer.getUint16(26, Endianness.LITTLE_ENDIAN);

  int get size => buffer.getUint32(28, Endianness.LITTLE_ENDIAN);

  String get filenameStr => stringFromList(filename);

  String get extensionStr => stringFromList(extension);

  String get fullname => filenameStr + '.' + extensionStr;

  // TODO filename metadata
}
