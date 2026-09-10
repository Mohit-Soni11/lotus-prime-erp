part of 'booking_advance_controller.dart';

extension BookingAdvanceControllerPersistence on BookingAdvanceController {
  Future<bool> _initializeForEdit(int orderId) async {
    isLoadingEditOrder = true;
    editLoadError = null;
    _emitChanged();

    try {
      final details = await _repo.fetchEditableBooking(orderId);
      if (details == null) {
        editLoadError = 'Advance order could not be loaded for editing.';
        return false;
      }

      _clearAll();
      final order = details.order;
      editingOrderId = order.id;
      _editingOrderNo = order.orderNo;
      selectedCustomerId = order.customerId;

      final customer = details.customer;
      if (customer != null) {
        mobileCtrl.text = customer.mobile;
        nameCtrl.text = customer.name;
        cityCtrl.text = _repo.customerAddressForBooking(customer);
        _selectedCustomerMobile = mobileCtrl.text.trim();
        _selectedCustomerName = nameCtrl.text.trim();
      }

      bookingType = order.bookingType.toUpperCase() == 'LOCKED'
          ? BookingType.locked
          : BookingType.open;
      lockedRateCtrl.text = _formatNumber(order.lockedRate);
      deliveryDate = order.deliveryDate;

      final item = BookingItemModel(metal: _metalFromLabel(order.metalType));
      item.descCtrl.text = order.itemName;
      item.purityCtrl.text = order.purity;
      item.grossCtrl.text = _formatNumber(order.approxWeight);
      item.lessCtrl.text = '';
      item.rateCtrl.text = _formatNumber(order.lockedRate);
      item.addListener(_onChildChanged);
      bookingItems.add(item);
      activeItemIndex = 0;

      final totalAdvance =
          details.advances.fold<double>(0, (sum, row) => sum + row.amountPaid);
      cashCtrl.text = _formatNumber(totalAdvance);
      _cashInput = totalAdvance;
      if (details.advances.isNotEmpty && lockedRateCtrl.text.isEmpty) {
        lockedRateCtrl.text = _formatNumber(details.advances.first.rateOnDate);
      }

      _syncSmartRatePreference();
      _emitChanged();
      return true;
    } catch (error) {
      editLoadError = 'Advance order could not be loaded for editing.';
      return false;
    } finally {
      isLoadingEditOrder = false;
      _emitChanged();
    }
  }

