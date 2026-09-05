import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/utils/formatters.dart';
import '../../core/widgets/admin_widgets.dart';
import '../../data/repositories/mock_repository.dart';
import '../../models/app_models.dart';

class VerificationDialog extends ConsumerStatefulWidget {
  const VerificationDialog.application(this.application, {super.key})
      : renewal = null;
  const VerificationDialog.renewal(this.renewal, {super.key})
      : application = null;
  final VendorApplication? application;
  final RenewalRequest? renewal;
  String get applicant => application?.applicant ?? renewal!.applicant;
  String get stall => application?.stallName ?? renewal!.stallName;
  String get category => application?.category ?? renewal!.category;
  String get location => application?.location ?? renewal!.location;
  String get id => application?.id ?? renewal!.id;
  @override
  ConsumerState<VerificationDialog> createState() => _VerificationDialogState();
}

class _VerificationDialogState extends ConsumerState<VerificationDialog> {
  bool processing = false;

  Future<void> approve() async {
    final okay = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approve application?'),
        content: const Text('This will grant marketplace access.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Approve'),
          ),
        ],
      ),
    );
    if (okay != true || !mounted) return;
    setState(() => processing = true);
    if (widget.application != null) {
      await ref
          .read(appDataProvider.notifier)
          .updateApplication(widget.id, ApplicationStatus.verified);
    }
    if (widget.renewal != null) {
      await ref
          .read(appDataProvider.notifier)
          .updateRenewal(widget.id, RenewalStatus.approved);
    }
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Application approved.')));
    }
  }

  Future<void> reject() async {
    final reason = TextEditingController();
    try {
      final value = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Reject application'),
          content: TextField(
            controller: reason,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(hintText: 'Add a reason...'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, reason.text.trim()),
              child: const Text('Reject'),
            ),
          ],
        ),
      );
      if (value == null || value.isEmpty || !mounted) return;
      setState(() => processing = true);
      if (widget.application != null) {
        await ref.read(appDataProvider.notifier).updateApplication(
              widget.id,
              ApplicationStatus.rejected,
              rejectionReason: value,
            );
      }
      if (widget.renewal != null) {
        await ref
            .read(appDataProvider.notifier)
            .updateRenewal(widget.id, RenewalStatus.expired);
      }
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Application rejected.')));
      }
    } finally {
      reason.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.sizeOf(context).width < 850;
    return Dialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: narrow ? 10 : 55,
        vertical: narrow ? 10 : 34,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 970, maxHeight: 720),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'TENANTS  /  VERIFICATION DETAIL',
                          style: TextStyle(
                            fontSize: 9,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: .5),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            AvatarCircle(name: widget.applicant, size: 46),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.applicant,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  Text(
                                    'Submitted: ${shortDate.format(DateTime.now())}  •  ${widget.location}',
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 10),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 17),
              const Divider(),
              const SizedBox(height: 17),
              if (narrow) ...[
                _documents(context),
                const SizedBox(height: 18),
                _summary(context),
              ] else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 68, child: _documents(context)),
                    const SizedBox(width: 25),
                    Expanded(flex: 32, child: _summary(context)),
                  ],
                ),
              const SizedBox(height: 22),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    onPressed: processing ? null : _moreDocs,
                    icon: const Icon(Icons.document_scanner_outlined, size: 15),
                    label: const Text('Request Additional Documents'),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: semanticColors(context).subtleBorder),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton.icon(
                    onPressed: processing ? null : reject,
                    icon: const Icon(Icons.close_rounded, size: 15, color: Color(0xFFEF4444)),
                    label: const Text('Reject', style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.w700)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFEF4444), width: 1.2),
                      backgroundColor: const Color(0xFFEF4444).withValues(alpha: 0.06),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    ),
                  ),
                  const SizedBox(width: 10),
                  FilledButton.icon(
                    onPressed: processing ? null : approve,
                    icon: processing
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.check_rounded, size: 16),
                    label: const Text('Approve', style: TextStyle(fontWeight: FontWeight.w700)),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF059669),
                      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _documents(BuildContext context) {
    final documents = widget.application?.documents ?? const <KycDocument>[];
    final tiles = documents.isNotEmpty
        ? documents.map((document) => _docModel(context, document)).toList()
        : [
            _doc(context, 'Mayor’s Permit', null),
            _doc(
              context,
              'Sanitary Permit',
              'assets/images/mobile_conversation.png',
            ),
            _doc(context, 'ID', 'assets/images/mobile_conversation.png'),
            _doc(
              context,
              'Fire Certification',
              'assets/images/spoiled_produce.png',
            ),
            _doc(
              context,
              'Market Clearance',
              'assets/images/mobile_conversation.png',
            ),
          ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.grid_view_rounded,
              size: 16,
              color: semanticColors(context).secondaryText,
            ),
            const SizedBox(width: 8),
            Text(
              'Required Documents',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: semanticColors(context).primaryText,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        GridView.count(
          crossAxisCount: MediaQuery.sizeOf(context).width < 600 ? 2 : 3,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: 1.2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: tiles,
        ),
      ],
    );
  }

  Widget _docModel(BuildContext context, KycDocument document) {
    final asset = document.assetPath;
    return _doc(
      context,
      document.name,
      asset,
      filename:
          '${document.filename} • ${shortDate.format(document.uploadedAt)}',
    );
  }

  Widget _doc(
    BuildContext context,
    String name,
    String? asset, {
    String? filename,
  }) {
    final colors = semanticColors(context);
    final content = asset == null
        ? Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colors.accent.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.description_outlined,
                size: 38,
                color: colors.accent,
              ),
            ),
          )
        : Image.asset(asset, fit: BoxFit.cover);

    return InkWell(
      onTap: () => showDialog<void>(
        context: context,
        builder: (context) => Dialog(
          child: asset == null
              ? const Icon(Icons.description_outlined, size: 160)
              : Image.asset(asset),
        ),
      ),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: colors.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.subtleBorder, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
                child: content,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: colors.subtleBorder, width: 0.8),
                ),
              ),
              child: Text(
                filename == null ? name : '$name\n$filename',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: colors.primaryText,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summary(BuildContext context) {
    final colors = semanticColors(context);
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: colors.cardBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.subtleBorder, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'APPLICANT SUMMARY',
                style: GoogleFonts.inter(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: colors.secondaryText,
                ),
              ),
              const SizedBox(height: 14),
              _item('BUSINESS NAME', widget.stall),
              Padding(
                padding: const EdgeInsets.only(bottom: 13),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('CATEGORY', style: TextStyle(fontSize: 8.5)),
                    const SizedBox(height: 5),
                    CategoryBadge(category: widget.category),
                  ],
                ),
              ),
              _item('CONTACT NO.', '+63 921 555 0123'),
              _item(
                'EMAIL ADDRESS',
                '${widget.applicant.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '.')}@gmail.com',
              ),
            ],
          ),
        ),
        if (widget.application?.rejectionReason != null &&
            widget.application!.rejectionReason!.isNotEmpty) ...[
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.dangerContainer,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.3)),
            ),
            child: _item(
              widget.application!.status == ApplicationStatus.invalidDocs
                  ? 'REQUIRED DOCUMENTS / NOTES'
                  : 'REJECTION REASON',
              widget.application!.rejectionReason!,
            ),
          ),
        ],
      ],
    );
  }

  Widget _item(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 13),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 8.5)),
            const SizedBox(height: 3),
            Text(
              value,
              style:
                  const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      );

  Future<void> _moreDocs() async {
    final notes = TextEditingController();
    try {
      final value = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Request Additional Documents'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Specify the missing or updated documents required from the applicant:',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notes,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText:
                      'e.g. Please upload a clear Mayor\'s Permit and valid Sanitary Clearance...',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(
                context,
                notes.text.trim().isEmpty
                    ? 'Additional documents required'
                    : notes.text.trim(),
              ),
              child: const Text('Send Request'),
            ),
          ],
        ),
      );
      if (value == null || !mounted) return;
      setState(() => processing = true);
      if (widget.application != null) {
        await ref.read(appDataProvider.notifier).updateApplication(
              widget.id,
              ApplicationStatus.invalidDocs,
              rejectionReason: value,
            );
      }
      if (widget.renewal != null) {
        await ref
            .read(appDataProvider.notifier)
            .updateRenewal(widget.id, RenewalStatus.reviewing);
      }
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Additional documents requested from ${widget.applicant}.',
            ),
          ),
        );
      }
    } finally {
      notes.dispose();
    }
  }
}
