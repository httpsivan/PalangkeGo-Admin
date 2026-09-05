import 'package:flutter/material.dart';

import '../models/admin_models.dart';
import '../models/app_models.dart';

final _names = [
  'Aicel D. Castillo Fish Retailer',
  'Diosa Fruit Stand',
  'William Del Rosario Meat Shop',
  'Sophie Sb’s store',
  'Luzon Fresh Produce',
  'Santos Quality Meats',
  'Maria Clara Vegetables',
  'Antonio Crafts',
  'Naga Dry Goods',
  'Rico’s Seafood Corner',
  'Mila General Merchandise',
  'Bicol Harvest',
  'Green Basket Stall',
  'Northside Fish Depot',
  'Tita Lory’s Snacks',
  'Harvest Lane Fruits',
  'Golden Grain Supplies',
  'Market Day Essentials',
  'Coco & Root Pantry',
  'Baybayin Butchery',
  'Fresh Finds Cooperative',
  'Aling Cora’s Greens',
  'Seaside Catch',
  'Seven Hills Grocer',
  'The Corner Basket',
];

final _customers = [
  'Alex Richardson',
  'Linda Williams',
  'Dr. Sarah Chen',
  'Marcus Koppel',
  'Elena Petrova',
  'Juan Dela Cruz',
  'Maria Santos',
  'Paolo Rivera',
  'Bea Navarro',
  'Nina Morales',
  'Catherine Tan',
  'Miguel Flores',
  'Noah Reyes',
  'Jasmine Lim',
  'Kevin Bautista',
  'Rina Villanueva',
  'Oscar Cruz',
  'Tomas Yu',
  'Ivy Fernandez',
  'Gabriel Ramos',
  'Lara Mendoza',
  'Pia Garcia',
  'Derek Wong',
  'Anne Castillo',
  'Sam Ortega',
];

const _applicationApplicants = [
  'Elena Rodriguez',
  'Ricardo Santos',
  'Maria Clara',
  'Antonio Reyes',
  'Bianca Salazar',
  'Carlo Mendoza',
  'Diana Villanueva',
  'Emilio Navarro',
  'Fatima Cruz',
  'Gabriel Lim',
  'Helena Bautista',
  'Isaac Fernandez',
  'Julia Ramos',
  'Kevin Tan',
  'Lucia Flores',
  'Mateo Garcia',
  'Nina Castillo',
  'Omar Rivera',
  'Patricia Yu',
  'Quentin Morales',
  'Rosa Dela Cruz',
  'Samuel Wong',
  'Teresa Mercado',
  'Ulises Aquino',
  'Valeria Reyes',
];

const _applicationStalls = [
  'Luzon Fresh Produce',
  'Santos Quality Meats',
  'Clara Vegetable Cart',
  'Bicol Dry Goods',
  'Riverside Seafood',
  'North Market Fruits',
  'Sunrise Bakery Stall',
  'Green Valley Grocer',
  'Central Spice House',
  'Baybayin Crafts',
  'Harvest Corner',
  'Southside Poultry',
  'Island Roots Pantry',
  'Market Lane Delicacies',
  'Golden Fields Grains',
  'Freshway Dairy Booth',
  'Cedar Home Supplies',
  'Coastal Catch Depot',
  'Orchard Basket',
  'Morning Star Snacks',
  'Pine Street Provisions',
  'Township Tea House',
  'Valley Harvest Goods',
  'Westside Kitchen',
  'Zest and Spice Stall',
];

List<Vendor> seedVendors() {
  final base = DateTime(2023, 10, 12, 10, 45);
  return List.generate(_names.length, (index) {
    final statuses = [
      AccountStatus.active,
      AccountStatus.offline,
      AccountStatus.blocked,
      AccountStatus.active,
    ];
    final types = [
      'Fish',
      'Fruits',
      'Meat',
      'Vegetables',
    ];
    return Vendor(
      id: 'VND-${8492 + index}',
      name: _names[index],
      email: 'vendor_${8492 + index}@mepco.com',
      stallType: types[index % types.length],
      registeredAt: base.add(Duration(days: index * 8, hours: index % 7)),
      status: statuses[index % statuses.length],
      location:
          'Section ${String.fromCharCode(65 + index % 5)}, Stall #${44 + index % 12}',
      orders: 1429 - index * 31,
      transactions: 42800 - index * 875,
      phone: '+63 921 555 ${1000 + index}',
      residence: '${742 + index} Evergreen Terrace, Springfield',
    );
  });
}

