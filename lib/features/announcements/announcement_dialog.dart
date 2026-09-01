import 'dart:typed_data';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/widgets/admin_widgets.dart';
import '../../data/repositories/mock_repository.dart';
import '../../models/app_models.dart';

const _maxFeatureImageBytes = 2 * 1024 * 1024;

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
    final bytes = result?.files.single.bytes;
    if (!mounted || bytes == null) return;
    if (bytes.lengthInBytes > _maxFeatureImageBytes) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Feature images must be 2 MB or smaller.')),
      );
      return;
    }
    setState(() => image = bytes);
  }

  Future<void> editImage() async {
    final bytes = image;
    if (bytes == null) return;
    final cropped = await _showImageCropper(bytes);
    if (mounted && cropped != null) setState(() => image = cropped);
  }

  Future<Uint8List?> _showImageCropper(Uint8List bytes) {
    return showDialog<Uint8List>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AnnouncementImageCropDialog(bytes: bytes),
    );
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
                onTap: image == null ? pick : editImage,
                child: Container(
                  width: double.infinity,
                  height: 94,
                  decoration: BoxDecoration(
                    color: colors.infoContainer.withValues(alpha: .48),
                    border:
                        Border.all(color: colors.info.withValues(alpha: .35)),
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
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.memory(image!, fit: BoxFit.cover),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: Material(
                                  color: Colors.black.withValues(alpha: .62),
                                  shape: const CircleBorder(),
                                  child: IconButton(
                                    onPressed: () =>
                                        setState(() => image = null),
                                    tooltip: 'Remove feature image',
                                    icon: const Icon(Icons.close_rounded),
                                    iconSize: 18,
                                    color: Colors.white,
                                    constraints: const BoxConstraints(
                                      minWidth: 32,
                                      minHeight: 32,
                                    ),
                                    padding: EdgeInsets.zero,
                                  ),
                                ),
                              ),
                              Positioned(
                                right: 8,
                                bottom: 6,
                                child: Material(
                                  color: Colors.black.withValues(alpha: .62),
                                  borderRadius: BorderRadius.circular(5),
                                  child: InkWell(
                                    onTap: editImage,
                                    borderRadius: BorderRadius.circular(5),
                                    child: const Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 5,
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.crop_rounded,
                                            color: Colors.white,
                                            size: 14,
                                          ),
                                          SizedBox(width: 4),
                                          Text(
                                            'Edit/Crop Image',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
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

class AnnouncementImageCropDialog extends StatefulWidget {
  const AnnouncementImageCropDialog({super.key, required this.bytes});

  final Uint8List bytes;

  @override
  State<AnnouncementImageCropDialog> createState() =>
      _AnnouncementImageCropDialogState();
}

class _AnnouncementImageCropDialogState
    extends State<AnnouncementImageCropDialog> {
  late final Future<ui.Image> _decodedImage = _decodeImage(widget.bytes);
  double _zoom = 1;
  double _cropSize = .82;
  Offset _offset = Offset.zero;
  Size? _viewport;

  static Future<ui.Image> _decodeImage(Uint8List bytes) async {
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    codec.dispose();
    return frame.image;
  }

  Rect _cropRect(Size viewport) {
    final width = viewport.width * _cropSize;
    return Rect.fromCenter(
      center: Offset(viewport.width / 2, viewport.height / 2),
      width: width,
      height: width * 9 / 16,
    );
  }

  Size _displaySize(ui.Image source, Size viewport) {
    final cropRect = _cropRect(viewport);
    final baseScale = math
        .max(
          cropRect.width / source.width,
          cropRect.height / source.height,
        )
        .toDouble();
    final scale = baseScale * _zoom;
    return Size(source.width * scale, source.height * scale);
  }

  Offset _clampedOffset(ui.Image source, Size viewport) {
    final displaySize = _displaySize(source, viewport);
    final cropRect = _cropRect(viewport);
    final maxX = math.max(0, (displaySize.width - cropRect.width) / 2);
    final maxY = math.max(0, (displaySize.height - cropRect.height) / 2);
    return Offset(
      _offset.dx.clamp(-maxX, maxX).toDouble(),
      _offset.dy.clamp(-maxY, maxY).toDouble(),
    );
  }

  Future<void> _confirmCrop(ui.Image source, Size viewport) async {
    final cropRect = _cropRect(viewport);
    final displaySize = _displaySize(source, viewport);
    final scale = displaySize.width / source.width;
    final offset = _clampedOffset(source, viewport);
    final imageTopLeft = Offset(
      (viewport.width - displaySize.width) / 2 + offset.dx,
      (viewport.height - displaySize.height) / 2 + offset.dy,
    );
    final sourceWidth =
        (cropRect.width / scale).clamp(1.0, source.width.toDouble()).toDouble();
    final sourceHeight = (cropRect.height / scale)
        .clamp(1.0, source.height.toDouble())
        .toDouble();
    final sourceLeft = ((cropRect.left - imageTopLeft.dx) / scale)
        .clamp(0.0, source.width.toDouble() - sourceWidth)
        .toDouble();
    final sourceTop = ((cropRect.top - imageTopLeft.dy) / scale)
        .clamp(0.0, source.height.toDouble() - sourceHeight)
        .toDouble();
    final sourceRect = Rect.fromLTWH(
      sourceLeft,
      sourceTop,
      sourceWidth,
      sourceHeight,
    );
    final outputWidth =
        math.min(1200, sourceWidth.round()).clamp(1, 1200).toInt();
    final outputHeight = math.max(1, (outputWidth * 9 / 16).round()).toInt();
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawImageRect(
      source,
      sourceRect,
      Rect.fromLTWH(0, 0, outputWidth.toDouble(), outputHeight.toDouble()),
      Paint()..filterQuality = FilterQuality.high,
    );
    final picture = recorder.endRecording();
    final cropped = await picture.toImage(outputWidth, outputHeight);
    final data = await cropped.toByteData(format: ui.ImageByteFormat.png);
    picture.dispose();
    cropped.dispose();
    if (!mounted || data == null) return;
    if (data.lengthInBytes > _maxFeatureImageBytes) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'The cropped image is over 2 MB. Reduce the crop area and try again.',
          ),
        ),
      );
      return;
    }
    Navigator.of(context).pop(Uint8List.fromList(data.buffer.asUint8List()));
  }

  @override
  Widget build(BuildContext context) {
    final colors = semanticColors(context);
    final contentWidth = math
        .min(
          560.0,
          math.max(200.0, MediaQuery.sizeOf(context).width - 128.0),
        )
        .toDouble();
    return AlertDialog(
      title: const Text('Crop Feature Image'),
      content: SizedBox(
        width: contentWidth,
        child: FutureBuilder<ui.Image>(
          future: _decodedImage,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Text('This image format is not supported.');
            }
            if (!snapshot.hasData) {
              return const SizedBox(
                height: 300,
                child: Center(child: CircularProgressIndicator()),
              );
            }

            final source = snapshot.data!;
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Drag to reposition the image. Adjust the crop area and zoom below.',
                    style: TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final viewport = Size(
                          constraints.maxWidth,
                          constraints.maxHeight,
                        );
                        if (_viewport != viewport) {
                          _viewport = viewport;
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted && _viewport == viewport)
                              setState(() {});
                          });
                        }
                        final cropRect = _cropRect(viewport);
                        final displaySize = _displaySize(source, viewport);
                        final offset = _clampedOffset(source, viewport);
                        return DecoratedBox(
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: colors.accent, width: 2),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onPanUpdate: (details) => setState(() {
                                _offset += details.delta;
                              }),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  Transform.translate(
                                    offset: offset,
                                    child: Center(
                                      child: SizedBox(
                                        width: displaySize.width,
                                        height: displaySize.height,
                                        child: RawImage(
                                          image: source,
                                          fit: BoxFit.fill,
                                          filterQuality: FilterQuality.high,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Positioned.fill(
                                    child: IgnorePointer(
                                      child: CustomPaint(
                                        painter: _CropOverlayPainter(
                                          cropRect: cropRect,
                                          scrimColor: Colors.black.withValues(
                                            alpha: .58,
                                          ),
                                          frameColor: colors.accent,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.crop_rounded, size: 17),
                      const SizedBox(width: 6),
                      const Text(
                        'Crop area',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '16:9  •  ${(_cropSize * 100).round()}%',
                        style: TextStyle(
                          color: colors.secondaryText,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: _cropSize,
                    min: .55,
                    max: 1,
                    divisions: 9,
                    label: '${(_cropSize * 100).round()}%',
                    onChanged: (value) => setState(() => _cropSize = value),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.zoom_out_rounded, size: 17),
                      Expanded(
                        child: Slider(
                          value: _zoom,
                          min: 1,
                          max: 3,
                          divisions: 20,
                          label: '${(_zoom * 100).round()}%',
                          onChanged: (value) => setState(() => _zoom = value),
                        ),
                      ),
                      const Icon(Icons.zoom_in_rounded, size: 17),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FutureBuilder<ui.Image>(
          future: _decodedImage,
          builder: (context, snapshot) => FilledButton(
            onPressed: snapshot.hasData && _viewport != null
                ? () => _confirmCrop(snapshot.data!, _viewport!)
                : null,
            child: const Text('Apply Crop'),
          ),
        ),
      ],
    );
  }
}

class _CropOverlayPainter extends CustomPainter {
  const _CropOverlayPainter({
    required this.cropRect,
    required this.scrimColor,
    required this.frameColor,
  });

  final Rect cropRect;
  final Color scrimColor;
  final Color frameColor;

  @override
  void paint(Canvas canvas, Size size) {
    final scrimPath = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size)
      ..addRect(cropRect);
    canvas.drawPath(scrimPath, Paint()..color = scrimColor);

    final framePaint = Paint()
      ..color = frameColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRect(cropRect, framePaint);

    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: .72)
      ..strokeWidth = 1;
    final thirdWidth = cropRect.width / 3;
    final thirdHeight = cropRect.height / 3;
    for (var i = 1; i < 3; i++) {
      final x = cropRect.left + thirdWidth * i;
      final y = cropRect.top + thirdHeight * i;
      canvas.drawLine(
        Offset(x, cropRect.top),
        Offset(x, cropRect.bottom),
        gridPaint,
      );
      canvas.drawLine(
        Offset(cropRect.left, y),
        Offset(cropRect.right, y),
        gridPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CropOverlayPainter oldDelegate) =>
      oldDelegate.cropRect != cropRect ||
      oldDelegate.scrimColor != scrimColor ||
      oldDelegate.frameColor != frameColor;
}