  Future<
      ({
        bool success,
        String message,
        String bookingNo,
        List<int> orderIds,
      })> _saveBooking() async {
    if (nameCtrl.text.trim().isEmpty) {
      return (
        success: false,
        message: 'Please enter customer name.',
        bookingNo: '',
        orderIds: const <int>[],
      );
    }
    if (bookingItems.isEmpty) {
      return (
        success: false,
        message: 'Please add at least one booking item.',
        bookingNo: '',
        orderIds: const <int>[],
      );
    }
    _syncSmartRatePreference();

    if (bookingType == BookingType.locked && lockedRate <= 0) {
      return (
        success: false,
        message: 'Please enter a valid locked rate.',
        bookingNo: '',
        orderIds: const <int>[],
      );
    }
    for (var index = 0; index < bookingItems.length; index++) {
      final item = bookingItems[index];
      if (item.netWt <= 0) {
        return (
          success: false,
          message: 'Please enter valid net weight for item ${index + 1}.',
          bookingNo: '',
          orderIds: const <int>[],
        );
      }
    }
    final minimumAdvanceMessage = _minimumAdvanceValidationMessage();
    if (minimumAdvanceMessage != null) {
      return (
        success: false,
        message: minimumAdvanceMessage,
        bookingNo: '',
        orderIds: const <int>[],
      );
    }

    isSaving = true;
    _emitChanged();

    try {
      if (_isNumberLoading) {
        await _initBookingNumber();
      }

      final customerId = await _repo.resolveCustomerForBooking(
        selectedCustomerId: selectedCustomerId,
        customerName: nameCtrl.text,
        customerMobile: mobileCtrl.text,
        address: cityCtrl.text,
        panNumber: '',
        gstNumber: '',
      );
      selectedCustomerId = customerId;

      final perItemAdv = bookingItems.isEmpty
          ? totalAdvance
          : totalAdvance / bookingItems.length;

      final activeEditOrderId = editingOrderId;
      if (activeEditOrderId != null) {
        final item = bookingItems.first;
        final savedBookingNo = formattedBookingNo;
        await _repo.updateBooking(
          orderId: activeEditOrderId,
          customerId: customerId,
          itemName: item.descCtrl.text.trim().isEmpty
              ? '${item.metal.displayName} Item'
              : item.descCtrl.text.trim(),
          metalType: item.metal.displayName,
          purity: item.purityCtrl.text.isEmpty ? '22K' : item.purityCtrl.text,
          approxWeight: item.netWt,
          bookingType: bookingType == BookingType.locked ? 'LOCKED' : 'OPEN',
          lockedRate:
              bookingType == BookingType.locked ? _lockedRateForItem(item) : 0,
          deliveryDate: deliveryDate,
          notes: null,
          totalAdvance: totalAdvance,
          rateOnDate: _p(item.rateCtrl.text),
        );

        _clearAll();
        isSaving = false;
        _emitChanged();

        return (
          success: true,
          message: 'Booking $savedBookingNo updated successfully!',
          bookingNo: savedBookingNo,
          orderIds: <int>[activeEditOrderId],
        );
      }

      final savedDocument = await _repo.saveBookingDocument(
        customerId: customerId,
        lines: bookingItems
            .map((item) => _bookingLineDraft(item, perItemAdv))
            .toList(growable: false),
      );

      await _initBookingNumber();

      _clearAll();
      isSaving = false;
      _emitChanged();

      return (
        success: true,
        message: 'Booking ${savedDocument.bookingNo} saved successfully!',
        bookingNo: savedDocument.bookingNo,
        orderIds: savedDocument.orderIds,
      );
    } catch (e) {
      isSaving = false;
      _emitChanged();
      AppLogger.debug('Booking save error: $e');
      return (
        success: false,
        message: 'Failed to save. Please try again.',
        bookingNo: '',
        orderIds: const <int>[],
      );
    }
  }

  Future<BookingInvoiceDraftResult> _buildInvoicePreviewDraft() async {
    final validationMessage = _validateBookingDraft();
    if (validationMessage != null) {
      return BookingInvoiceDraftResult(
        success: false,
        message: validationMessage,
        bookings: const [],
      );
    }

    if (_isNumberLoading) {
      await _initBookingNumber();
    }

    _syncSmartRatePreference();
    _emitChanged();

    final now = DateTime.now();
    final bookingNo = formattedBookingNo;
    final perItemAdvance = bookingItems.isEmpty
        ? totalAdvance
        : totalAdvance / bookingItems.length;
    final customer = _buildPreviewCustomer(now);
    final previewBookings = <EditableBookingAdvance>[];

    for (var index = 0; index < bookingItems.length; index++) {
      final item = bookingItems[index];
      final orderId = editingOrderId ?? -(index + 1);
      final rate =
          bookingType == BookingType.locked ? _lockedRateForItem(item) : 0.0;
      previewBookings.add(
        EditableBookingAdvance(
          order: SalesOrder(
            id: orderId,
            createdAt: now,
            orderNo: bookingNo,
            customerId: selectedCustomerId ?? 0,
            itemName: item.descCtrl.text.trim().isEmpty
                ? '${item.metal.displayName} Item'
                : item.descCtrl.text.trim(),
            metalType: item.metal.displayName,
            purity: item.purityCtrl.text.isEmpty ? '22K' : item.purityCtrl.text,
            approxWeight: item.netWt,
            bookingType: bookingType == BookingType.locked ? 'LOCKED' : 'OPEN',
            lockedRate: rate,
            status: 'PREVIEW',
            deliveryDate: deliveryDate,
          ),
          customer: customer,
          advances: perItemAdvance > 0
              ? [
                  OrderAdvance(
                    id: -(index + 1),
                    createdAt: now,
                    orderId: orderId,
                    amountPaid: perItemAdvance,
                    rateOnDate: _p(item.rateCtrl.text),
                    paymentDate: now,
                  ),
                ]
              : const [],
        ),
      );
    }

    return BookingInvoiceDraftResult(
      success: true,
      message: 'Booking invoice preview is ready.',
      bookings: List.unmodifiable(previewBookings),
    );
  }

