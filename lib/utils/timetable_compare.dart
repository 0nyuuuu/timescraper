List<int> findCommonFreeSlots(
    List<int> a,
    List<int> b,
    ) {
  final result = <int>[];

  for (int i = 0; i < a.length; i++) {
    if (a[i] == 0 && b[i] == 0) {
      result.add(i);
    }
  }

  return result;
}
