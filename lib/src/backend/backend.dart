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
	RandomAccessFile _file;

	BackendFile._(this._file);

	Future<Uint8List> readSector(int sector, {int sectorSize: 512}) async {
		await _file.setPosition(sector * sectorSize);
		final ret = new Uint8List(sectorSize);
		await _file.readInto(ret);
		return ret;
	}

	Future writeSector(int sector, List<int> data, {int sectorSize: 512}) async {
		if (data.length != sectorSize)
			throw new UnsupportedError('Data size must match sector size!');
		await _file.setPosition(sector * sectorSize);
		await _file.writeFrom(data);
	}

	static Future<BackendFile> make(File image) async {
		final RandomAccessFile r = await image.open(mode: FileMode.append);
		return new BackendFile._(r);
	}

	static Future<Fat32FileSystem> mount(File image) async {
		return await Fat32FileSystem.mount(await BackendFile.make(image));
	}
}