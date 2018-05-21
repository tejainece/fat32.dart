String stringFromShortFn(List<int> filename, List<int> extension) {
  String name = new String.fromCharCodes(filename).trimRight();
  if (extension.first == 0x20) return name;
  name += '.';
  name += new String.fromCharCodes(extension).trimRight();
  return name;
}

String stringFromList(List<int> data) {
  final int lastChar = data.indexOf(0);
  if (lastChar == -1) return new String.fromCharCodes(data);
  return new String.fromCharCodes(data.sublist(0, lastChar));
}
