import 'dart:async';
import 'dart:typed_data';
import 'package:meta/meta.dart';
import 'package:hexview/hexview.dart';
import 'package:fat32/src/backend/backend.dart';

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
  int get bytePerSector => buffer.getUint16(11, Endian.little);

  /// Number of sectors per cluster
  int get sectorsPerCluster => buffer.getUint8(13);

  /// Number of reserved sectors
  int get reservedSectorCount => buffer.getUint16(14, Endian.little);

  /// Number of copies of FATs on the storage media
  int get numFATs => buffer.getUint8(16);

  /// Number of directory entries (must be set so that the root directory occupies entire sectors)
  int get rootEntryCount => buffer.getUint16(17, Endian.little);

  /// The total sectors in the logical volume. If greater than, this field is 0 and
  /// [totalSectors32] will hold the real total sectors in volume.
  int get totalSectors16 => buffer.getUint16(19, Endian.little);

  int get media => buffer.getUint8(21);

  /// Number of sectors per FAT. Not used in FAT32.
  int get fatSize16 => buffer.getUint16(22, Endian.little);

  /// Number of sectors per track.
  int get sectorsPerTrack => buffer.getUint16(24, Endian.little);

  /// Number of heads or sides on the storage media.
  int get numberOfHeads => buffer.getUint16(26, Endian.little);

  /// Number of hidden sectors.
  int get hiddenSectors => buffer.getUint32(28, Endian.little);

  /// The total sectors in the logical volume. Only valid if [totalSectors16] is 0
  int get totalSectors32 => buffer.getUint32(32, Endian.little);

  /// Sectors per FAT. The size of the FAT in sectors.
  int get fatSize32 => buffer.getUint32(36, Endian.little);

  /// Flags
  int get extFlags => buffer.getUint16(40, Endian.little);

  /// FAT version number
  int get fsVer => buffer.getUint16(42, Endian.little);

  /// Cluster number of root directory
  int get rootCluster => buffer.getUint32(44, Endian.little);

  /// The sector number of the FSInfo structure.
  int get fsInfo => buffer.getUint16(48, Endian.little);

  /// The sector number of the backup boot sector.
  int get bkBootSec => buffer.getUint16(50, Endian.little);
  int get drvNum => buffer.getUint8(64);

  /// Signature (must be 0x28 or 0x29).
  int get bootSig => buffer.getUint8(66);

  /// VolumeID 'Serial' number. Used for tracking volumes between computers.
  /// You can ignore this if you want.
  int get volId => buffer.getUint32(67, Endian.little);

  /// Volume label string
  List<int> get volLab =>
      new List<int>.generate(11, (i) => buffer.getUint8(71 + i));

  List<int> get filSysType =>
      new List<int>.generate(8, (i) => buffer.getUint8(82 + i));

  /// Bootable partition signature
  int get signature => buffer.getUint16(510, Endian.little);

  /// Validates that [jumpBoot] field is valid
  bool get isValidJumpBoot =>
      (jumpBoot[0] == 0xEB && jumpBoot[2] == 0x90) || jumpBoot[0] == 0xE9;

  /// Returns the size of FAT
  int get fatSize => fatSize16 != 0 ? fatSize16 : fatSize32;

  int get rootDirSectors =>
      ((rootEntryCount * 32) + (bytePerSector - 1)) ~/ bytePerSector;

  int get totalSectors => totalSectors16 != 0 ? totalSectors16 : totalSectors32;

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

    return sb.toString();
  }

  static Future<Bpb> readWithBackend(Backend backend) async {
    final Uint8List data = await backend.readSector(0);
    return new Bpb.fromUInt8List(data);
  }
}

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

/*
class DriveInfo {
  final int sectorsPerTrack;

  final int numberOfHeads;

  DriveInfo(this.sectorsPerTrack, this.numberOfHeads);
}
*/
