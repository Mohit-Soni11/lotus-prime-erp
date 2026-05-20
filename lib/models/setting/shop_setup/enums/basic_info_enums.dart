// -----------------------------------------------------------------------------
// FILE: basic_info_enums.dart
// TYPE: Core Foundation / Enums
// AUTHOR: Senior System Architect
// DESCRIPTION: Type-safe enumerations for the Basic Info module.
//              Prevents string-based crashes and typo errors.
// -----------------------------------------------------------------------------

/// Defines the primary sections of the Basic Info form.
/// Used for state management, locking/unlocking, and focus traversal.
enum FormSection {
  enterprise,
  operations,
  communication,
}

/// Represents the status of a specific setup step in the UI.
enum StepStatus {
  locked,
  active,
  completed,
}
