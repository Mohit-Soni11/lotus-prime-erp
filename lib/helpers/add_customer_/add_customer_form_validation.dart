import '../../models/customer/add_customer/add_customer_form_model.dart';
import 'add_customer_validator.dart';

class AddCustomerFormValidation {
  const AddCustomerFormValidation._();

  static AddCustomerFormModel apply(AddCustomerFormModel form) {
    final nameError = form.isCorporate
        ? AddCustomerValidator.validateCompanyName(form.companyName)
        : AddCustomerValidator.validateName(form.firstName);
    final mobileError = AddCustomerValidator.validateMobile(form.mobile);
    final whatsappError = AddCustomerValidator.validateMobile(form.whatsapp);
    final alternateError =
        AddCustomerValidator.validateMobile(form.alternateContact);
    final panError = AddCustomerValidator.validatePan(form.panNumber);
    final idProofError = AddCustomerValidator.validateIdProof(
      form.idProofNumber,
      hasType: form.idProofType != null,
    );
    final gstError = AddCustomerValidator.validateGst(form.gstNumber);
    final emailError = AddCustomerValidator.validateEmail(form.email);
    final pincodeError = AddCustomerValidator.validatePostalCode(
      form.pincode,
      country: form.country,
    );
    return form.copyWith(
      firstNameError: form.isCorporate ? null : nameError,
      clearFirstNameError: form.isCorporate || nameError == null,
      companyNameError: form.isCorporate ? nameError : null,
      clearCompanyNameError: !form.isCorporate || nameError == null,
      mobileError: mobileError,
      clearMobileError: mobileError == null,
      whatsappError: whatsappError,
      clearWhatsappError: whatsappError == null,
      alternateContactError: alternateError,
      clearAlternateContactError: alternateError == null,
      panError: panError,
      clearPanError: panError == null,
      idProofError: idProofError,
      clearIdProofError: idProofError == null,
      gstError: gstError,
      clearGstError: gstError == null,
      emailError: emailError,
      clearEmailError: emailError == null,
      pincodeError: pincodeError,
      clearPincodeError: pincodeError == null,
    );
  }
}
