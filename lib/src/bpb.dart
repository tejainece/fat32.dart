import 'dart:typed_data';
import 'package:hexview/hexview.dart';

class BadBpb {
  final int id;

  final String message;

  const BadBpb(this.id, this.message);

  static const BadBpb badJumpBoot =
  const BadBpb(0, 'Bad BPB: Invalid jump boot field!');

  static const BadBpb invalidReservedSectorCount =
  const BadBpb(1, 'Bad BPB: Invalid reserved sector count field!');

  static const BadBpb invalidMedia =
  const BadBpb(1, 'Bad BPB: Invalid media field!');

  static const BadBpb invalidBootSignature =
  const BadBpb(1, 'Bad BPB: Invalid boot signature!');

  String toString() => message;
}

///
class Bpb {
  final ByteData buffer;

  Bpb(this.buffer) {
    if (buffer.lengthInBytes != 512)
      throw new Exception('BPB must be 512 bytes long!');
  }

  factory Bpb.fromUInt8List(Uint8List list) =>
      new Bpb(new ByteData.view(list.buffer));

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

  /// The total sectors in the logical volume. If greater than, this field is 0 and
  /// [totalSectors32] will hold the real total sectors in volume.
  int get totalSectors16 => buffer.getUint16(19, Endianness.LITTLE_ENDIAN);

  int get media => buffer.getUint8(21);

  /// Number of sectors per FAT. Not used in FAT32.
  int get fatSize16 => buffer.getUint16(22, Endianness.LITTLE_ENDIAN);

  /// Number of sectors per track.
  int get sectorsPerTrack => buffer.getUint16(24, Endianness.LITTLE_ENDIAN);

  /// Number of heads or sides on the storage media.
  int get numberOfHeads => buffer.getUint16(26, Endianness.LITTLE_ENDIAN);

  /// Number of hidden sectors.
  int get hiddenSectors => buffer.getUint32(28, Endianness.LITTLE_ENDIAN);

  /// The total sectors in the logical volume. Only valid if [totalSectors16] is 0
  int get totalSectors32 => buffer.getUint32(32, Endianness.LITTLE_ENDIAN);

  /// Sectors per FAT. The size of the FAT in sectors.
  int get fatSize32 => buffer.getUint32(36, Endianness.LITTLE_ENDIAN);

  /// Flags
  int get extFlags => buffer.getUint16(40, Endianness.LITTLE_ENDIAN);

  /// FAT version number
  int get fsVer => buffer.getUint16(42, Endianness.LITTLE_ENDIAN);

  /// Cluster number of root directory
  int get rootCluster => buffer.getUint32(44, Endianness.LITTLE_ENDIAN);

  /// The sector number of the FSInfo structure.
  int get fsInfo => buffer.getUint16(48, Endianness.LITTLE_ENDIAN);

  /// The sector number of the backup boot sector.
  int get bkBootSec => buffer.getUint16(50, Endianness.LITTLE_ENDIAN);
  int get drvNum => buffer.getUint8(64);

  /// Signature (must be 0x28 or 0x29).
  int get bootSig => buffer.getUint8(66);

  /// VolumeID 'Serial' number. Used for tracking volumes between computers.
  /// You can ignore this if you want.
  int get volId => buffer.getUint32(67, Endianness.LITTLE_ENDIAN);

  /// Volume label string
  List<int> get volLab =>
      new List<int>.generate(11, (i) => buffer.getUint8(71 + i));
  List<int> get filSysType =>
      new List<int>.generate(8, (i) => buffer.getUint8(82 + i));

  /// Bootable partition signature
  int get signature => buffer.getUint16(510, Endianness.LITTLE_ENDIAN);

  /// Validates that [jumpBoot] field is valid
  bool get isValidJumpBoot =>
      (jumpBoot[0] == 0xEB && jumpBoot[2] == 0x90) || jumpBoot[0] == 0xE9;

  /// Returns the size of FAT
  int get fatSize => fatSize16 != 0 ? fatSize16 : fatSize32;

  int get rootDirSectors =>
      ((rootEntryCount * 32) + (bytePerSector - 1)) ~/ bytePerSector;

  int get totalSectors => totalSectors16 != 0 ? totalSectors16 : totalSectors32;

  int get dataSectors =>
      totalSectors -
      (reservedSectorCount + (numFATs * fatSize) + rootDirSectors);

  int get clusterCount => dataSectors ~/ sectorsPerCluster;

  int get firstDataSector =>
      reservedSectorCount + (numFATs * fatSize) + rootDirSectors;

  String toString() {
    final sb = new StringBuffer();

    sb.writeln('Jump Boot: ${Hex.hex8List(jumpBoot)}');
    sb.writeln('OEM name: ${new String.fromCharCodes(oemName)}');
    sb.writeln('Bytes/Sector: $bytePerSector');
    sb.writeln('Sectors/Cluster: $sectorsPerCluster');
    sb.writeln('Reserved sector count: $reservedSectorCount');
    sb.writeln('# FAT copies: $numFATs');
    sb.writeln('Root entry count: $rootEntryCount');
    sb.writeln('# Sectors16: $totalSectors16');
    sb.writeln('Media: $media');
    sb.writeln('Sectors/FAT16: $fatSize16');
    sb.writeln('Sectors/Track: $sectorsPerTrack');
    sb.writeln('# heads: $numberOfHeads');
    sb.writeln('# hidden sectors: $hiddenSectors');
    sb.writeln('# Sectors32: $totalSectors32');
    sb.writeln('Sectors/FAT32: $fatSize32');
    sb.writeln('Ext flags: $extFlags');
    sb.writeln('Version: $fsVer');
    sb.writeln('Root cluster: $rootCluster');
    sb.writeln('Info: $fsInfo');
    sb.writeln('Backup boot sector: $bkBootSec');
    sb.writeln('Drv num: $drvNum');
    sb.writeln('Boot signature: $bootSig');
    sb.writeln('Volume id: ${Hex.hex32(volId)}');
    sb.writeln('Volume label: ${new String.fromCharCodes(volLab)}');
    sb.writeln('File system type: ${Hex.hex8List(filSysType)}');
    sb.writeln('Signature: 0x${Hex.hex16(signature)}');
    // TODO

    return sb.toString();
  }
}
