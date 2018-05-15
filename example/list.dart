import 'dart:io';
import 'package:fat32/fat32.dart';
import 'dart:typed_data';
import 'package:hexview/hexview.dart';
import 'package:fat32/src/bpb.dart';

main() async {
  // The FAT32 formatted binary file
  final file = new File('./data/1.fat');
  if(!file.existsSync()) throw new Exception();

  final BackendFile bk = await BackendFile.make(file);

  final bpb = await Bpb.readWithBackend(bk);
  print(bpb);
}