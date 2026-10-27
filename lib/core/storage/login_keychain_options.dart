import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// macOS: the login keychain instead of the data protection keychain. The
/// latter needs a keychain-access-groups entitlement, which a Developer ID
/// app only gets with a provisioning profile; without it every call fails
/// with -34018. flutter_secure_storage_darwin 0.2.0 reads the switch as
/// `useDataProtectionKeyChain` while the Dart side sends
/// `usesDataProtectionKeychain`, so both spellings are sent.
class LoginKeychainMacOsOptions extends MacOsOptions {
  const LoginKeychainMacOsOptions() : super(usesDataProtectionKeychain: false);

  @override
  Map<String, String> toMap() => <String, String>{
    ...super.toMap(),
    'useDataProtectionKeyChain': 'false',
  };
}
