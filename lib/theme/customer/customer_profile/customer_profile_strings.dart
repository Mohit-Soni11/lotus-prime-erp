class CustomerProfileStrings {
  CustomerProfileStrings._();

  static const appBarTitle = 'CUSTOMER PROFILE';
  static const btnNewSale = 'New Sale';
  static const btnEdit = 'Edit Customer';
  static const btnHistory = 'Invoice History';
  static const btnDelete = 'Delete Customer';

  static const secContact = 'Customer Information';
  static const secAccountSnapshot = 'Account Ledgers';

  static const noBills = 'No sales bills yet';
  static const noBillsSub = 'Sales invoices will appear after the first sale.';
  static const convertToSale = 'Convert to Sale';
  static const totalAdvancePaid = 'Advance Paid';
  static const remainingBalance = 'Remaining Balance';

  static const deleteTitle = 'Delete Customer?';
  static const deleteMsg =
      'Only customers without linked transactions can be deleted. Sales, Girvi, advance, purchase, return, delivery, and refund records stay protected.';
  static const deleteConfirm = 'Delete';
  static const deleteCancel = 'Cancel';
  static const deleteError = 'This customer has linked transaction records.';
}