  void _clearAllAndNotify() {
    _clearAll();
    _emitChanged();
  }

  void _clearAll() {
    mobileCtrl.clear();
    nameCtrl.clear();
    cityCtrl.clear();
    lockedRateCtrl.clear();
    cashCtrl.clear();
    upiCtrl.clear();
    cardCtrl.clear();
    _cashInput = 0;
    _upiInput = 0;
    _cardInput = 0;
    selectedCustomerId = null;
    _selectedCustomerMobile = '';
    _selectedCustomerName = '';
    editingOrderId = null;
    _editingOrderNo = null;
    editLoadError = null;
    _applyBillingDefaults();
    customerResults = [];
    customerNotFound = false;
    for (final i in bookingItems) {
      i.removeListener(_onChildChanged);
      i.dispose();
    }
    for (final i in scrapItems) {
      i.removeListener(_onChildChanged);
      i.dispose();
    }
    bookingItems.clear();
    scrapItems.clear();
    activeItemIndex = -1;
  }

  BookingAdvanceLineDraft _bookingLineDraft(
    BookingItemModel item,
    double advanceAmount,
  ) {
    return BookingAdvanceLineDraft(
      itemName: item.descCtrl.text.trim().isEmpty
          ? '${item.metal.displayName} Item'
          : item.descCtrl.text.trim(),
      metalType: item.metal.displayName,
      purity: item.purityCtrl.text.isEmpty ? '22K' : item.purityCtrl.text,
      approxWeight: item.netWt,
      bookingType: bookingType == BookingType.locked ? 'LOCKED' : 'OPEN',
      lockedRate:
          bookingType == BookingType.locked ? _lockedRateForItem(item) : 0,
      deliveryDate: deliveryDate,
      notes: null,
      advanceAmount: advanceAmount,
      rateOnDate: _p(item.rateCtrl.text),
    );
  }

  String? _validateBookingDraft() {
    if (nameCtrl.text.trim().isEmpty) {
      return 'Please enter customer name.';
    }
    if (bookingItems.isEmpty) {
      return 'Please add at least one booking item.';
    }
    _syncSmartRatePreference();
    if (bookingType == BookingType.locked && lockedRate <= 0) {
      return 'Please enter a valid locked rate.';
    }
    for (var index = 0; index < bookingItems.length; index++) {
      if (bookingItems[index].netWt <= 0) {
        return 'Please enter valid net weight for item ${index + 1}.';
      }
    }
    final minimumAdvanceMessage = _minimumAdvanceValidationMessage();
    if (minimumAdvanceMessage != null) return minimumAdvanceMessage;
    return null;
  }

  Customer _buildPreviewCustomer(DateTime now) {
    final cleanMobile = mobileCtrl.text.replaceAll(RegExp(r'[^0-9]'), '');
    final displayName = nameCtrl.text.trim().isEmpty
        ? cleanMobile.isEmpty
            ? 'Walk-in Customer'
            : 'Customer ${cleanMobile.substring(cleanMobile.length - 4)}'
        : nameCtrl.text.trim();
    return Customer(
      id: selectedCustomerId ?? 0,
      createdAt: now,
      name: displayName,
      mobile: cleanMobile,
      type: 'Regular',
      entityType: 'Individual',
      firstName: displayName,
      addressLine1: cityCtrl.text.trim().isEmpty ? null : cityCtrl.text.trim(),
      country: 'India',
      openingBalance: 0,
      creditLimit: 0,
      customerTier: 'Regular',
    );
  }
}