List<Customer> seedCustomers() {
  final base = DateTime(2023, 10, 12);
  return List.generate(
    _customers.length,
    (index) => Customer(
      id: 'CUS-${1200 + index}',
      name: _customers[index],
      email:
          '${_customers[index].toLowerCase().replaceAll(RegExp(r'[^a-z]+'), '.')}@example.com',
      registeredAt: base.add(Duration(days: index * 14)),
      transactions: [142, 58, 0, 214, 12, 36, 84][index % 7],
      status: index == 2 ? AccountStatus.blocked : AccountStatus.active,
    ),
  );
}

List<VendorApplication> seedApplications() {
  final categories = [
    'FRUITS',
    'MEAT',
    'VEGETABLES',
    'FISH',
  ];
  final statuses = [
    ApplicationStatus.verified,
    ApplicationStatus.reviewing,
    ApplicationStatus.invalidDocs,
    ApplicationStatus.verified,
  ];
  return List.generate(
    25,
    (index) => VendorApplication(
      id: '#APP-${92834 + index}',
      applicant: _applicationApplicants[index],
      stallName: _applicationStalls[index],
      category: categories[index % categories.length],
      submittedAt: DateTime(2023, 10, 24).subtract(Duration(days: index)),
      status: statuses[index % statuses.length],
      location: 'Block ${14 + index % 4} - Stall ${2 + index % 8}',
      documents: _seedKycDocuments(
          DateTime(2023, 10, 24).subtract(Duration(days: index))),
    ),
  );
}

List<KycDocument> _seedKycDocuments(DateTime uploadedAt) => [
      KycDocument(
        name: 'Mayor\'s Permit',
        filename: 'mayors-permit.pdf',
        mimeType: 'application/pdf',
        uploadedAt: uploadedAt,
      ),
      KycDocument(
        name: 'Sanitary Permit',
        filename: 'sanitary-permit.png',
        mimeType: 'image/png',
        uploadedAt: uploadedAt,
        assetPath: 'assets/images/mobile_conversation.png',
      ),
      KycDocument(
        name: 'Government ID',
        filename: 'government-id.png',
        mimeType: 'image/png',
        uploadedAt: uploadedAt,
        assetPath: 'assets/images/mobile_conversation.png',
      ),
      KycDocument(
        name: 'Fire Certification',
        filename: 'fire-certification.jpg',
        mimeType: 'image/jpeg',
        uploadedAt: uploadedAt,
        assetPath: 'assets/images/spoiled_produce.png',
      ),
      KycDocument(
        name: 'Market Clearance',
        filename: 'market-clearance.png',
        mimeType: 'image/png',
        uploadedAt: uploadedAt,
        assetPath: 'assets/images/mobile_conversation.png',
      ),
    ];

List<RenewalRequest> seedRenewals() {
  final categories = [
    'FRUITS',
    'MEAT',
    'VEGETABLES',
    'FISH',
  ];
  final statuses = [
    RenewalStatus.approved,
    RenewalStatus.reviewing,
    RenewalStatus.expired,
    RenewalStatus.approved,
  ];
  final now = DateTime.now();
  return List.generate(
    25,
    (index) {
      final status = statuses[index % statuses.length];
      final DateTime expiryDate = switch (status) {
        RenewalStatus.expired =>
          now.subtract(Duration(days: 7 + (index % 15))),
        RenewalStatus.reviewing => now.add(
            Duration(
              days: (index % 8 < 4) ? (2 + (index % 5)) : (9 + (index % 7)),
            ),
          ),
        RenewalStatus.approved =>
          now.add(Duration(days: 90 + (index * 7))),
      };
      return RenewalRequest(
        id: '#RN-${92834 + index}',
        applicant: _applicationApplicants[index],
        stallName: _applicationStalls[index],
        category: categories[index % categories.length],
        expiryDate: expiryDate,
        status: status,
        location: 'Block ${14 + index % 4} - Stall ${2 + index % 8}',
      );
    },
  );
}

