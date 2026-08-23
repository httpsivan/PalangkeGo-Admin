import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/widgets/admin_widgets.dart';
import '../../data/repositories/mock_repository.dart';
import '../../models/app_models.dart';

class AnnouncementDialog extends ConsumerStatefulWidget {
  const AnnouncementDialog({super.key});
  @override
  ConsumerState<AnnouncementDialog> createState() => _AnnouncementDialogState();
}

class _AnnouncementDialogState extends ConsumerState<AnnouncementDialog> {
  final title = TextEditingController(text: 'Public Market Holiday Notice');
  final body = TextEditingController(
    text:
        'Good day! Please be informed that the PalengkeGo services will be temporarily unavailable on Friday due to the scheduled holiday maintenance. Vendors are advised to settle transactions early. Thank you!',
  );
  String audience = 'All Users';
  bool notify = true, loading = false;
  Uint8List? image;
  @override
  void dispose() {
    title.dispose();
    body.dispose();
    super.dispose();
  }

  Future<void> pick() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (mounted && result?.files.single.bytes != null) {
      setState(() => image = result!.files.single.bytes);
    }
  }

  Future<void> save(bool draft) async {
    if (title.text.trim().isEmpty || body.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add a title and message before saving.')),
      );
      return;
    }
    setState(() => loading = true);
    final data = ref.read(appDataProvider);
    final profile = ref.read(adminProfileProvider);
    final recipients = switch (audience) {
      'Vendors' => data.vendors.length,
      'Customers' => data.customers.length,
      _ => data.vendors.length + data.customers.length,
    };
    await ref.read(appDataProvider.notifier).addAnnouncement(
          Announcement(
            id: 'ANN-${DateTime.now().millisecondsSinceEpoch}',
            title: title.text.trim(),
            summary: body.text.trim(),
            audience: audience,
            createdAt: DateTime.now(),
            isDraft: draft,
            notificationType: notify ? 'Push notification' : 'In-app notice',
            state: draft ? 'Draft' : 'Queued locally',
            createdBy: profile.name,
            recipientCount: recipients,
            deliveredCount: draft ? 0 : (notify ? recipients : 0),
          ),
        );
    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          draft
              ? 'Announcement saved as draft locally.'
              : 'Announcement queued locally; backend delivery is not configured.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = semanticColors(context);
    final narrow = MediaQuery.sizeOf(context).width < 700;
    return Dialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: narrow ? 12 : 80,
        vertical: narrow ? 18 : 48,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(28, 22, 28, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Compose New Announcement',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const StatusBadge(
                    label: 'DRAFT MODE',
                    kind: BadgeKind.success,
                  ),
                ],
              ),
              const SizedBox(height: 17),
              const Divider(),
              const SizedBox(height: 15),
              const Text(
                'Announcement Title',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 7),
              TextField(controller: title),
              const SizedBox(height: 15),
              const Text(
                'Target Audience',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 7),
              DropdownButtonFormField<String>(
                initialValue: audience,
                items: ['All Users', 'Vendors', 'Customers']
                    .map(
                      (value) => DropdownMenuItem(
                        value: value,
                        child: Text(
                          value,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) =>
                    setState(() => audience = value ?? audience),
              ),
              const SizedBox(height: 16),
              const Text(
                'Feature Image (Optional)',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 7),
              InkWell(
                onTap: pick,
                child: Container(
                  width: double.infinity,
                  height: 94,
                  decoration: BoxDecoration(
                    color: colors.infoContainer.withValues(alpha: .48),
                    border: Border.all(color: colors.info.withValues(alpha: .35)),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: image == null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_photo_alternate_outlined,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: .7),
                              size: 26,
                            ),
                            Text(
                              'Drag and drop or click to upload',
                              style: TextStyle(
                                fontSize: 11,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: .7),
                              ),
                            ),
                            Text(
                              'Recommended size: 1200×600px (Max 2MB)',
                              style: TextStyle(
                                fontSize: 9,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: .45),
                              ),
                            ),
                          ],
                        )
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(9),
                          child: Image.memory(
                            image!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Message Body',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 7),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: colors.subtleBorder),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Column(
                  children: [
                    Container(
                      height: 36,
                      color: colors.tableHeader,
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: () {},
                            icon: const Icon(
                              Icons.format_bold_rounded,
                              size: 17,
                            ),
                          ),
                          IconButton(
                            onPressed: () {},
                            icon: const Icon(
                              Icons.format_italic_rounded,
                              size: 17,
                            ),
                          ),
                          IconButton(
                            onPressed: () {},
                            icon: const Icon(
                              Icons.format_list_bulleted_rounded,
                              size: 17,
                            ),
                          ),
                          IconButton(
                            onPressed: () {},
                            icon: const Icon(Icons.link_rounded, size: 17),
                          ),
                        ],
                      ),
                    ),
                    TextField(
                      controller: body,
                      minLines: 4,
                      maxLines: 6,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        fillColor: Colors.transparent,
                        filled: true,
                        contentPadding: EdgeInsets.all(12),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  SizedBox(
                    width: 22,
                    height: 22,
                    child: Checkbox(
                      value: notify,
                      onChanged: (value) =>
                          setState(() => notify = value ?? false),
                    ),
                  ),
                  const SizedBox(width: 5),
                  const Text(
                    'Send push notification to mobile app',
                    style: TextStyle(fontSize: 11),
                  ),
                  const Spacer(),
                  OutlinedButton(
                    onPressed: loading ? null : () => save(true),
                    child: const Text('Drafts', style: TextStyle(fontSize: 11)),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: loading ? null : () => save(false),
                    icon: loading
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send_rounded, size: 14),
                    label: const Text(
                      'Send Announcement',
                      style: TextStyle(fontSize: 11),
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
}
