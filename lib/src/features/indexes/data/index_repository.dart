import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/index_item.dart';
import '../domain/index_repository.dart';

class SupabaseIndexRepository implements IndexRepository {
  final SupabaseClient client;
  SupabaseIndexRepository(this.client);

  @override
  Future<IndexEntry> createIndex(IndexEntry index) async {
    // user_id defaults to auth.uid() in DB, so we don't send it
    final response = await client
        .from('indexes')
        .insert({'title': index.title})
        .select()
        .single();

    final indexId = response['id'] as int;

    // Insert items if any
    if (index.items.isNotEmpty) {
      final itemsPayload = index.items.map((item) => {
        'index_id': indexId,
        'item': item.item,
        if (item.status != null) 'status': item.status,
      }).toList();

      await client.from('index_items').insert(itemsPayload);
    }

    // Fetch the full index with items
    return (await getIndex(indexId.toString()))!;
  }

  @override
  Future<IndexEntry> updateIndex(IndexEntry index) async {
    // Update the index title
    await client
        .from('indexes')
        .update({'title': index.title})
        .eq('id', index.id!);

    // Get existing item IDs
    final existingItems = await client
        .from('index_items')
        .select('id')
        .eq('index_id', index.id!);
    final existingIds =
        (existingItems as List).map((e) => e['id'].toString()).toSet();

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
    }

    // Update existing items
    for (final item in index.items.where((i) => i.id != null)) {
      await client.from('index_items').update({
        'item': item.item,
        'status': item.status ?? 0,
      }).eq('id', item.id!);
    }

    // Insert new items
    final newItems = index.items.where((i) => i.id == null).toList();
    if (newItems.isNotEmpty) {
      final indexIdInt = int.parse(index.id!);
      await client.from('index_items').insert(
        newItems.map((item) => {
          'index_id': indexIdInt,
          'item': item.item,
          if (item.status != null) 'status': item.status,
        }).toList(),
      );
    }

    return (await getIndex(index.id!))!;
  }

  @override
  Future<void> updateItemStatus(String itemId, int status) async {
    await client
        .from('index_items')
        .update({'status': status})
        .eq('id', itemId);
  }

  @override
  Future<void> deleteIndex(String id) async {
    // Items will be cascade-deleted via FK constraint
    await client.from('indexes').delete().eq('id', id);
  }

  @override
  Future<IndexEntry?> getIndex(String id) async {
    final response = await client
        .from('indexes')
        .select()
        .eq('id', id)
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
    var query = client.from('indexes').select();
    if (userId != null) {
      query = query.eq('user_id', userId);
    }
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
      items: items.map((item) => IndexItem(
        id: item['id']?.toString(),
        indexId: item['index_id']?.toString(),
        item: item['item'] ?? '',
        status: item['status'] as int?,
        createdAt: item['created_at'] != null
            ? DateTime.parse(item['created_at'])
            : null,
      )).toList(),
      createdAt: row['created_at'] != null
          ? DateTime.parse(row['created_at'])
          : null,
    );
  }
}
