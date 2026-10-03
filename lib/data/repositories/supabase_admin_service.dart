import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/admin_models.dart';
import '../../models/app_models.dart';

final supabaseAdminServiceProvider = Provider<SupabaseAdminService>((ref) {
  SupabaseClient? client;
  try {
    client = Supabase.instance.client;
  } catch (_) {
    client = null;
  }
  return SupabaseAdminService(client: client);
});

/// Central Supabase administration client for querying and synchronizing
/// announcements, KYC applications, and sales orders directly with the shared
/// Supabase database used by PalengkeGoAPP.
class SupabaseAdminService {
  const SupabaseAdminService({SupabaseClient? client}) : _client = client;

  final SupabaseClient? _client;

  SupabaseClient? get client {
    if (_client != null) return _client;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  bool get isConfigured => client != null;

  // ── Announcements ─────────────────────────────────────────────────────────

  /// Fetches all announcements from `system_announcements`.
  Future<List<Announcement>> fetchAnnouncements() async {
    final sb = client;
    if (sb == null) return [];

    try {
      final response = await sb
          .from('system_announcements')
          .select('*')
          .order('created_at', ascending: false);

      final list = response as List<dynamic>? ?? [];
      return list.map((item) {
        final map = Map<String, dynamic>.from(item as Map);
        final id = (map['id'] ?? map['announcement_id'] ?? '').toString();
        final rawAudience =
            (map['target_audience'] ?? map['targetAudience']) as String?;
        final audience = targetAudienceToDisplay(rawAudience);
        final createdAt = DateTime.tryParse(
              map['created_at']?.toString() ??
                  map['createdAt']?.toString() ??
                  '',
            ) ??
            DateTime.now();
        final expiresAt = map['expires_at'] != null
            ? DateTime.tryParse(map['expires_at'].toString())
            : (map['expiresAt'] != null
                ? DateTime.tryParse(map['expiresAt'].toString())
                : null);

        return Announcement(
          id: id,
          title: (map['title'] as String?) ?? '',
          summary: (map['body'] as String?) ?? '',
          audience: audience,
          createdAt: createdAt,
          expiresAt: expiresAt,
          isDraft: false,
          state: 'Sent',
          imageUrl: (map['image_url'] ?? map['imageUrl']) as String?,
          createdBy: (map['created_by'] as String?) ?? 'ADM-001',
        );
      }).toList();
    } catch (e) {
      debugPrint('[admin] Supabase fetchAnnouncements failed: $e');
      return [];
    }
  }

  /// Inserts a newly published announcement into `system_announcements`.
  Future<String?> publishAnnouncement({
    required String title,
    required String body,
    required String audience,
    DateTime? expiresAt,
    String? imageUrl,
    Uint8List? imageBytes,
  }) async {
    final sb = client;
    if (sb == null) return 'Supabase client is not configured';

    try {
      String? resolvedImageUrl = imageUrl;
      if (imageBytes != null && imageBytes.isNotEmpty) {
        final uploaded = await _uploadImageBytes(imageBytes);
        if (uploaded != null) resolvedImageUrl = uploaded;
      }

      final payload = <String, dynamic>{
        'title': title,
        'body': body,
        'target_audience': audienceToTargetAudience(audience),
        'created_at': DateTime.now().toUtc().toIso8601String(),
        if (expiresAt != null)
          'expires_at': expiresAt.toUtc().toIso8601String(),
        if (resolvedImageUrl != null && resolvedImageUrl.isNotEmpty)
          'image_url': resolvedImageUrl,
      };

      await sb.from('system_announcements').insert(payload);
      return null;
    } catch (e) {
      debugPrint('[admin] Supabase publishAnnouncement error: $e');
      return e.toString();
    }
  }

  /// Updates an announcement in `system_announcements`.
  Future<String?> updateAnnouncement({
    required String id,
    required String title,
    required String body,
    required String audience,
    DateTime? expiresAt,
    String? imageUrl,
    Uint8List? imageBytes,
    bool clearImage = false,
  }) async {
    final sb = client;
    if (sb == null) return 'Supabase client is not configured';

    try {
      String? resolvedImageUrl = imageUrl;
      if (imageBytes != null && imageBytes.isNotEmpty) {
        final uploaded = await _uploadImageBytes(imageBytes);
        if (uploaded != null) resolvedImageUrl = uploaded;
      }

      final payload = <String, dynamic>{
        'title': title,
        'body': body,
        'target_audience': audienceToTargetAudience(audience),
        if (expiresAt != null)
          'expires_at': expiresAt.toUtc().toIso8601String(),
        if (clearImage)
          'image_url': null
        else if (resolvedImageUrl != null && resolvedImageUrl.isNotEmpty)
          'image_url': resolvedImageUrl,
      };

      try {
        await sb.from('system_announcements').update(payload).eq('id', id);
      } catch (_) {
        await sb
            .from('system_announcements')
            .update(payload)
            .eq('announcement_id', id);
      }
      return null;
    } catch (e) {
      debugPrint('[admin] Supabase updateAnnouncement error: $e');
      return e.toString();
    }
  }

  /// Deletes an announcement in `system_announcements`.
  Future<String?> deleteAnnouncement(String id) async {
    final sb = client;
    if (sb == null) return 'Supabase client is not configured';

    try {
      try {
        await sb.from('system_announcements').delete().eq('id', id);
      } catch (_) {
        await sb.from('system_announcements').delete().eq('announcement_id', id);
      }
      return null;
    } catch (e) {
      debugPrint('[admin] Supabase deleteAnnouncement error: $e');
      return e.toString();
    }
  }

  // ── KYC Applications ──────────────────────────────────────────────────────

  /// Loads vendor KYC submissions from `kyc_submissions` table.
  Future<List<VendorApplication>> fetchApplications() async {
    final sb = client;
    if (sb == null) return [];

    try {
      final kycRows = await sb
          .from('kyc_submissions')
          .select('*')
          .order('submitted_at', ascending: false);

      final stallsRows = await sb.from('stall_holders').select('*');
      final usersRows = await sb.from('users').select('*');

      final stallById = <String, Map<String, dynamic>>{};
      for (final item in (stallsRows as List<dynamic>? ?? [])) {
        final m = Map<String, dynamic>.from(item as Map);
        final id = (m['stall_holder_id'] ?? m['id'] ?? '').toString();
        if (id.isNotEmpty) stallById[id] = m;
      }

      final userById = <String, Map<String, dynamic>>{};
      for (final item in (usersRows as List<dynamic>? ?? [])) {
        final m = Map<String, dynamic>.from(item as Map);
        final id = (m['user_id'] ?? m['id'] ?? '').toString();
        if (id.isNotEmpty) userById[id] = m;
      }

      final results = <VendorApplication>[];
      for (final item in (kycRows as List<dynamic>? ?? [])) {
        final kyc = Map<String, dynamic>.from(item as Map);
        final id = (kyc['kyc_id'] ?? kyc['id'] ?? '').toString();
        final stallId = (kyc['stall_holder_id'] ?? '').toString();
        final stall = stallById[stallId] ?? const <String, dynamic>{};
        final user = userById[stallId] ?? const <String, dynamic>{};

        final submittedAt = DateTime.tryParse(
              kyc['submitted_at']?.toString() ?? '',
            ) ??
            DateTime.now();

        final rawStatus = (kyc['status'] as String? ?? 'pending').toLowerCase();
        final status = switch (rawStatus) {
          'approved' => ApplicationStatus.verified,
          'rejected' => ApplicationStatus.rejected,
          'invaliddocs' || 'invalid_docs' => ApplicationStatus.invalidDocs,
          _ => ApplicationStatus.reviewing,
        };

        final applicantName = (user['full_name'] ??
                user['displayName'] ??
                kyc['owner_name']) as String? ??
            'Vendor ($stallId)';
        final stallName = (stall['stall_name'] ??
                stall['name'] ??
                kyc['stall_name']) as String? ??
            'Stall $stallId';
        final category = (stall['category'] ?? kyc['category']) as String? ??
            'General';
        final location = stall['stall_number'] != null
            ? 'Stall #${stall['stall_number']}, Floor ${stall['floor_number'] ?? '1'}'
            : 'Main Wet Market';

        final documents = <KycDocument>[];
        void addDoc(String name, String? url) {
          if (url != null && url.isNotEmpty) {
            documents.add(
              KycDocument(
                name: name,
                filename: url.split('/').last.split('?').first,
                mimeType: 'image/*',
                uploadedAt: submittedAt,
                fileUrl: url,
                idFrontUrl: url,
              ),
            );
          }
        }

        addDoc("Mayor's Permit", kyc['mayor_permit_url'] as String?);
        addDoc("Sanitary Permit", kyc['sanitary_permit_url'] as String?);
        addDoc(
            "Fire Safety Certificate", kyc['fire_certification_url'] as String?);
        addDoc("Market Clearance", kyc['market_clearance_url'] as String?);
        addDoc("Valid Government ID", kyc['valid_id_photo_url'] as String?);
        addDoc("Selfie Verification", kyc['selfie_url'] as String?);

        results.add(
          VendorApplication(
            id: id,
            applicant: applicantName,
            stallName: stallName,
            category: category,
            submittedAt: submittedAt,
            status: status,
            location: location,
            documents: documents,
            rejectionReason: kyc['rejection_reason'] as String?,
            reviewedAt: kyc['reviewed_at'] != null
                ? DateTime.tryParse(kyc['reviewed_at'].toString())
                : null,
            reviewedBy: kyc['reviewed_by'] as String?,
          ),
        );
      }

      return results;
    } catch (e) {
      debugPrint('[admin] Supabase fetchApplications failed: $e');
      return [];
    }
  }

  /// Updates application status in `kyc_submissions` and `stall_holders`.
  Future<String?> updateApplicationStatus(
    String id,
    ApplicationStatus status, {
    String? rejectionReason,
    String? stallHolderId,
  }) async {
    final sb = client;
    if (sb == null) return 'Supabase client is not configured';

    try {
      final isApproved = status == ApplicationStatus.verified;
      final dbStatus = isApproved ? 'approved' : 'rejected';

      await sb.from('kyc_submissions').update({
        'status': dbStatus,
        'reviewed_at': DateTime.now().toUtc().toIso8601String(),
        'reviewed_by': 'Admin',
        if (rejectionReason != null) 'rejection_reason': rejectionReason,
      }).or('kyc_id.eq.$id,id.eq.$id');

      if (stallHolderId != null && stallHolderId.isNotEmpty) {
        await sb.from('stall_holders').update({
          'kyc_status': dbStatus,
          'is_kyc_approved': isApproved,
        }).or('stall_holder_id.eq.$stallHolderId,id.eq.$stallHolderId');
      }
      return null;
    } catch (e) {
      debugPrint('[admin] Supabase updateApplicationStatus failed: $e');
      return e.toString();
    }
  }

  // ── Orders & Sales Reports ────────────────────────────────────────────────

  /// Fetches orders from Supabase `orders` and `order_items` tables.
  Future<List<Order>> fetchOrders() async {
    final sb = client;
    if (sb == null) return [];

    try {
      final orderRows = await sb
          .from('orders')
          .select('*')
          .order('created_at', ascending: false)
          .limit(500);

      final itemsRows = await sb.from('order_items').select('*');
      final stallsRows = await sb.from('stall_holders').select('*');

      final itemsByOrderId = <String, List<OrderItem>>{};
      for (final item in (itemsRows as List<dynamic>? ?? [])) {
        final m = Map<String, dynamic>.from(item as Map);
        final orderId = (m['order_id'] ?? '').toString();
        if (orderId.isEmpty) continue;

        itemsByOrderId.putIfAbsent(orderId, () => []).add(
              OrderItem(
                name: (m['product_name'] ?? 'Product').toString(),
                category: (m['category'] ?? 'Produce').toString(),
                quantity: ((m['quantity'] as num?) ?? 1).round(),
                unitPrice: ((m['unit_price'] ?? m['price_at_order'] as num?) ??
                        0.0)
                    .toDouble(),
              ),
            );
      }

      final stallById = <String, Map<String, dynamic>>{};
      for (final item in (stallsRows as List<dynamic>? ?? [])) {
        final m = Map<String, dynamic>.from(item as Map);
        final id = (m['stall_holder_id'] ?? m['id'] ?? '').toString();
        if (id.isNotEmpty) stallById[id] = m;
      }

      final results = <Order>[];
      for (final item in (orderRows as List<dynamic>? ?? [])) {
        final row = Map<String, dynamic>.from(item as Map);
        final orderId = (row['order_id'] ?? row['id'] ?? '').toString();
        final stallId = (row['stall_holder_id'] ?? '').toString();
        final stall = stallById[stallId] ?? const <String, dynamic>{};

        final stallName = (stall['stall_name'] ??
                stall['name'] ??
                row['vendor_name']) as String? ??
            'Market Stall';
        final vendorName = (stall['owner_name'] ?? stallName) as String;

        final items = itemsByOrderId[orderId] ??
            [
              OrderItem(
                name: 'Market Produce',
                category: 'General',
                quantity: 1,
                unitPrice:
                    ((row['total_amount'] ?? row['total'] as num?) ?? 0.0)
                        .toDouble(),
              ),
            ];

        final pm = (row['payment_method'] as String? ?? 'cod').toLowerCase();
        final paymentMethod = switch (pm) {
          'gcash' => PaymentMethod.gcash,
          'card' => PaymentMethod.card,
          'wallet' => PaymentMethod.wallet,
          _ => PaymentMethod.cashOnDelivery,
        };

        final ps =
            (row['payment_status'] as String? ?? 'pending').toLowerCase();
        final paymentStatus = switch (ps) {
          'paid' => PaymentStatus.paid,
          'refunded' => PaymentStatus.refunded,
          'partially_refunded' => PaymentStatus.partiallyRefunded,
          'failed' => PaymentStatus.failed,
          _ => PaymentStatus.pending,
        };

        final os = (row['order_status'] ??
                row['status'] as String? ??
                'pending')
            .toLowerCase();
        final orderStatus = switch (os) {
          'completed' || 'delivered' => OrderStatus.completed,
          'cancelled' => OrderStatus.cancelled,
          'refunded' => OrderStatus.refunded,
          'preparing' ||
          'ready' ||
          'processing' ||
          'out_for_delivery' ||
          'outfordelivery' =>
            OrderStatus.processing,
          _ => OrderStatus.pending,
        };

        results.add(
          Order(
            id: orderId,
            transactionId: stallId.isNotEmpty ? stallId : orderId,
            placedAt: DateTime.tryParse(
                  row['created_at']?.toString() ??
                      row['placed_at']?.toString() ??
                      '',
                ) ??
                DateTime.now(),
            customerName:
                (row['customer_name'] as String?) ?? 'Market Customer',
            vendorName: vendorName,
            stallName: stallName,
            items: items,
            discounts: ((row['discounts'] as num?) ?? 0.0).toDouble(),
            deliveryFee: ((row['delivery_fee'] as num?) ?? 0.0).toDouble(),
            platformFee: ((row['service_fee'] as num?) ?? 0.0).toDouble(),
            refundAmount: ((row['refunded_amount'] as num?) ?? 0.0).toDouble(),
            paymentMethod: paymentMethod,
            paymentStatus: paymentStatus,
            status: orderStatus,
          ),
        );
      }

      return results;
    } catch (e) {
      debugPrint('[admin] Supabase fetchOrders failed: $e');
      return [];
    }
  }

  // ── Account Blocking Sync ─────────────────────────────────────────────────

  /// Syncs an account block/unblock state with Supabase `users` table.
  Future<void> setAccountBlocked(String userId, bool blocked) async {
    final sb = client;
    if (sb == null) return;
    try {
      await sb
          .from('users')
          .update({'is_blocked': blocked, 'updated_at': DateTime.now().toUtc().toIso8601String()})
          .or('user_id.eq.$userId,id.eq.$userId');
    } catch (e) {
      debugPrint('[admin] Supabase setAccountBlocked failed: $e');
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Future<String?> _uploadImageBytes(Uint8List bytes) async {
    final sb = client;
    if (sb == null) return null;
    try {
      final fileName =
          'announcement_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await sb.storage.from('stalls').uploadBinary(
            fileName,
            bytes,
            fileOptions:
                const FileOptions(contentType: 'image/jpeg', upsert: true),
          );
      return sb.storage.from('stalls').getPublicUrl(fileName);
    } catch (e) {
      debugPrint('[admin] Storage upload fallback: $e');
      return null;
    }
  }

  static String audienceToTargetAudience(String audience) {
    switch (audience.trim().toLowerCase()) {
      case 'stall holders':
      case 'stallholders':
      case 'vendors':
      case 'vendor':
        return 'stallholders';
      case 'customers':
      case 'customer':
        return 'customers';
      default:
        return 'all';
    }
  }

  static String targetAudienceToDisplay(String? targetAudience) {
    switch (targetAudience?.trim().toLowerCase()) {
      case 'stallholders':
      case 'vendors':
        return 'Stall Holders';
      case 'customers':
        return 'Customers';
      default:
        return 'All Users';
    }
  }
}
