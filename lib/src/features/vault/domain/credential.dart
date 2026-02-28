enum SsoProvider { none, google, github, facebook }

class Credential {
  final String id;
  final String account;
  final String password;
  final SsoProvider sso;

  Credential({
    required this.id,
    required this.account,
    required this.password,
    this.sso = SsoProvider.none,
  });
}
