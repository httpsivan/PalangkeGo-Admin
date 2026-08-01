import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    if (widget.application != null)
      await ref
          .read(appDataProvider.notifier)
          .updateApplication(widget.id, ApplicationStatus.verified);
    if (widget.renewal != null)
      await ref
          .read(appDataProvider.notifier)
          .updateRenewal(widget.id, RenewalStatus.approved);
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
      if (widget.application != null)
        await ref.read(appDataProvider.notifier).updateApplication(
              widget.id,
              ApplicationStatus.rejected,
              rejectionReason: value,
            );
      if (widget.renewal != null)
        await ref
            .read(appDataProvider.notifier)
            .updateRenewal(widget.id, RenewalStatus.expired);
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
                            ).colorScheme.onSurface.withOpacity(.5),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            AvatarCircle(name: widget.applicant, size: 46),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.applicant,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Text(
                                  'Submitted: ${shortDate.format(DateTime.now())}  •  ${widget.location}',
                                  style: const TextStyle(fontSize: 10),
                                ),
                              ],
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
                  OutlinedButton(
                    onPressed: () => _moreDocs(context),
                    child: const Text('Request Addl. Docs'),
                  ),
                  const SizedBox(width: 9),
                  FilledButton(
                    onPressed: processing ? null : reject,
                    style: FilledButton.styleFrom(
                      backgroundColor: semanticColors(context).danger,
                    ),
                    child: const Text('Reject'),
                  ),
                  const SizedBox(width: 9),
                  FilledButton(
                    onPressed: processing ? null : approve,
                    style: FilledButton.styleFrom(
                      backgroundColor: semanticColors(context).success,
                    ),
                    child: processing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text('Approve'),
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
        const Text(
          '▣ Required Documents',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 13),
        GridView.count(
          crossAxisCount: MediaQuery.sizeOf(context).width < 600 ? 2 : 3,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.23,
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
    final content = asset == null
        ? Icon(
            Icons.description_outlined,
            size: 55,
            color: semanticColors(context).accent,
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
      child: Container(
        decoration: BoxDecoration(
          color: semanticColors(context).hoverSurface,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: semanticColors(context).subtleBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: content),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Text(
                filename == null ? name : '$name\n$filename',
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summary(BuildContext context) => Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: semanticColors(context).infoContainer.withOpacity(.42),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'APPLICANT SUMMARY',
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 14),
                _item('BUSINESS NAME', 'Morales Artisan Crafts'),
                _item('CATEGORY', widget.category),
                _item('CONTACT NO.', '+63 921 555 0123'),
                _item('EMAIL ADDRESS', 'antonio@crafts.com'),
              ],
            ),
          ),
          if (widget.application?.rejectionReason != null &&
              widget.application!.rejectionReason!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: semanticColors(context).dangerContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: _item(
                'REJECTION REASON',
                widget.application!.rejectionReason!,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: semanticColors(context).subtleBorder),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'INTERNAL WORKFLOW',
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Schedule Site Inspection',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => _appointment(context),
                  icon: const Icon(Icons.calendar_month_outlined, size: 14),
                  label: const Text('Set Appointment'),
                ),
              ],
            ),
          ),
        ],
      );
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
  Future<void> _appointment(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (!mounted || date == null) return;
    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 10, minute: 0),
    );
    if (mounted && time != null)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Inspection scheduled for ${shortDate.format(date)} at ${time.format(context)}.',
          ),
        ),
      );
  }

  Future<void> _moreDocs(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Request additional documents'),
        content: const Text(
          'Choose the missing documents and add a message for the applicant.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(this.context).showSnackBar(
                const SnackBar(content: Text('Document request sent.')),
              );
            },
            child: const Text('Send request'),
          ),
        ],
      ),
    );
  }
}
