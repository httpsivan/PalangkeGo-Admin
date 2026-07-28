enum AccountStatus { active, offline, suspended, blocked }

enum ApplicationStatus { verified, reviewing, invalidDocs, rejected }

enum RenewalStatus { approved, reviewing, expired }

enum ReportStatus { pending, underReview, resolved, dismissed }

enum Priority { high, medium, low }

String enumLabel(Object value) {
  final raw = value.toString().split('.').last;
  final spaced = raw.replaceAllMapped(
    RegExp(r'([A-Z])'),
    (match) => ' ${match.group(1)}',
  );
  return spaced[0].toUpperCase() + spaced.substring(1);
}

class Vendor {
  const Vendor({
    required this.id,
    required this.name,
    required this.email,
    required this.stallType,
    required this.registeredAt,
    required this.status,
    required this.location,
    required this.orders,
    required this.transactions,
    required this.phone,
    required this.residence,
    this.administrativeNotes = '',
  });

  final String id;
  final String name;
  final String email;
  final String stallType;
  final DateTime registeredAt;
  final AccountStatus status;
  final String location;
  final int orders;
  final double transactions;
  final String phone;
  final String residence;
  final String administrativeNotes;

  Vendor copyWith({AccountStatus? status, String? administrativeNotes}) =>
      Vendor(
        id: id,
        name: name,
        email: email,
        stallType: stallType,
        registeredAt: registeredAt,
        status: status ?? this.status,
        location: location,
        orders: orders,
        transactions: transactions,
        phone: phone,
        residence: residence,
        administrativeNotes: administrativeNotes ?? this.administrativeNotes,
      );
}

class Customer {
  const Customer({
    required this.id,
    required this.name,
    required this.email,
    required this.registeredAt,
    required this.transactions,
    required this.status,
    this.administrativeNotes = '',
  });

  final String id;
  final String name;
  final String email;
  final DateTime registeredAt;
  final int transactions;
  final AccountStatus status;
  final String administrativeNotes;

  Customer copyWith({AccountStatus? status, String? administrativeNotes}) =>
      Customer(
        id: id,
        name: name,
        email: email,
        registeredAt: registeredAt,
        transactions: transactions,
        status: status ?? this.status,
        administrativeNotes: administrativeNotes ?? this.administrativeNotes,
      );
}

class VendorApplication {
  const VendorApplication({
    required this.id,
    required this.applicant,
    required this.stallName,
    required this.category,
    required this.submittedAt,
    required this.status,
    required this.location,
  });

  final String id;
  final String applicant;
  final String stallName;
  final String category;
  final DateTime submittedAt;
  final ApplicationStatus status;
  final String location;

  VendorApplication copyWith({ApplicationStatus? status}) => VendorApplication(
        id: id,
        applicant: applicant,
        stallName: stallName,
        category: category,
        submittedAt: submittedAt,
        status: status ?? this.status,
        location: location,
      );
}

class RenewalRequest {
  const RenewalRequest({
    required this.id,
    required this.applicant,
    required this.stallName,
    required this.category,
    required this.expiryDate,
    required this.status,
    required this.location,
  });

  final String id;
  final String applicant;
  final String stallName;
  final String category;
  final DateTime expiryDate;
  final RenewalStatus status;
  final String location;

  RenewalRequest copyWith({RenewalStatus? status}) => RenewalRequest(
        id: id,
        applicant: applicant,
        stallName: stallName,
        category: category,
        expiryDate: expiryDate,
        status: status ?? this.status,
        location: location,
      );
}

class Report {
  const Report({
    required this.id,
    required this.type,
    required this.accountIssue,
    this.category = 'FRUITS',
    required this.submittedBy,
    required this.reason,
    required this.date,
    required this.status,
    required this.priority,
    required this.description,
    required this.reporterEmail,
    required this.phone,
    required this.vendorName,
    required this.owner,
    required this.stallNumber,
    required this.previousViolations,
    required this.notes,
  });

  final String id;
  final String type;
  final String accountIssue;
  final String? category;
  final String submittedBy;
  final String reason;
  final DateTime date;
  final ReportStatus status;
  final Priority priority;
  final String description;
  final String reporterEmail;
  final String phone;
  final String vendorName;
  final String owner;
  final String stallNumber;
  final int previousViolations;
  final String notes;

  Report copyWith({ReportStatus? status, String? notes}) => Report(
        id: id,
        type: type,
        accountIssue: accountIssue,
        category: category ?? 'FRUITS',
        submittedBy: submittedBy,
        reason: reason,
        date: date,
        status: status ?? this.status,
        priority: priority,
        description: description,
        reporterEmail: reporterEmail,
        phone: phone,
        vendorName: vendorName,
        owner: owner,
        stallNumber: stallNumber,
        previousViolations: previousViolations,
        notes: notes ?? this.notes,
      );
}

class Announcement {
  const Announcement({
    required this.title,
    required this.summary,
    required this.audience,
    required this.createdAt,
    required this.isDraft,
  });

  final String title;
  final String summary;
  final String audience;
  final DateTime createdAt;
  final bool isDraft;
}
