import 'dart:io';
import 'package:fat32/fat32.dart';
import 'dart:typed_data';
import 'package:hexview/hexview.dart';
import 'package:fat32/src/bpb.dart';

main() async {
	final file = new File('./data/1.fat');
	if(!file.existsSync()) throw new Exception();
	final BackendFile bk = await BackendFile.make(file);
	final Uint8List data = await bk.readSector(0);
	print(new HexView16(0, data));

	final bpb = new Bpb.fromUInt8List(data);
	print(bpb);

	final info = new Fat32Info.read(data);
	print(info);
}
