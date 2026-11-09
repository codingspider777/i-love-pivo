import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:salamanca/features/map/models/building_content.dart';
import 'package:salamanca/features/map/models/map_building.dart';
import 'package:url_launcher/url_launcher.dart';

IconData categoryIcon(BuildingCategory c) => switch (c) {
      BuildingCategory.academic => Icons.school,
      BuildingCategory.dorm => Icons.bed,
      BuildingCategory.sport => Icons.fitness_center,
      BuildingCategory.food => Icons.restaurant,
      BuildingCategory.service => Icons.place,
    };

class BuildingSheet extends StatelessWidget {
  const BuildingSheet({
    super.key,
    required this.building,
    required this.controller,
    required this.onClose,
  });

  final MapBuilding building;
  final ScrollController controller;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final b = building;

    final blocks = <ContentBlock>[
      if (b.description.isNotEmpty) TextBlock(b.description),
      ...b.content,
    ];

    return Material(
      color: scheme.surface,
      elevation: 12,
      shadowColor: Colors.black54,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      clipBehavior: Clip.antiAlias,
      child: ListView(
        controller: controller,
        padding: EdgeInsets.zero,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              decoration: BoxDecoration(
                color: scheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 8, 0),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: scheme.primary.withValues(alpha: 0.12),
                  child: Icon(categoryIcon(b.category), color: scheme.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(b.name, style: theme.textTheme.titleLarge),
                      Text(
                        b.category.label,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Закрыть',
                  icon: const Icon(Icons.close),
                  onPressed: onClose,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (b.address.isNotEmpty)
                  _BlockFrame(
                    child: InfoTile(
                      block: InfoBlock(
                        kind: InfoKind.place,
                        label: 'Адрес',
                        value: b.address,
                      ),
                    ),
                  ),
                if (blocks.isEmpty)
                  Text(
                    'Описание пока не добавлено',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                for (final block in blocks)
                  _BlockFrame(child: _BlockView(block: block)),
                SizedBox(height: 16 + MediaQuery.of(context).padding.bottom),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BlockFrame extends StatelessWidget {
  const _BlockFrame({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) =>
      Padding(padding: const EdgeInsets.only(bottom: 14), child: child);
}

class _BlockView extends StatelessWidget {
  const _BlockView({required this.block});
  final ContentBlock block;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final muted =
        theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant);

    return switch (block) {
      HeadingBlock(:final text) => Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(text, style: theme.textTheme.titleMedium),
        ),
      TextBlock(:final text) => Text(text, style: muted),
      BulletsBlock(:final items) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final item in items)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 7, right: 10),
                      child: Icon(Icons.circle,
                          size: 6, color: scheme.onSurfaceVariant),
                    ),
                    Expanded(child: Text(item, style: muted)),
                  ],
                ),
              ),
          ],
        ),
      ChipsBlock(:final items) => Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [for (final i in items) Chip(label: Text(i))],
        ),
      ImageBlock(:final image) => _ImageCard(
          image: image,
          onTap: () => showImageViewer(context, [image], 0),
        ),
      GalleryBlock(:final images) => SizedBox(
          height: 170,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: images.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, i) => SizedBox(
              width: 240,
              child: _ImageCard(
                image: images[i],
                onTap: () => showImageViewer(context, images, i),
              ),
            ),
          ),
        ),
      InfoBlock() => InfoTile(block: block as InfoBlock),
      LinkBlock() => _LinkTile(block: block as LinkBlock),
    };
  }
}

class _ImageCard extends StatelessWidget {
  const _ImageCard({required this.image, required this.onTap});

  final ImageRef image;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final caption = image.caption;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: GestureDetector(
            onTap: onTap,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: AssetPhoto(asset: image.asset, fit: BoxFit.cover),
              ),
            ),
          ),
        ),
        if (caption != null && caption.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              caption,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
      ],
    );
  }
}

class AssetPhoto extends StatelessWidget {
  const AssetPhoto({super.key, required this.asset, this.fit = BoxFit.cover});

  final String asset;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Image.asset(
      asset,
      fit: fit,
      errorBuilder: (_, _, _) => ColoredBox(
        color: scheme.surfaceContainerHighest,
        child: Center(
          child: Icon(Icons.broken_image_outlined,
              color: scheme.onSurfaceVariant),
        ),
      ),
    );
  }
}

class InfoTile extends StatelessWidget {
  const InfoTile({super.key, required this.block});
  final InfoBlock block;

  Future<void> _act(BuildContext context) async {
    final value = block.value;
    switch (block.kind) {
      case InfoKind.phone:
        await _launch(context, Uri(scheme: 'tel', path: value.replaceAll(' ', '')));
      case InfoKind.email:
        await _launch(context, Uri(scheme: 'mailto', path: value));
      default:
        await Clipboard.setData(ClipboardData(text: value));
        if (context.mounted) _toast(context, 'Скопировано');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => _act(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(block.kind.icon, size: 20, color: scheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    block.label,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                  Text(block.value, style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LinkTile extends StatelessWidget {
  const _LinkTile({required this.block});
  final LinkBlock block;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Card(
      child: ListTile(
        leading: Icon(Icons.link, color: scheme.primary),
        title: Text(block.title),
        subtitle: block.subtitle == null ? null : Text(block.subtitle!),
        trailing: const Icon(Icons.open_in_new, size: 18),
        onTap: () {
          final uri = Uri.tryParse(block.url);
          if (uri != null) _launch(context, uri);
        },
      ),
    );
  }
}

Future<void> _launch(BuildContext context, Uri uri) async {
  try {
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) _toast(context, 'Не удалось открыть');
  } catch (_) {
    if (context.mounted) _toast(context, 'Не удалось открыть');
  }
}

void _toast(BuildContext context, String text) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text)));
}

void showImageViewer(BuildContext context, List<ImageRef> images, int index) {
  showDialog<void>(
    context: context,
    builder: (_) => _ImageViewer(images: images, initialIndex: index),
  );
}

class _ImageViewer extends StatefulWidget {
  const _ImageViewer({required this.images, required this.initialIndex});

  final List<ImageRef> images;
  final int initialIndex;

  @override
  State<_ImageViewer> createState() => _ImageViewerState();
}

class _ImageViewerState extends State<_ImageViewer> {
  late final PageController _pages =
      PageController(initialPage: widget.initialIndex);
  late int _index = widget.initialIndex;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final images = widget.images;
    final caption = images[_index].caption;
    return Dialog.fullscreen(
      backgroundColor: Colors.black,
      child: Stack(
        children: [
          PageView.builder(
            controller: _pages,
            itemCount: images.length,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (_, i) => InteractiveViewer(
              maxScale: 5,
              child: Center(
                child: AssetPhoto(asset: images[i].asset, fit: BoxFit.contain),
              ),
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: IconButton(
                color: Colors.white,
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),
          if ((caption != null && caption.isNotEmpty) || images.length > 1)
            SafeArea(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    [
                      if (caption != null && caption.isNotEmpty) caption,
                      if (images.length > 1) '${_index + 1} / ${images.length}',
                    ].join('  •  '),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}