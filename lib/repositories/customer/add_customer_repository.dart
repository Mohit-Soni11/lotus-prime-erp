import 'package:drift/drift.dart' as drift;
import 'package:lotus_erp/database/db/app_database.dart';

import '../../models/customer/add_customer/add_customer_form_model.dart';
import '../../models/customer/customer_enums/add_customer_enums.dart';
import '../../core/logging/app_logger.dart';

class AddCustomerRepository {
  final AppDatabase _db;

  AddCustomerRepository({AppDatabase? db}) : _db = db ?? AppDatabase();

  Future<AddCustomerFormModel?> fetchCustomerForEdit(int customerId) async {
    try {
      final customer = await (_db.select(_db.customers)
            ..where((row) => row.id.equals(customerId)))
          .getSingleOrNull();
      if (customer == null) return null;

      final entityType = CustomerEntityType.fromLabel(customer.entityType);
      final fallbackNameParts = customer.name.trim().split(RegExp(r'\s+'));
      final firstName = customer.firstName?.trim().isNotEmpty == true
          ? customer.firstName!.trim()
          : entityType == CustomerEntityType.individual
              ? fallbackNameParts.first
              : '';
      final lastName = customer.lastName?.trim().isNotEmpty == true
          ? customer.lastName!.trim()
          : entityType == CustomerEntityType.individual &&
                  fallbackNameParts.length > 1
              ? fallbackNameParts.skip(1).join(' ')
              : '';
      final companyName = customer.companyName?.trim().isNotEmpty == true
          ? customer.companyName!.trim()
          : entityType == CustomerEntityType.corporate
              ? customer.name.trim()
              : '';
      final whatsapp = customer.whatsapp?.trim() ?? '';
      final tierLabel = customer.customerTier.trim().isEmpty
          ? customer.type
          : customer.customerTier;
      final customerTier = CustomerTier.fromLabel(tierLabel);

      return AddCustomerFormModel(
        entityType: entityType,
        firstName: firstName,
        lastName: lastName,
        companyName: companyName,
        contactPersonName: customer.contactPersonName ?? '',
        dateOfBirth: _parseDate(customer.dateOfBirth),
        gender: _optionalEnum(
          customer.gender,
          Gender.values,
          (value) => value.label,
        ),
        anniversaryDate: _parseDate(customer.anniversaryDate),
        mobile: customer.mobile,
        sameAsWhatsApp:
            whatsapp.isNotEmpty && whatsapp == customer.mobile.trim(),
        whatsapp: whatsapp,
        email: customer.email ?? '',
        alternateContact: customer.alternateContact ?? '',
        panNumber: customer.panNumber ?? '',
        idProofType: _optionalEnum(
          customer.idProofType,
          IdProofType.values,
          (value) => value.label,
        ),
        idProofNumber: customer.idProofNumber ?? '',
        idProofDocPath: customer.idProofDocPath,
        gstNumber: customer.gstNumber ?? '',
        addressLine1: customer.addressLine1 ?? '',
        addressLine2: customer.addressLine2 ?? '',
        country: customer.country,
        state: customer.state ?? '',
        city: customer.city ?? '',
        pincode: customer.pincode ?? '',
        openingBalance: customer.openingBalance,
        creditLimit: customer.creditLimit,
        customerTier: customerTier,
        membershipId: customer.membershipId ?? '',
        ringSize: _optionalEnum(
          customer.ringSize,
          RingSize.values,
          (value) => value.label,
        ),
        bangleSize: _optionalEnum(
          customer.bangleSize,
          BangleSize.values,
          (value) => value.label,
        ),
        familyMembers: FamilyMember.decodeList(customer.familyDetailsJson),
        referralSource: _optionalEnum(
          customer.referralSource,
          ReferralSource.values,
          (value) => value.label,
        ),
        notes: customer.notes ?? '',
        profileImagePath: customer.profileImagePath,
        type: customerTier == CustomerTier.vip
            ? NewCustomerType.vip
            : NewCustomerType.regular,
      );
    } catch (e) {
      AppLogger.debug('Customer edit load error: $e');
      return null;
    }
  }

