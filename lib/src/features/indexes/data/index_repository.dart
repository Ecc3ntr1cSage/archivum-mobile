import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/errors/app_error.dart';
import '../domain/index_item.dart';
import '../domain/index_repository.dart';

class SupabaseIndexRepository implements IndexRepository {
  final SupabaseClient client;
  SupabaseIndexRepository(this.client);

  String _requireUserId() {
    final userId = client.auth.currentUser?.id;
    if (userId == null) {
      throw AppError.auth('You must be signed in to manage indexes.');
    }
    return userId;
  }

  String _scopedUserId(String? requestedUserId) {
    final userId = _requireUserId();
    if (requestedUserId != null && requestedUserId != userId) {
      throw AppError.permission('You cannot access another user’s indexes.');
    }
    return userId;
  }

  @override
  Future<IndexEntry> createIndex(IndexEntry index) async {
    final userId = _requireUserId();
    final response = await client
        .from('indexes')
        .insert({'title': index.title, 'user_id': userId})
        .select()
        .single();

    final indexId = response['id'] as int;

    // Insert items if any
    if (index.items.isNotEmpty) {
      final itemsPayload = index.items
          .map((item) => {'index_id': indexId, 'item': item.item})
          .toList();

      await client.from('index_items').insert(itemsPayload);
      await client.from('activity_logs').insert({
        'activity_type': 'index_item_created',
      });
    }

    // Fetch the full index with items
    final result = await getIndex(indexId.toString());
    await client.from('activity_logs').insert({
      'activity_type': 'index_created',
    });
    return result!;
  }

  @override
  Future<IndexEntry> updateIndex(IndexEntry index) async {
    if (index.id == null) {
      throw AppError.validation('Index ID is required for update.');
    }
    final userId = _requireUserId();
    // Update the index title
    final updated = await client
        .from('indexes')
        .update({'title': index.title})
        .eq('id', index.id!)
        .eq('user_id', userId)
        .select('id')
        .maybeSingle();
    if (updated == null) {
      throw AppError.notFound('Index was not found.');
    }

    // Get existing item IDs
    final existingItems = await client
        .from('index_items')
        .select('id')
        .eq('index_id', index.id!);
    final existingIds = (existingItems as List)
        .map((e) => e['id'].toString())
        .toSet();

    // IDs of items the user kept (existing items still present)
    final keptIds = index.items
        .where((i) => i.id != null)
        .map((i) => i.id!)
        .toSet();

    // Delete removed items
    final toDelete = existingIds.difference(keptIds);
    if (toDelete.isNotEmpty) {
      for (final id in toDelete) {
        await client.from('index_items').delete().eq('id', id);
      }
      await client.from('activity_logs').insert({
        'activity_type': 'index_item_deleted',
      });
    }

    // Update existing items
    for (final item in index.items.where((i) => i.id != null)) {
      await client
          .from('index_items')
          .update({'item': item.item})
          .eq('id', item.id!);
    }

    // Insert new items
    final newItems = index.items.where((i) => i.id == null).toList();
    if (newItems.isNotEmpty) {
      final indexIdInt = int.parse(index.id!);
      await client
          .from('index_items')
          .insert(
            newItems
                .map((item) => {'index_id': indexIdInt, 'item': item.item})
                .toList(),
          );
      await client.from('activity_logs').insert({
        'activity_type': 'index_item_created',
      });
    }

    final result = await getIndex(index.id!);
    await client.from('activity_logs').insert({
      'activity_type': 'index_updated',
    });
    return result!;
  }

  @override
  Future<void> deleteIndex(String id) async {
    final userId = _requireUserId();
    // Items will be cascade-deleted via FK constraint
    await client.from('indexes').delete().eq('id', id).eq('user_id', userId);
    await client.from('activity_logs').insert({
      'activity_type': 'index_deleted',
    });
  }

  @override
  Future<IndexEntry?> getIndex(String id) async {
    final userId = _requireUserId();
    final response = await client
        .from('indexes')
        .select()
        .eq('id', id)
        .eq('user_id', userId)
        .maybeSingle();
    if (response == null) return null;

    final itemsResponse = await client
        .from('index_items')
        .select()
        .eq('index_id', id)
        .order('created_at', ascending: true);

    return _mapToIndexEntry(response, itemsResponse as List);
  }

  @override
  Future<List<IndexEntry>> listIndexes({String? userId}) async {
    final scopedUserId = _scopedUserId(userId);
    var query = client.from('indexes').select().eq('user_id', scopedUserId);
    final response = await query.order('created_at', ascending: false);

    final List<IndexEntry> indexes = [];
    for (final row in response as List) {
      final itemsResponse = await client
          .from('index_items')
          .select()
          .eq('index_id', row['id'])
          .order('created_at', ascending: true);
      indexes.add(_mapToIndexEntry(row, itemsResponse as List));
    }
    return indexes;
  }

  IndexEntry _mapToIndexEntry(Map<String, dynamic> row, List items) {
    return IndexEntry(
      id: row['id']?.toString(),
      userId: row['user_id']?.toString(),
      title: row['title'] ?? '',
      items: items
          .map(
            (item) => IndexItem(
              id: item['id']?.toString(),
              indexId: item['index_id']?.toString(),
              item: item['item'] ?? '',
              createdAt: item['created_at'] != null
                  ? DateTime.parse(item['created_at'])
                  : null,
            ),
          )
          .toList(),
      createdAt: row['created_at'] != null
          ? DateTime.parse(row['created_at'])
          : null,
    );
  }
}
