import 'account.dart';

abstract class AccountRepository {
  Future<Account> createAccount(Account account);
  Future<List<Account>> listAccounts({String? userId});
}