List<Report> seedReports() {
  final reasons = [
    'Scam or Fraud',
    'Harassment',
    'Bug Report',
    'Incorrect Pricing',
    'Late Delivery',
  ];
  final categories = ['FRUITS', 'MEAT', 'VEGETABLES', 'FISH'];
  final statuses = [
    ReportStatus.pending,
    ReportStatus.underReview,
    ReportStatus.resolved,
  ];
  final priorities = [Priority.high, Priority.medium, Priority.low];
  return List.generate(25, (index) {
    final type = ['Stall Holder', 'Customer', 'Application'][index % 3];
    final accountIssue = switch (index % 3) {
      0 => _names[index ~/ 3],
      1 => _customers[index ~/ 3],
      _ => '${_applicationApplicants[index ~/ 3]} Application',
    };
    final submittedBy = _customers[(index + 9) % _customers.length];

    return Report(
      id: '#RPT-${index + 1}'.padRight(8, '0'),
      type: type,
      accountIssue: accountIssue,
      category: categories[index % categories.length],
      submittedBy: submittedBy,
      reason: reasons[index % reasons.length],
      date: DateTime(2023, 10, 24).subtract(Duration(days: index)),
      status: statuses[index % statuses.length],
      priority: priorities[index % priorities.length],
      description:
          'The seller promised fresh produce but delivered spoiled goods repeatedly and refused a refund. When confronted, the stall holder became hostile and blocked my account on the messaging feature.',
      reporterEmail:
          '${submittedBy.toLowerCase().replaceAll(RegExp(r'[^a-z]+'), '.')}@example.com',
      phone: '+63 917 123 ${4500 + index}',
      vendorName: (type == 'Vendor' || type == 'Stall Holder')
          ? accountIssue
          : _names[(index + 10) % _names.length],
      owner: _customers[(index + 3) % _customers.length],
      stallNumber: 'Block ${12 + index}',
      previousViolations: index % 4,
      notes: '',
    );
  });
}

List<Announcement> seedAnnouncements() => [
      Announcement(
        id: 'ANN-1001',
        title: 'New Market Guidelines',
        summary: 'Updated safety protocols for the upcoming weekend market.',
        audience: 'All Users',
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        isDraft: false,
        notificationType: 'Push notification',
        state: 'Sent',
        createdBy: 'Admin Office',
        recipientCount: 168,
        deliveredCount: 168,
        failedCount: 0,
      ),
      Announcement(
        id: 'ANN-1002',
        title: 'Maintenance Notice',
        summary: 'Payment reconciliation will be available again at 8:00 AM.',
        audience: 'Stall Holders',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        isDraft: false,
        notificationType: 'In-app notice',
        state: 'Sent',
        createdBy: 'Finance Admin',
        recipientCount: 42,
        deliveredCount: 42,
        failedCount: 0,
      ),
      Announcement(
        id: 'ANN-1003',
        title: 'Holiday Operating Hours',
        summary:
            'Please review the special opening schedule for public holidays.',
        audience: 'All Users',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        isDraft: false,
        notificationType: 'Push notification',
        state: 'Sent',
        createdBy: 'Admin Office',
        recipientCount: 168,
        deliveredCount: 165,
        failedCount: 3,
      ),
      Announcement(
        id: 'ANN-1004',
        title: 'Stall Holder Orientation & Training',
        summary: 'New stall holders can reserve a training slot this week.',
        audience: 'Stall Holders',
        createdAt: DateTime.now().subtract(const Duration(days: 4)),
        isDraft: false,
        notificationType: 'In-app notice',
        state: 'Sent',
        createdBy: 'Market Supervisor',
        recipientCount: 42,
        deliveredCount: 42,
        failedCount: 0,
      ),
      Announcement(
        id: 'ANN-1005',
        title: 'Fresh Finds Rewards Campaign',
        summary: 'Customers can now redeem points at participating stalls.',
        audience: 'Customers',
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        isDraft: false,
        notificationType: 'Push notification',
        state: 'Sent',
        createdBy: 'Marketing Desk',
        recipientCount: 126,
        deliveredCount: 126,
        failedCount: 0,
      ),
      Announcement(
        id: 'ANN-1006',
        title: 'Weekend Market Sanitation Protocol Draft',
        summary: 'Scheduled deep cleaning for fish and meat market aisles.',
        audience: 'Stall Holders',
        createdAt: DateTime.now().subtract(const Duration(days: 7)),
        isDraft: true,
        notificationType: 'In-app notice',
        state: 'Draft',
        createdBy: 'Admin Office',
        recipientCount: 42,
        deliveredCount: 0,
        failedCount: 0,
      ),
    ];

