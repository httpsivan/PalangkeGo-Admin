import 'package:flutter/material.dart';

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
      'Fish Section',
      'Fruit Section',
      'Meat Section',
      'Vegetables Section',
      'Dry Goods',
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
  final applicants = [
    'Elena Rodriguez',
    'Ricardo Santos',
    'Maria Clara',
    'Maria Clara',
    'Antonio Reyes',
  ];
  final stalls = [
    'Luzon Fresh Produce',
    'Santos Quality Meats',
    'Vegetables',
    'Vegetables',
    'Bicol Dry Goods',
  ];
  final categories = [
    'FRUITS',
    'MEAT',
    'VEGETABLES',
    'VEGETABLES',
    'DRY GOODS',
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
      applicant: applicants[index % applicants.length],
      stallName: stalls[index % stalls.length],
      category: categories[index % categories.length],
      submittedAt: DateTime(2023, 10, 24).subtract(Duration(days: index)),
      status: statuses[index % statuses.length],
      location: 'Block ${14 + index % 4} - Stall ${2 + index % 8}',
    ),
  );
}

List<RenewalRequest> seedRenewals() {
  final applicants = [
    'Elena Rodriguez',
    'Ricardo Santos',
    'Maria Clara',
    'Maria Clara',
    'Antonio Reyes',
  ];
  final stalls = [
    'Luzon Fresh Produce',
    'Santos Quality Meats',
    'Vegetables',
    'Vegetables',
    'Bicol Dry Goods',
  ];
  final categories = [
    'FRUITS',
    'MEAT',
    'VEGETABLES',
    'VEGETABLES',
    'DRY GOODS',
  ];
  final statuses = [
    RenewalStatus.approved,
    RenewalStatus.reviewing,
    RenewalStatus.expired,
    RenewalStatus.approved,
  ];
  final expiry = [14, -7, 54, -27, 4];
  final now = DateTime.now();
  return List.generate(
    25,
    (index) => RenewalRequest(
      id: '#RN-${92834 + index}',
      applicant: applicants[index % applicants.length],
      stallName: stalls[index % stalls.length],
      category: categories[index % categories.length],
      expiryDate: now.add(
        Duration(days: expiry[index % expiry.length] - index),
      ),
      status: statuses[index % statuses.length],
      location: 'Block ${14 + index % 4} - Stall ${2 + index % 8}',
    ),
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
  final statuses = [
    ReportStatus.pending,
    ReportStatus.underReview,
    ReportStatus.resolved,
  ];
  final priorities = [Priority.high, Priority.medium, Priority.low];
  return List.generate(
    25,
    (index) => Report(
      id: '#RPT-${index + 1}'.padRight(8, '0'),
      type: ['Vendor', 'Customer', 'Application'][index % 3],
      accountIssue: [
        'Diosa Fruit Stand',
        'Juan Dela Cruz',
        'Payout Issue',
        'Sophie Sb’s store',
      ][index % 4],
      submittedBy: [
        'Maria Santos',
        'Admin Tool',
        'Elena Rodriguez',
        'Juan Dela Cruz',
      ][index % 4],
      reason: reasons[index % reasons.length],
      date: DateTime(2023, 10, 24).subtract(Duration(days: index)),
      status: statuses[index % statuses.length],
      priority: priorities[index % priorities.length],
      description:
          'The seller promised fresh produce but delivered spoiled goods repeatedly and refused a refund. When confronted, the vendor became hostile and blocked my account on the messaging feature.',
      reporterEmail: 'm.santos@email.com',
      phone: '+63 917 123 4567',
      vendorName: 'Diosa Fruit Stand',
      owner: 'Maria Santos',
      stallNumber: 'Block 12',
      previousViolations: 2,
      notes: '',
    ),
  );
}

List<Announcement> seedAnnouncements() => [
  Announcement(
    title: 'New Market Guidelines',
    summary: 'Updated safety protocols for the upcoming weekend market.',
    audience: 'General',
    createdAt: DateTime.now().subtract(const Duration(hours: 1)),
    isDraft: false,
  ),
  Announcement(
    title: 'Maintenance Notice',
    summary: 'Payment reconciliation will be available again at 8:00 AM.',
    audience: 'Vendors',
    createdAt: DateTime.now().subtract(const Duration(days: 1)),
    isDraft: false,
  ),
  Announcement(
    title: 'Holiday Operating Hours',
    summary: 'Please review the special opening schedule for public holidays.',
    audience: 'All Users',
    createdAt: DateTime.now().subtract(const Duration(days: 2)),
    isDraft: false,
  ),
  Announcement(
    title: 'Vendor Orientation',
    summary: 'New stall holders can reserve a training slot this week.',
    audience: 'Vendors',
    createdAt: DateTime.now().subtract(const Duration(days: 4)),
    isDraft: false,
  ),
  Announcement(
    title: 'Fresh Finds Rewards',
    summary: 'Customers can now redeem points at participating stalls.',
    audience: 'Customers',
    createdAt: DateTime.now().subtract(const Duration(days: 5)),
    isDraft: false,
  ),
];

const topSellerNames = ['Ivan Navarro', 'Akisha San Miguel', 'Schylle Palmero'];
const topSellerRevenue = ['43.9k', '34.1k', '17.1k'];
const topSellerOrders = ['2395 orders', '2013 orders', '1579 orders'];

const avatarColors = [
  Color(0xFFFFD7B5),
  Color(0xFFB8D8FF),
  Color(0xFFC8E6C9),
  Color(0xFFFFE0B2),
  Color(0xFFE1BEE7),
];
