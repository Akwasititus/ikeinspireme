
class FormatHelper {
  static String formatLikeCount(int count) {
    if (count < 1000) {
      return count.toString();
    } else if (count < 1000000) {
      double result = count / 1000;
      return '${result.toStringAsFixed(result % 1 == 0 ? 0 : 1)}k';
    } else {
      double result = count / 1000000;
      return '${result.toStringAsFixed(result % 1 == 0 ? 0 : 1)}M';
    }
  }
}