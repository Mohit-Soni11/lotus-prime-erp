part of 'customer_profile_repository.dart';

mixin _CustomerProfileGirviQueries {
  AppDatabase get _db;
  double _girviInterestOutstanding(
    GirviLoan loan,
    List<GirviPayment> payments,
  ) {
    if (GirviStatus.fromDb(loan.status).isClosed) return 0;
    final principalRepaid = payments.fold<double>(0, (sum, payment) {
      final type = GirviPaymentType.fromDb(payment.paymentType);
      if (type == GirviPaymentType.partialPrincipal) {
        return sum + payment.amount;
      }
      if (type == GirviPaymentType.interest ||
          type == GirviPaymentType.partialInterest) {
        return sum + payment.principalComponent;
      }
      return sum;
    });
    return GirviInterestCalculator.quoteAt(
      principal: loan.loanAmount + principalRepaid,
      monthlyRatePercent: loan.interestRate,
      startDate: loan.startDate,
      asOf: loan.releaseDate ?? DateTime.now(),
      adjustments: GirviInterestPaymentAdjustments.fromPayments(payments),
    ).interestOutstanding;
  }

  Future<GirviInvoiceDraft?> fetchGirviInvoiceDraft({
    required int customerId,
    required int loanId,
  }) async {
    try {
      final loan = await (_db.select(_db.girviLoans)
            ..where(
              (t) => t.id.equals(loanId) & t.customerId.equals(customerId),
            ))
          .getSingleOrNull();
      if (loan == null) return null;

      final customer = await (_db.select(_db.customers)
            ..where((t) => t.id.equals(customerId)))
          .getSingleOrNull();
      if (customer == null) return null;

      final itemRows = await (_db.select(_db.girviLoanItems)
            ..where((t) => t.girviId.equals(loanId))
            ..orderBy([(t) => OrderingTerm(expression: t.serialNo)]))
          .get();

      final itemIds = itemRows.map((item) => item.id).toList(growable: false);
      final photoRows = itemIds.isEmpty
          ? const <GirviItemPhoto>[]
          : await (_db.select(_db.girviItemPhotos)
                ..where((t) => t.itemId.isIn(itemIds))
                ..orderBy([
                  (t) => OrderingTerm(expression: t.itemId),
                  (t) => OrderingTerm(expression: t.sortOrder),
                ]))
              .get();

      final photosByItem = <int, List<String>>{};
      for (final photo in photoRows) {
        photosByItem.putIfAbsent(photo.itemId, () => []).add(photo.filePath);
      }

      final disbursementRows = await (_db.select(_db.girviDisbursements)
            ..where((t) => t.girviId.equals(loanId))
            ..orderBy([(t) => OrderingTerm(expression: t.sequenceNo)]))
          .get();
      final ledgerRows = await (_db.select(_db.girviPayments)
            ..where((t) => t.girviId.equals(loanId))
            ..orderBy([
              (t) => OrderingTerm(expression: t.paymentDate),
              (t) => OrderingTerm(expression: t.id),
            ]))
          .get();

      final maturityDate = loan.maturityDate ??
          DateTime(
            loan.startDate.year,
            loan.startDate.month + loan.durationMonths,
            loan.startDate.day,
          );

      final payments = disbursementRows
          .map(
            (entry) => GirviInvoicePayment(
              label: entry.displayLabel,
              amount: entry.amount,
            ),
          )
          .toList(growable: false);

      final disbursementSummary = payments.isEmpty
          ? loan.disbursementMode
          : payments
              .map(
                (entry) =>
                    '${entry.label} Rs ${entry.amount.toStringAsFixed(2)}',
              )
              .join(' + ');
      final interestAdjustments =
          GirviInterestPaymentAdjustments.fromPayments(ledgerRows);
      final hasInterestCollection = interestAdjustments.any(
        (entry) => entry.paid > 0 || entry.discount > 0,
      );
      final status = GirviStatus.fromDb(loan.status);
      final fullySettled = status == GirviStatus.released ||
          status == GirviStatus.readyForDelivery;
      final receiptMode = fullySettled
          ? GirviReceiptMode.release
          : hasInterestCollection ||
                  loan.lastInterestPaidDate != null ||
                  status == GirviStatus.partialRelease
              ? GirviReceiptMode.interest
              : GirviReceiptMode.pledge;
      var legacyPrincipalRepaid = 0.0;
      var releasePrincipalPaid = 0.0;
      var releasePrincipalDiscount = 0.0;
      for (final payment in ledgerRows) {
        final type = GirviPaymentType.fromDb(payment.paymentType);
        if (type == GirviPaymentType.interest ||
            type == GirviPaymentType.partialInterest) {
          legacyPrincipalRepaid += payment.principalComponent;
        } else if (type == GirviPaymentType.partialPrincipal) {
          legacyPrincipalRepaid += payment.amount;
        } else if (type == GirviPaymentType.fullRelease) {
          releasePrincipalPaid += payment.principalComponent;
          releasePrincipalDiscount += payment.principalDiscountComponent;
        }
      }
      final interestAsOfDate = loan.releaseDate ?? DateTime.now();
      final interestQuote = GirviInterestCalculator.quoteAt(
        principal: loan.loanAmount + legacyPrincipalRepaid,
        monthlyRatePercent: loan.interestRate,
        startDate: loan.startDate,
        asOf: interestAsOfDate,
        adjustments: interestAdjustments,
      );
      final monthlyInterest = receiptMode == GirviReceiptMode.pledge
          ? 0.0
          : interestQuote.currentMonthlyInterest;
      final totalInterest = receiptMode == GirviReceiptMode.pledge
          ? 0.0
          : interestQuote.grossInterest;
      final releaseTotal = loan.releaseTotalAmount ?? 0;
      final principalOutstanding = fullySettled
          ? 0.0
          : (loan.loanAmount - releasePrincipalPaid - releasePrincipalDiscount)
              .clamp(0.0, double.infinity)
              .toDouble();
      final interestOutstanding =
          fullySettled ? 0.0 : interestQuote.interestOutstanding;

      return GirviInvoiceDraft(
        loanId: loan.id,
        ticketNo: loan.ticketNo,
        createdAt: loan.createdAt,
        customerName: customer.name,
        customerMobile: CustomerContactValue.displayMobile(customer.mobile),
        customerCity: customer.city ?? '',
        customerAddress: _formatCustomerAddress(customer),
        items: itemRows
            .map(
              (item) => GirviInvoiceItemDraft(
                serialNo: item.serialNo,
                metal: item.metalType,
                description: item.itemName,
                purity: item.purity,
                pieces: item.pieces,
                grossWeight: item.grossWeight,
                lessWeight: item.lessWeight,
                netWeight: item.netWeight,
                huid: item.huidNumber ?? '',
                photoPaths:
                    List.unmodifiable(photosByItem[item.id] ?? const []),
              ),
            )
            .toList(growable: false),
        loanAmount: loan.loanAmount,
        interestPrincipal: loan.loanAmount + legacyPrincipalRepaid,
        interestRate: loan.interestRate,
        durationMonths: loan.durationMonths,
        startDate: loan.startDate,
        maturityDate: maturityDate,
        interestAsOfDate: interestAsOfDate,
        monthlyInterest: monthlyInterest,
        totalInterest: totalInterest,
        totalDue: loan.loanAmount + totalInterest,
        payments: List.unmodifiable(payments),
        disbursementSummary: disbursementSummary,
        ledgerEntries: List.unmodifiable(
          ledgerRows.map(
            (entry) {
              final type = GirviPaymentType.fromDb(entry.paymentType);
              final mode = GirviPaymentMode.fromDb(entry.paymentMode);
              return GirviInvoiceLedgerEntry(
                date: entry.paymentDate,
                typeLabel: type.displayName,
                modeLabel: mode.displayName,
                amount: entry.amount,
                principalAmount: entry.principalComponent,
                interestAmount: entry.interestComponent,
                discountAmount: entry.principalDiscountComponent +
                    entry.interestDiscountComponent,
                balanceAfter: entry.balanceAfter,
                monthsCovered: entry.monthsCovered,
                interestFromDate: entry.interestFromDate,
                interestToDate: entry.interestToDate,
                notes: entry.notes,
              );
            },
          ),
        ),
        interestAdjustments: interestAdjustments,
        mode: receiptMode,
        accountStatus: status.displayName,
        recoveryDisposition: status == GirviStatus.auctioned
            ? GirviRecoveryDisposition.fromItemStatuses(
                itemRows.map((item) => item.recoveryDispositionStatus),
              )
            : null,
        releaseDate: loan.releaseDate,
        expectedDeliveryDate: loan.expectedDeliveryDate,
        deliveredAt: loan.deliveredAt,
        lastInterestPaidDate: loan.lastInterestPaidDate,
        releasePrincipal: loan.releasePrincipal,
        releaseInterest: loan.releaseInterest,
        releasePenalty: loan.releasePenalty,
        releaseDiscount: loan.releaseDiscount,
        releaseTotalAmount: releaseTotal > 0 ? releaseTotal : null,
        releasePaymentMode: loan.releasePaymentMode,
        releaseNotes: loan.releaseNotes,
        releasedBy: loan.releasedBy,
        principalOutstanding: principalOutstanding,
        interestOutstanding: interestOutstanding,
        idProofType: loan.idProofType,
        idProofNumber: loan.idProofNumber,
        idProofImagePath: loan.idProofImagePath,
        notes: loan.notes,
      );
    } catch (e) {
      AppLogger.error("Customer girvi invoice draft fetch error: $e");
      return null;
    }
  }

  String _formatCustomerAddress(Customer customer) {
    final parts = <String>[
      customer.addressLine1 ?? '',
      customer.addressLine2 ?? '',
      customer.city ?? '',
      customer.state ?? '',
      customer.pincode ?? '',
      customer.country.trim().toLowerCase() == 'india' ? '' : customer.country,
    ];
    final cleanParts = <String>[];
    for (final part in parts) {
      final value = part.trim();
      if (value.isNotEmpty && !cleanParts.contains(value)) {
        cleanParts.add(value);
      }
    }
    return cleanParts.join(', ');
  }
}
