import 'dart:io';
import 'dart:async';
import 'dart:typed_data';

import 'package:fat32/fat32.dart';

abstract class Backend {
	FutureOr<Int8List> readSector(int sector);

	FutureOr writeSector(int sectorNum, Int8List data);
}

class BackendFile extends Backend {
	/// The backend file
	RandomAccessFile _backend;

	BackendFile._(this._backend);

	Future<Int8List> readSector(int sector, {int sectorSize: 512}) async {
		await _backend.setPosition(sector * sectorSize);
		final ret = new Int8List(sectorSize);
		await _backend.readInto(ret);
		return ret;
	}

	Future writeSector(int sector, Int8List data, {int sectorSize: 512}) async {
		if (data.length != sectorSize)
			throw new UnsupportedError('Data size must match sector size!');
		await _backend.setPosition(sector * sectorSize);
		await _backend.writeFrom(data);
	}

	static Future<Fat32> mount(File file) async {
		final RandomAccessFile r = await file.open(mode: FileMode.WRITE);
		final b = new BackendFile._(r);
		return new Fat32._(b);
	}
}