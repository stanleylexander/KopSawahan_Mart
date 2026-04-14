class ReceiptHelper {
  static String formatCurrency(num value) {
    final text = value.toInt().toString();
    final buffer = StringBuffer();

    for (int i = 0; i < text.length; i++) {
      final reverseIndex = text.length - i;
      buffer.write(text[i]);

      if (reverseIndex > 1 && reverseIndex % 3 == 1) {
        buffer.write('.');
      }
    }

    return "Rp $buffer";
  }

  static String formatDateTime(String? value) {
    if (value == null || value.isEmpty) {
      return "-";
    }

    final dateTime = DateTime.tryParse(value)?.toLocal();

    if (dateTime == null) {
      return value;
    }

    final day = dateTime.day.toString().padLeft(2, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    final year = dateTime.year.toString();
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');

    return "$day/$month/$year $hour:$minute";
  }
}
