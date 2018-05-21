import 'dart:io';
import 'package:fat32/fat32.dart';

main() async {
  // The FAT32 formatted binary file
  final file = new File('./data/1.fat');
  final Fat32FileSystem fat = await BackendFile.mount(file);

  print(fat.info);

  print((await fat.list(new Fat32Dir('\\'))).join(', '));
}