  Future<SaveResult> saveCustomer(
    AddCustomerFormModel form, {
    int? customerId,
  }) async {
    try {
      final exists = await _checkMobileExists(
        form.mobile.trim(),
        excludeCustomerId: customerId,
      );
      if (exists) return SaveResult.duplicate;

      final displayName = form.isCorporate
          ? form.companyName.trim()
          : '${form.firstName.trim()} ${form.lastName.trim()}'.trim();
      final companion = _buildCompanion(
        form,
        displayName: displayName.isEmpty ? form.mobile : displayName,
        isUpdate: customerId != null,
      );

      if (customerId == null) {
        await _db.into(_db.customers).insert(companion);
      } else {
        final affected = await (_db.update(_db.customers)
              ..where((row) => row.id.equals(customerId)))
            .write(companion);
        if (affected == 0) return SaveResult.error;
      }

      AppLogger.debug(
        customerId == null
            ? 'Customer saved: $displayName (${form.mobile})'
            : 'Customer updated: #$customerId $displayName (${form.mobile})',
      );
      return SaveResult.success;
    } on Exception catch (e) {
      final message = e.toString().toLowerCase();
      if (message.contains('unique') || message.contains('constraint')) {
        return SaveResult.duplicate;
      }
      AppLogger.debug('Customer save error: $e');
      return SaveResult.error;
    } catch (e) {
      AppLogger.debug('Customer save error: $e');
      return SaveResult.error;
    }
  }

  Future<bool> isMobileDuplicate(
    String mobile, {
    int? excludeCustomerId,
  }) async {
    if (mobile.trim().length != 10) return false;
    return _checkMobileExists(
      mobile.trim(),
      excludeCustomerId: excludeCustomerId,
    );
  }

  CustomersCompanion _buildCompanion(
    AddCustomerFormModel form, {
    required String displayName,
    required bool isUpdate,
  }) {
    return CustomersCompanion(
      name: drift.Value(displayName),
      mobile: drift.Value(form.mobile.trim()),
      city: drift.Value(_nullable(form.city)),
      type: drift.Value(form.customerTier.label),
      entityType: drift.Value(form.entityType.label),
      firstName: drift.Value(_nullable(form.firstName)),
      lastName: drift.Value(_nullable(form.lastName)),
      companyName: drift.Value(_nullable(form.companyName)),
      contactPersonName: drift.Value(_nullable(form.contactPersonName)),
      dateOfBirth: drift.Value(form.dateOfBirth?.toIso8601String()),
      gender: drift.Value(form.gender?.label),
      anniversaryDate: drift.Value(form.anniversaryDate?.toIso8601String()),
      whatsapp: drift.Value(_nullable(form.whatsapp)),
      email: drift.Value(_nullable(form.email)),
      alternateContact: drift.Value(_nullable(form.alternateContact)),
      panNumber: drift.Value(_nullable(form.panNumber)),
      idProofType: drift.Value(form.idProofType?.label),
      idProofNumber: drift.Value(_nullable(form.idProofNumber)),
      idProofDocPath: drift.Value(form.idProofDocPath),
      gstNumber: drift.Value(_nullable(form.gstNumber)),
      addressLine1: drift.Value(_nullable(form.addressLine1)),
      addressLine2: drift.Value(_nullable(form.addressLine2)),
      country: drift.Value(form.country),
      state: drift.Value(_nullable(form.state)),
      pincode: drift.Value(_nullable(form.pincode)),
      openingBalance: drift.Value(form.openingBalance),
      creditLimit: drift.Value(form.creditLimit),
      customerTier: drift.Value(form.customerTier.label),
      membershipId: drift.Value(_nullable(form.membershipId)),
      ringSize: drift.Value(form.ringSize?.label),
      bangleSize: drift.Value(form.bangleSize?.label),
      familyDetailsJson: drift.Value(
        form.familyMembers.isEmpty
            ? null
            : FamilyMember.encodeList(form.familyMembers),
      ),
      referralSource: drift.Value(form.referralSource?.label),
      notes: drift.Value(_nullable(form.notes)),
      profileImagePath: drift.Value(form.profileImagePath),
      updatedAt:
          isUpdate ? drift.Value(DateTime.now()) : const drift.Value.absent(),
    );
  }

  Future<bool> _checkMobileExists(
    String mobile, {
    int? excludeCustomerId,
  }) async {
    try {
      final query = _db.select(_db.customers)
        ..where((row) {
          final sameMobile = row.mobile.equals(mobile);
          return excludeCustomerId == null
              ? sameMobile
              : sameMobile & row.id.equals(excludeCustomerId).not();
        })
        ..limit(1);
      return await query.getSingleOrNull() != null;
    } catch (_) {
      return false;
    }
  }

  String? _nullable(String value) {
    final normalized = value.trim();
    return normalized.isEmpty ? null : normalized;
  }

  DateTime? _parseDate(String? value) {
    final normalized = value?.trim() ?? '';
    return normalized.isEmpty ? null : DateTime.tryParse(normalized);
  }

  T? _optionalEnum<T>(
    String? rawValue,
    Iterable<T> values,
    String Function(T value) labelOf,
  ) {
    final normalized = rawValue?.trim().toLowerCase() ?? '';
    if (normalized.isEmpty) return null;
    for (final value in values) {
      if (labelOf(value).toLowerCase() == normalized) return value;
    }
    return null;
  }
}

enum SaveResult { success, duplicate, error }