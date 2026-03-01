import 'index_item.dart';

abstract class IndexRepository {
  Future<IndexEntry> createIndex(IndexEntry index);
  Future<IndexEntry> updateIndex(IndexEntry index);
  Future<void> updateItemStatus(String itemId, int status);
  Future<void> deleteIndex(String id);
  Future<IndexEntry?> getIndex(String id);
  Future<List<IndexEntry>> listIndexes({String? userId});
}
