
class FormatUtils {
  static String formatByGroups(String num, List<int> groups) {
    final clean = num.replaceAll(RegExp(r'\s+'), '');
    int i = 0;
    List<String> result = [];
    
    for (int len in groups) {
      if (i >= clean.length) break;
      int nextIndex = i + len;
      if (nextIndex > clean.length) {
        nextIndex = clean.length;
      }
      result.add(clean.substring(i, nextIndex));
      i = nextIndex;
    }
    
    return result.where((s) => s.isNotEmpty).join(' ');
  }
}