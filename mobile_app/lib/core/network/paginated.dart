import 'package:flutter/foundation.dart';

/// One page of a list endpoint (backend roadmap phase 4: pagination).
///
/// Expected JSON:
/// ```json
/// { "items": [ ... ], "page": 1, "page_size": 20, "total": 48 }
/// ```
@immutable
class Paginated<T> {
  const Paginated({
    required this.items,
    required this.page,
    required this.pageSize,
    this.total,
  });

  final List<T> items;
  final int page;
  final int pageSize;

  /// Total items across all pages, when the backend reports it.
  final int? total;

  bool get hasMore =>
      total == null ? items.length == pageSize : page * pageSize < total!;

  factory Paginated.fromJson(
    Map<String, Object?> json,
    T Function(Map<String, Object?>) item,
  ) => Paginated(
    items: [
      for (final e in (json['items'] as List? ?? const []))
        item(e as Map<String, Object?>),
    ],
    page: (json['page'] as num?)?.toInt() ?? 1,
    pageSize: (json['page_size'] as num?)?.toInt() ?? 20,
    total: (json['total'] as num?)?.toInt(),
  );
}
