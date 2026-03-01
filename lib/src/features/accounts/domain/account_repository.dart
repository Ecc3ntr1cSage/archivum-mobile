import 'account.dart';

abstract class AccountRepository {
  Future<Account> createAccount(Account account);
  Future<List<Account>> listAccounts({String? userId});
  Future<Account> updateAccount(Account account);
  Future<void> deleteAccount(String id);
  Future<List<String>> getTags(String feature);
  Future<void> addTag(String text, String feature);
}
