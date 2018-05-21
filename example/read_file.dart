import 'dart:io';
import 'package:fat32/fat32.dart';

main() async {
  // The FAT32 formatted binary file
  final image = new File('./data/1.fat');
  final Fat32FileSystem fat = await BackendFile.mount(image);

  print(fat.info);

  final ReadOnlyFileHandle file = await fat.open(new Fat32File(r'\dir\dir1.txt'));
  
  print(file.size);
  print(file.startCluster);

  while(!file.isFinished) print(new String.fromCharCode(await file.readChar()));
  print('-------------');
}