import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:palengkego_admin/data/mock_data.dart';
import 'package:palengkego_admin/data/repositories/mock_repository.dart';
import 'package:palengkego_admin/models/admin_models.dart';
import 'package:palengkego_admin/models/app_models.dart';

void main() {
  test('mock list data uses unique display names', () {
    final applications = seedApplications();
    final renewals = seedRenewals();
    final reports = seedReports();

    expect(
      applications.map((item) => item.applicant).toSet(),
      hasLength(applications.length),
    );
    expect(
      applications.map((item) => item.stallName).toSet(),
      hasLength(applications.length),
    );
    expect(
      renewals.map((item) => item.applicant).toSet(),
      hasLength(renewals.length),
    );
    expect(
      renewals.map((item) => item.stallName).toSet(),
      hasLength(renewals.length),
    );
    expect(
      reports.map((item) => item.accountIssue).toSet(),
      hasLength(reports.length),
    );
    expect(
      reports.map((item) => item.submittedBy).toSet(),
      hasLength(reports.length),
    );
  });

  test('order totals and net revenue are computed from line items', () {
    final order = Order(
      id: 'ORD-1',
      transactionId: 'TX-1',
      placedAt: DateTime(2026, 7, 28),
      customerName: 'Customer',
      vendorName: 'Vendor',
      stallName: 'Stall',
      items: const [
        OrderItem(
          name: 'Rice',
          category: 'GRAINS',
          quantity: 2,
          unitPrice: 100,
        ),
      ],
      discounts: 20,
      deliveryFee: 50,
      platformFee: 10,
      refundAmount: 30,
      paymentMethod: PaymentMethod.gcash,
      paymentStatus: PaymentStatus.paid,
      status: OrderStatus.completed,
    );

    expect(order.subtotal, 200);
    expect(order.total, 240);
    expect(order.netRevenue, 210);
    expect(order.quantity, 2);
    expect(order.categories, 'GRAINS');
  });

  test('sales summary aggregates seeded order data', () {
    final orders = seedOrders();
    final summary = SalesSummary.fromOrders(orders);

    expect(summary.totalOrders, orders.length);
    expect(summary.grossSales, greaterThan(0));
    expect(summary.netRevenue, greaterThan(0));
    expect(
      summary.completedOrders +
          summary.pendingOrders +
          summary.cancelledOrders +
          summary.refundedOrders,
      orders.length,
    );
  });

  test('suspension is active only inside its date window', () {
    final now = DateTime.now();
    final suspension = Suspension(
      id: 'SUS-1',
      accountId: 'VND-1',
      accountName: 'Vendor',
      accountType: 'Vendor',
      reason: 'Policy violation',
      startDate: now.subtract(const Duration(hours: 1)),
      endDate: now.add(const Duration(days: 1)),
      administratorId: 'ADM-001',
      createdAt: now,
      note: '',
      notifyUser: true,
    );

    expect(suspension.isActive, isTrue);
    expect(suspension.isExpired, isFalse);
    expect(suspension.lift(now).isActive, isFalse);
  });

  test('application stores KYC documents and rejection reason', () {
    final application = VendorApplication(
      id: 'APP-1',
      applicant: 'Vendor',
      stallName: 'Stall',
      category: 'FRUITS',
      submittedAt: DateTime(2026, 7, 28),
      status: ApplicationStatus.rejected,
      location: 'Block 1',
      documents: [
        KycDocument(
          name: 'Permit',
          filename: 'permit.pdf',
          mimeType: 'application/pdf',
          uploadedAt: DateTime(2026, 7, 28),
        ),
      ],
      rejectionReason: 'Document is unreadable',
    );

    expect(application.documents, hasLength(1));
    expect(application.rejectionReason, 'Document is unreadable');
  });

  test(
      'dismissing a report moves it to resolved history without changing account',
      () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final controller = AppDataController(preferences, firebaseEnabled: false);
    final report = controller.state.reports.firstWhere(
      (item) =>
          item.type == 'Customer' && item.accountIssue == 'Juan Dela Cruz',
    );

    final error = await controller.dismissReport(
      reportId: report.id,
      note: 'No policy violation found.',
    );

    expect(error, isNull);
    final updated = controller.state.reports.firstWhere(
      (item) => item.id == report.id,
    );
    expect(updated.status, ReportStatus.resolved);
    expect(updated.decision, 'No Violation');
    expect(updated.actionTaken, 'Dismissed');
    expect(
      controller.state.customers
          .firstWhere((item) => item.name == 'Juan Dela Cruz')
          .status,
      AccountStatus.active,
    );
    expect(
      controller.state.auditLogs.first.action,
      AuditAction.resolveReport,
    );
  });

  test('suspending a reported account resolves the report and can be lifted',
      () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final controller = AppDataController(preferences, firebaseEnabled: false);
    final report = controller.state.reports.firstWhere(
      (item) =>
          item.type == 'Customer' && item.accountIssue == 'Juan Dela Cruz',
    );
    final start = DateTime.now();
    final end = start.add(const Duration(days: 7));

    final error = await controller.suspendAccountFromReport(
      reportId: report.id,
      reason: 'Marketplace violation',
      startDate: start,
      endDate: end,
    );

    expect(error, isNull);
    final suspension = controller.state.suspensions.firstWhere(
      (item) => item.relatedReportId == report.id,
    );
    expect(
      controller.state.customers
          .firstWhere((item) => item.name == 'Juan Dela Cruz')
          .status,
      AccountStatus.suspended,
    );
    expect(
      controller.state.reports
          .firstWhere((item) => item.id == report.id)
          .decision,
      'Account Suspended',
    );

    await controller.liftSuspension(suspension.id);

    expect(
      controller.state.customers
          .firstWhere((item) => item.name == 'Juan Dela Cruz')
          .status,
      AccountStatus.active,
    );
    expect(
      controller.state.reports
          .firstWhere((item) => item.id == report.id)
          .status,
      ReportStatus.resolved,
    );
    expect(
      controller.state.auditLogs.first.metadata['relatedReportId'],
      report.id,
    );
  });

  test('blocking a reported vendor stores details and supports unblocking',
      () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final controller = AppDataController(preferences, firebaseEnabled: false);
    final report = controller.state.reports.firstWhere(
      (item) =>
          item.type == 'Vendor' && item.accountIssue == 'Diosa Fruit Stand',
    );

    final error = await controller.blockAccountFromReport(
      reportId: report.id,
      reason: 'Repeated marketplace violations',
    );

    expect(error, isNull);
    final vendor = controller.state.vendors.firstWhere(
      (item) => item.name == 'Diosa Fruit Stand',
    );
    expect(vendor.status, AccountStatus.blocked);
    expect(vendor.blockedReason, 'Repeated marketplace violations');
    expect(vendor.blockedFromReportId, report.id);
    expect(
      controller.state.reports
          .firstWhere((item) => item.id == report.id)
          .status,
      ReportStatus.resolved,
    );

    await controller.updateVendorAccount(
      vendor.id,
      status: AccountStatus.active,
      administrativeNotes: '',
    );

    final unblocked = controller.state.vendors.firstWhere(
      (item) => item.id == vendor.id,
    );
    expect(unblocked.status, AccountStatus.active);
    expect(unblocked.blockedReason, isNull);
    expect(
      controller.state.reports
          .firstWhere((item) => item.id == report.id)
          .status,
      ReportStatus.resolved,
    );
  });

  test('blocking a suspended account closes its active suspension', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final controller = AppDataController(preferences, firebaseEnabled: false);
    final vendor = controller.state.vendors.first;
    final report = controller.state.reports.firstWhere(
      (item) => item.type == 'Vendor' && item.accountIssue == vendor.name,
    );

    final suspensionError = await controller.createSuspension(
      accountId: vendor.id,
      accountName: vendor.name,
      accountType: 'Vendor',
      reason: 'Temporary investigation hold',
      startDate: DateTime.now(),
      endDate: DateTime.now().add(const Duration(days: 7)),
      note: '',
      notifyUser: false,
    );
    expect(suspensionError, isNull);
    expect(
      controller.state.vendors
          .firstWhere((item) => item.id == vendor.id)
          .status,
      AccountStatus.suspended,
    );

    final blockError = await controller.blockAccountFromReport(
      reportId: report.id,
      reason: 'Confirmed policy violation',
    );

    expect(blockError, isNull);
    expect(
      controller.state.vendors
          .firstWhere((item) => item.id == vendor.id)
          .status,
      AccountStatus.blocked,
    );
    expect(
      controller.state.suspensions
          .where((item) => item.accountId == vendor.id && item.isActive),
      isEmpty,
    );
  });
}
