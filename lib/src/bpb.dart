import 'dart:typed_data';

///
class Bpb {
  ByteData buffer;

  List<int> get jumpBoot =>
      new List<int>.generate(3, (i) => buffer.getUint8(0 + i));
  /// OEM identifier
  List<int> get oemName =>
      new List<int>.generate(8, (i) => buffer.getUint8(3 + i));
  /// Number of bytes per sector
  int get bytePerSector => buffer.getUint16(11, Endianness.LITTLE_ENDIAN);
  /// Number of sectors per cluster
  int get sectorsPerCluster => buffer.getUint8(13);
  /// Number of reserved sectors
  int get reservedSectorCount => buffer.getUint16(14, Endianness.LITTLE_ENDIAN);
  /// Number of copies of FATs on the storage media
  int get numFATs => buffer.getUint8(16);
  /// Number of directory entries (must be set so that the root directory occupies entire sectors)
  int get rootEntryCount => buffer.getUint16(17, Endianness.LITTLE_ENDIAN);
  int get totalSectors16 => buffer.getUint16(19, Endianness.LITTLE_ENDIAN);
  int get media => buffer.getUint8(21);
  int get fatSize16 => buffer.getUint16(22, Endianness.LITTLE_ENDIAN);
  int get sectorsPerTrack => buffer.getUint16(24, Endianness.LITTLE_ENDIAN);
  int get numberOfHeads => buffer.getUint16(26, Endianness.LITTLE_ENDIAN);
  int get hiddenSectors => buffer.getUint32(28, Endianness.LITTLE_ENDIAN);
  int get totalSectors32 => buffer.getUint32(32, Endianness.LITTLE_ENDIAN);
  int get fatSz32 => buffer.getUint32(36, Endianness.LITTLE_ENDIAN);
  int get extFlags => buffer.getUint16(40, Endianness.LITTLE_ENDIAN);
  int get fsVer => buffer.getUint16(42, Endianness.LITTLE_ENDIAN);
  int get rootCluster => buffer.getUint32(44, Endianness.LITTLE_ENDIAN);
  int get fsInfo => buffer.getUint16(48, Endianness.LITTLE_ENDIAN);
  int get bkBootSec => buffer.getUint16(50, Endianness.LITTLE_ENDIAN);
  int get drvNum => buffer.getUint8(64);
  int get bootSig => buffer.getUint8(66);
  int get volId => buffer.getUint32(67, Endianness.LITTLE_ENDIAN);
  List<int> get volLab =>
      new List<int>.generate(11, (i) => buffer.getUint8(71 + i));
  List<int> get filSysType =>
      new List<int>.generate(8, (i) => buffer.getUint8(82 + i));
  int get signature => buffer.getUint16(510, Endianness.LITTLE_ENDIAN);
}
