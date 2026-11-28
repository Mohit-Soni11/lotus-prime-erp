class CompanyRegistrationInput {
  const CompanyRegistrationInput({
    required this.ownerName,
    required this.mobile,
    required this.companyName,
    required this.email,
    required this.password,
  });

  final String ownerName;
  final String mobile;
  final String companyName;
  final String email;
  final String password;
}
