import 'dart:io';
import 'dart:async';
import 'dart:typed_data';

import 'package:fat32/fat32.dart';

abstract class Backend {
	FutureOr<Uint8List> readSector(int sector);

	FutureOr writeSector(int sectorNum, List<int> data);
}

class BackendFile extends Backend {
	/// The backend file
	RandomAccessFile _backend;

	BackendFile._(this._backend);

	Future<Uint8List> readSector(int sector, {int sectorSize: 512}) async {
		await _backend.setPosition(sector * sectorSize);
		final ret = new Uint8List(sectorSize);
		await _backend.readInto(ret);
		return ret;
	}

	Future writeSector(int sector, List<int> data, {int sectorSize: 512}) async {
		if (data.length != sectorSize)
			throw new UnsupportedError('Data size must match sector size!');
		await _backend.setPosition(sector * sectorSize);
		await _backend.writeFrom(data);
	}

	static Future<BackendFile> make(File file) async {
		final RandomAccessFile r = await file.open(mode: FileMode.APPEND);
		return new BackendFile._(r);
	}

	static Future<Fat32> mount(File file) async {
		final RandomAccessFile r = await file.open(mode: FileMode.APPEND);
		final b = new BackendFile._(r);
		final ret = new Fat32(b);
		await ret.init();
		return ret;
	}
}