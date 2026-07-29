import 'package:flutter_test/flutter_test.dart';

import '../lib/data/mock_data.dart';
import '../lib/models/admin_models.dart';
import '../lib/models/app_models.dart';

void main() {
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
}
