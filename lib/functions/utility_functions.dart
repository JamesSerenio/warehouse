abstract final class UtilityFunctions {
  static String? requiredField(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your ${fieldName.toLowerCase()}.';
    }
    return null;
  }
}
