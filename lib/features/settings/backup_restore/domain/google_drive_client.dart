/// Application identity supplied by the developer when building Lotus ERP.
/// Account access and refresh tokens belong in platform secure storage.
class GoogleDriveClient {
  const GoogleDriveClient({required this.clientId, this.clientSecret = ''});

  const GoogleDriveClient.fromEnvironment()
      : clientId = const String.fromEnvironment('LOTUS_GOOGLE_CLIENT_ID'),
        clientSecret =
            const String.fromEnvironment('LOTUS_GOOGLE_CLIENT_SECRET');

  final String clientId;
  final String clientSecret;

  bool get configured =>
      RegExp(r'^[A-Za-z0-9_-]+\.apps\.googleusercontent\.com$')
          .hasMatch(clientId);
}
