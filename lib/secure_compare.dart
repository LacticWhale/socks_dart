/// Constant time comparison.
///
/// Keep in mind that it's designed for always the same length inputs
/// i.e. hashes.
bool secureCompare(String a, String b) {
  if (a.codeUnits.length != b.codeUnits.length) {
    return false;
  }

  var r = 0;
  for (var i = 0; i < a.codeUnits.length; i++) {
    r |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
  }
  return r == 0;
}
