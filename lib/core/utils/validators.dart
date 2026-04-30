/// Form field validators for SplitSaathi.
/// Used in all text fields across auth, expense, and group forms.
class Validators {
  Validators._();

  /// Validates an email address format.
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Enter a valid email address';
    }
    return null;
  }

  /// Validates password (minimum 6 characters).
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  /// Validates confirm password matches original password.
  static String? confirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != password) {
      return 'Passwords do not match';
    }
    return null;
  }

  /// Validates a non-empty name field.
  static String? name(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Name is required';
    }
    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters';
    }
    return null;
  }

  /// Validates a group name.
  static String? groupName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Group name is required';
    }
    if (value.trim().length < 2) {
      return 'Group name must be at least 2 characters';
    }
    return null;
  }

  /// Validates an expense item name.
  static String? itemName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Item name is required';
    }
    return null;
  }

  /// Validates an expense amount (must be positive number).
  static String? amount(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Amount is required';
    }
    final parsed = double.tryParse(value.trim());
    if (parsed == null) {
      return 'Enter a valid number';
    }
    if (parsed <= 0) {
      return 'Amount must be greater than 0';
    }
    return null;
  }
}
