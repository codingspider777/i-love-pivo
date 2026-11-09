import 'package:flutter/material.dart' show IconData, Icons;

class ImageRef {
  const ImageRef(this.asset, [this.caption]);

  final String asset;
  final String? caption;

  static ImageRef? tryParse(Object? raw) {
    if (raw is String) return ImageRef(raw);
    if (raw is Map<String, dynamic> && raw['asset'] is String) {
      return ImageRef(raw['asset'] as String, raw['caption'] as String?);
    }
    return null;
  }
}

enum InfoKind {
  hours(Icons.schedule, 'Часы работы'),
  phone(Icons.phone_outlined, 'Телефон'),
  email(Icons.mail_outline, 'Почта'),
  place(Icons.meeting_room_outlined, 'Расположение'),
  info(Icons.info_outline, 'Информация');

  const InfoKind(this.icon, this.label);
  final IconData icon;
  final String label;

  static InfoKind parse(String? v) => InfoKind.values.asNameMap()[v] ?? info;
}

sealed class ContentBlock {
  const ContentBlock();

  static ContentBlock? tryParse(Map<String, dynamic> j) {
    List<String> strings(Object? v) =>
        (v as List?)?.map((e) => e.toString()).toList() ?? const [];

    switch (j['type']) {
      case 'heading':
        return HeadingBlock(j['text'] as String? ?? '');
      case 'text':
        return TextBlock(j['text'] as String? ?? '');
      case 'bullets':
        return BulletsBlock(strings(j['items']));
      case 'chips':
        return ChipsBlock(strings(j['items']));
      case 'image':
        final img = ImageRef.tryParse(j);
        return img == null ? null : ImageBlock(img);
      case 'gallery':
        final imgs = [
          for (final raw in (j['images'] as List? ?? const []))
            if (ImageRef.tryParse(raw) case final img?) img,
        ];
        return imgs.isEmpty ? null : GalleryBlock(imgs);
      case 'info':
        final kind = InfoKind.parse(j['kind'] as String?);
        return InfoBlock(
          kind: kind,
          label: j['label'] as String? ?? kind.label,
          value: j['value'] as String? ?? '',
        );
      case 'link':
        final url = j['url'] as String?;
        if (url == null) return null;
        return LinkBlock(
          title: j['title'] as String? ?? url,
          url: url,
          subtitle: j['subtitle'] as String?,
        );
    }
    return null;
  }
}

class HeadingBlock extends ContentBlock {
  const HeadingBlock(this.text);
  final String text;
}

class TextBlock extends ContentBlock {
  const TextBlock(this.text);
  final String text;
}

class BulletsBlock extends ContentBlock {
  const BulletsBlock(this.items);
  final List<String> items;
}

class ChipsBlock extends ContentBlock {
  const ChipsBlock(this.items);
  final List<String> items;
}

class ImageBlock extends ContentBlock {
  const ImageBlock(this.image);
  final ImageRef image;
}

class GalleryBlock extends ContentBlock {
  const GalleryBlock(this.images);
  final List<ImageRef> images;
}

class InfoBlock extends ContentBlock {
  const InfoBlock({required this.kind, required this.label, required this.value});
  final InfoKind kind;
  final String label;
  final String value;
}

class LinkBlock extends ContentBlock {
  const LinkBlock({required this.title, required this.url, this.subtitle});
  final String title;
  final String url;
  final String? subtitle;
}