const topSellerNames = ['Ivan Navarro', 'Akisha San Miguel', 'Schylle Palmero'];
const topSellerRevenue = ['43.9k', '34.1k', '17.1k'];
const topSellerOrders = ['2395 orders', '2013 orders', '1579 orders'];

List<Order> seedOrders() {
  final customers = [
    'Alex Richardson',
    'Linda Williams',
    'Juan Dela Cruz',
    'Maria Santos'
  ];
  final vendors = [
    'Aicel D. Castillo Fish Retailer',
    'Diosa Fruit Stand',
    'Santos Quality Meats',
    'Luzon Fresh Produce'
  ];
  final stalls = [
    'Fish Section',
    'Fruit Section',
    'Meat Section',
    'Vegetables Section'
  ];
  final products = [
    ('Bangus', 'FISH', 220.0),
    ('Mangoes', 'FRUITS', 180.0),
    ('Pork Belly', 'MEAT', 360.0),
    ('Fresh Vegetables', 'VEGETABLES', 150.0),
  ];
  final statuses = [
    OrderStatus.completed,
    OrderStatus.completed,
    OrderStatus.processing,
    OrderStatus.pending,
    OrderStatus.refunded,
    OrderStatus.cancelled,
  ];
  final payments = [
    PaymentStatus.paid,
    PaymentStatus.paid,
    PaymentStatus.pending,
    PaymentStatus.pending,
    PaymentStatus.refunded,
    PaymentStatus.failed,
  ];
  final methods = [
    PaymentMethod.gcash,
    PaymentMethod.card,
    PaymentMethod.wallet,
    PaymentMethod.cashOnDelivery,
  ];
  return List.generate(48, (index) {
    final product = products[index % products.length];
    final second = products[(index + 1) % products.length];
    final quantity = 1 + index % 4;
    final items = [
      OrderItem(
        name: product.$1,
        category: product.$2,
        quantity: quantity,
        unitPrice: product.$3,
      ),
      if (index % 3 == 0)
        OrderItem(
          name: second.$1,
          category: second.$2,
          quantity: 1,
          unitPrice: second.$3,
        ),
    ];
    return Order(
      id: 'ORD-${2026001 + index}',
      transactionId: 'TXN-${72001 + index}',
      placedAt: DateTime.now()
          .subtract(Duration(days: index % 38, hours: index % 12)),
      customerName: customers[index % customers.length],
      vendorName: vendors[index % vendors.length],
      stallName: stalls[index % stalls.length],
      items: items,
      discounts: index % 5 == 0 ? 25 : 0,
      deliveryFee: 40,
      platformFee: 15,
      refundAmount:
          statuses[index % statuses.length] == OrderStatus.refunded ? 120 : 0,
      paymentMethod: methods[index % methods.length],
      paymentStatus: payments[index % payments.length],
      status: statuses[index % statuses.length],
    );
  });
}

const avatarColors = [
  Color(0xFFFFD7B5),
  Color(0xFFB8D8FF),
  Color(0xFFC8E6C9),
  Color(0xFFFFE0B2),
  Color(0xFFE1BEE7),
];
