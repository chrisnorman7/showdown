/// Useful extension methods for integers.
extension IntX on int {
  /// Converts an integer into its ordinal string representation.
  String ordinal() {
    // Get the last two digits to handle exceptions like 11, 12, and 13
    final lastTwoDigits = this % 100;
    final lastDigit = this % 10;

    // Handle special cases for 11th, 12th, and 13th
    if (lastTwoDigits >= 11 && lastTwoDigits <= 13) {
      return '${this}th';
    }

    // Assign appropriate suffix based on the last digit
    switch (lastDigit) {
      case 1:
        return '${this}st';
      case 2:
        return '${this}nd';
      case 3:
        return '${this}rd';
      default:
        return '${this}th';
    }
  }
}
