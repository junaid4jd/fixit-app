import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

class ErrorHandler {
  static String getErrorMessage(dynamic error) {
    if (error == null) return AppConstants.errorGeneric;

    String errorMessage = error.toString().toLowerCase();

    // Firebase Auth errors
    if (errorMessage.contains('user-not-found')) {
      return AppConstants.errorUserNotFound;
    } else if (errorMessage.contains('wrong-password')) {
      return AppConstants.errorWrongPassword;
    } else if (errorMessage.contains('email-already-in-use')) {
      return AppConstants.errorEmailInUse;
    } else if (errorMessage.contains('weak-password')) {
      return AppConstants.errorWeakPassword;
    } else if (errorMessage.contains('invalid-email')) {
      return AppConstants.errorInvalidEmail;
    } else if (errorMessage.contains('permission-denied')) {
      return AppConstants.errorPermissionDenied;
    } else if (errorMessage.contains('unauthenticated')) {
      return AppConstants.errorUnauthorized;
    } else
    if (errorMessage.contains('network') || errorMessage.contains('timeout')) {
      return AppConstants.errorNetwork;
    }

    return AppConstants.errorGeneric;
  }

  static void showErrorSnackBar(BuildContext context, dynamic error) {
    if (!context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(getErrorMessage(error)),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            messenger.hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  static void showSuccessSnackBar(BuildContext context, String message) {
    if (!context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  static void showInfoSnackBar(BuildContext context, String message) {
    if (!context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.blue,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  static Future<bool?> showConfirmDialog(BuildContext context, {
    required String title,
    required String message,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    bool isDestructive = false,
  }) async {
    if (!context.mounted) return null;

    return showDialog<bool>(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(cancelText),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(
                  foregroundColor: isDestructive ? Colors.red : null,
                ),
                child: Text(confirmText),
              ),
            ],
          ),
    );
  }
}

class LoadingDialog {
  static void show(BuildContext context, {String? message}) {
    if (!context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          PopScope(
            canPop: false,
            child: AlertDialog(
              content: Row(
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(message ?? AppStrings.loading),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static void hide(BuildContext context) {
    if (!context.mounted) return;
    Navigator.of(context, rootNavigator: true).pop();
  }
}

class ValidationHelper {
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return AppStrings.requiredField;
    }

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return AppStrings.invalidEmail;
    }

    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return AppStrings.requiredField;
    }

    if (value.length < AppConstants.minPasswordLength) {
      return AppStrings.passwordTooShort;
    }

    return null;
  }

  static String? validateConfirmPassword(String? value, String? password) {
    if (value == null || value.isEmpty) {
      return AppStrings.requiredField;
    }

    if (value != password) {
      return AppStrings.passwordMismatch;
    }

    return null;
  }

  static String? validateRequired(String? value, {String? fieldName}) {
    if (value == null || value
        .trim()
        .isEmpty) {
      return fieldName != null
          ? '$fieldName is required'
          : AppStrings.requiredField;
    }
    return null;
  }

  static String? validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return AppStrings.requiredField;
    }

    // Basic phone number validation for Oman (+968)
    final phoneRegex = RegExp(r'^\+968[0-9]{8}$|^[0-9]{8}$');
    if (!phoneRegex.hasMatch(value.replaceAll(' ', ''))) {
      return AppStrings.invalidPhoneNumber;
    }

    return null;
  }

  static String? validateName(String? value) {
    if (value == null || value
        .trim()
        .isEmpty) {
      return AppStrings.requiredField;
    }

    if (value
        .trim()
        .length > AppConstants.maxNameLength) {
      return 'Name must be less than ${AppConstants.maxNameLength} characters';
    }

    return null;
  }

  static String? validateDescription(String? value) {
    if (value != null && value.length > AppConstants.maxDescriptionLength) {
      return 'Description must be less than ${AppConstants
          .maxDescriptionLength} characters';
    }

    return null;
  }

  static String? validateHourlyRate(String? value) {
    if (value == null || value.isEmpty) {
      return AppStrings.requiredField;
    }

    final rate = double.tryParse(value);
    if (rate == null || rate <= 0) {
      return 'Please enter a valid hourly rate';
    }

    return null;
  }

  static String? validateExperience(String? value) {
    if (value == null || value.isEmpty) {
      return AppStrings.requiredField;
    }

    final experience = int.tryParse(value);
    if (experience == null ||
        experience < AppConstants.minExperience ||
        experience > AppConstants.maxExperience) {
      return 'Experience must be between ${AppConstants
          .minExperience} and ${AppConstants.maxExperience} years';
    }

    return null;
  }
}
