import 'dart:math';

import 'package:drift/drift.dart' as drift;
import 'package:lotus_erp/database/db/app_database.dart';

import '../../models/customer/add_customer/add_customer_form_model.dart';
import '../../models/customer/customer_enums/add_customer_enums.dart';
import 'package:lotus_erp/core/logging/app_logger.dart';
import '../../features/customer/domain/services/customer_contact_value.dart';
import '../../helpers/add_customer_/add_customer_form_validation.dart';
import 'customer_media_store.dart';

class AddCustomerRepository {
  final AppDatabase _db;
  final CustomerMediaStore _mediaStore;

  AddCustomerRepository({AppDatabase? db, CustomerMediaStore? mediaStore})
      : _db = db ?? AppDatabase(),
        _mediaStore = mediaStore ?? CustomerMediaStore();

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
        mobile: CustomerContactValue.displayMobile(customer.mobile),
        sameAsWhatsApp: whatsapp.isNotEmpty &&
            whatsapp == CustomerContactValue.displayMobile(customer.mobile),
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
    final newlyOwnedPaths = <String>[];
    String? previousPhoto;
    String? previousIdProof;
    try {
      if (AddCustomerFormValidation.apply(form).hasErrors) {
        return SaveResult.error;
      }
      final cleanMobile = form.mobile.replaceAll(RegExp(r'[^0-9]'), '');
      final exists = cleanMobile.isNotEmpty &&
          await _checkMobileExists(
            cleanMobile,
            excludeCustomerId: customerId,
          );
      if (exists) return SaveResult.duplicate;

      final displayName = form.isCorporate
          ? form.companyName.trim()
          : '${form.firstName.trim()} ${form.lastName.trim()}'.trim();
      await _db.transaction(() async {
        final existing = customerId == null
            ? null
            : await (_db.select(_db.customers)
                  ..where((row) => row.id.equals(customerId)))
                .getSingleOrNull();
        if (customerId != null && existing == null) {
          throw StateError('Customer no longer exists');
        }
        previousPhoto = existing?.profileImagePath;
        previousIdProof = existing?.idProofDocPath;
        final name = displayName.isEmpty ? 'Walk-in Customer' : displayName;
        final id = customerId ??
            await _db.into(_db.customers).insert(
                  _buildCompanion(
                    form,
                    displayName: name,
                    isUpdate: false,
                    storageMobile: cleanMobile.isEmpty
                        ? 'WALKIN-TEMP-${Random.secure().nextInt(1 << 32)}-${Random.secure().nextInt(1 << 32)}'
                        : cleanMobile,
                  ),
                );
        final photo =
            await _mediaStore.persist(form.profileImagePath, id, 'profile');
        if (photo != null && photo != form.profileImagePath) {
          newlyOwnedPaths.add(photo);
        }
        final proof =
            await _mediaStore.persist(form.idProofDocPath, id, 'identity');
        if (proof != null && proof != form.idProofDocPath) {
          newlyOwnedPaths.add(proof);
        }
        final memberId = existing?.membershipId?.trim().isNotEmpty == true
            ? existing!.membershipId!
            : _membershipId(id);
        await (_db.update(_db.customers)..where((row) => row.id.equals(id)))
            .write(_buildCompanion(
          form,
          displayName: name,
          isUpdate: true,
          membershipId: memberId,
          profileImagePath: photo,
          idProofDocPath: proof,
          storageMobile: cleanMobile.isEmpty ? 'WALKIN-$id' : cleanMobile,
        ));
      });
      try {
        if (previousPhoto != form.profileImagePath) {
          await _mediaStore.deleteIfOwned(previousPhoto);
        }
        if (previousIdProof != form.idProofDocPath) {
          await _mediaStore.deleteIfOwned(previousIdProof);
        }
      } catch (error) {
        AppLogger.debug('Customer media cleanup failed: $error');
      }
      AppLogger.debug(
          customerId == null ? 'Customer created' : 'Customer updated');
      return SaveResult.success;
    } on Exception catch (e) {
      await _discardNewMedia(newlyOwnedPaths);
      final message = e.toString().toLowerCase();
      if (message.contains('unique constraint failed: customers.mobile')) {
        return SaveResult.duplicate;
      }
      AppLogger.debug('Customer save error: $e');
      return SaveResult.error;
    } catch (e) {
      await _discardNewMedia(newlyOwnedPaths);
      AppLogger.debug('Customer save error: $e');
      return SaveResult.error;
    }
  }

  Future<void> _discardNewMedia(List<String> paths) async {
    for (final path in paths) {
      try {
        await _mediaStore.deleteIfOwned(path);
      } catch (error) {
        AppLogger.debug('Customer media rollback cleanup failed: $error');
      }
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
    String? membershipId,
    String? profileImagePath,
    String? idProofDocPath,
    required String storageMobile,
  }) {
    return CustomersCompanion(
      name: drift.Value(displayName),
      mobile: drift.Value(storageMobile),
      city: drift.Value(_nullable(form.city)),
      type: drift.Value(form.customerTier.label),
      entityType: drift.Value(form.entityType.label),
      firstName:
          drift.Value(form.isCorporate ? null : _nullable(form.firstName)),
      lastName: drift.Value(form.isCorporate ? null : _nullable(form.lastName)),
      companyName:
          drift.Value(form.isCorporate ? _nullable(form.companyName) : null),
      contactPersonName: drift.Value(
          form.isCorporate ? _nullable(form.contactPersonName) : null),
      dateOfBirth: drift.Value(form.dateOfBirth?.toIso8601String()),
      gender: drift.Value(form.gender?.label),
      anniversaryDate: drift.Value(form.anniversaryDate?.toIso8601String()),
      whatsapp: drift.Value(_nullable(form.whatsapp)),
      email: drift.Value(_nullable(form.email)),
      alternateContact: drift.Value(_nullable(form.alternateContact)),
      panNumber: drift.Value(_nullable(form.panNumber)),
      idProofType: drift.Value(form.idProofType?.label),
      idProofNumber: drift.Value(_nullable(form.idProofNumber)),
      idProofDocPath: drift.Value(idProofDocPath),
      gstNumber: drift.Value(_nullable(form.gstNumber)),
      addressLine1: drift.Value(_nullable(form.addressLine1)),
      addressLine2: drift.Value(_nullable(form.addressLine2)),
      country: drift.Value(form.country),
      state: drift.Value(_nullable(form.state)),
      pincode: drift.Value(_nullable(form.pincode)),
      customerTier: drift.Value(form.customerTier.label),
      membershipId: drift.Value(membershipId),
      ringSize: drift.Value(form.ringSize?.label),
      bangleSize: drift.Value(form.bangleSize?.label),
      familyDetailsJson: drift.Value(
        form.familyMembers.isEmpty
            ? null
            : FamilyMember.encodeList(form.familyMembers),
      ),
      referralSource: drift.Value(form.referralSource?.label),
      notes: drift.Value(_nullable(form.notes)),
      profileImagePath: drift.Value(profileImagePath),
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
    } catch (error) {
      AppLogger.debug('Customer mobile lookup failed: $error');
      rethrow;
    }
  }

  String _membershipId(int id) {
    final now = DateTime.now();
    final month = now.month.toString().padLeft(2, '0');
    return 'LTMP-${now.year}$month-${id.toString().padLeft(6, '0')}';
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
