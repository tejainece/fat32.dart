

String stringFromList(List<int> data) {
	final int lastChar = data.indexOf(0);
	if(lastChar == -1) return new String.fromCharCodes(data);
	return new String.fromCharCodes(data.sublist(0, lastChar));
}