import 'package:flutter_test/flutter_test.dart';

import '../../tool/verify_release_signing.dart';

// Output formats copied from real runs (names replaced):
// `keytool -printcert -jarfile app.aab` (German JDK locale on purpose: the
// fingerprint line is the same in every locale) and
// `apksigner verify --print-certs app.apk`.
const _uploadSha256 =
    '55:A0:91:F4:90:94:54:39:C6:04:83:E7:D8:33:93:59:'
    'D6:6D:C3:DA:B9:F2:CC:60:9A:CF:5D:72:C3:32:F0:BF';

const _keytoolUploadSigned =
    '''
Signaturgeber #1:

Certificate #1:
Eigentümer: CN=Example, O=Sensor Widgets
Aussteller: CN=Example, O=Sensor Widgets
Zertifikatsfingerprints:
	 SHA1: 24:09:31:3E:96:93:03:3F:DC:34:26:F0:51:D7:44:42:0F:97:37:5C
	 SHA256: $_uploadSha256
Signaturalgorithmusname: SHA384withRSA
''';

const _apksignerDebugSigned = '''
Signer #1 certificate DN: C=US, O=Android, CN=Android Debug
Signer #1 certificate SHA-256 digest: 4a7c6417f654bd5c73cb60b27c6f3d314c99bd360432a0e3ff26b739bfbe7a3f
Signer #1 certificate SHA-1 digest: d36c0f2eea491cfcb5bd00d7edce16fc4cbd9fb3
''';

const _apksignerUploadSigned = '''
Signer #1 certificate DN: CN=Example, O=Sensor Widgets
Signer #1 certificate SHA-256 digest: 55a091f490945439c60483e7d8339359d66dc3dab9f2cc609acf5d72c332f0bf
''';

void main() {
  group('normalizeFingerprint', () {
    test('drops colons and whitespace and lowercases', () {
      expect(normalizeFingerprint(' 55:A0:91 '), '55a091');
    });
  });

  group('signerSha256s', () {
    test('reads the SHA256 line of keytool', () {
      expect(signerSha256s(_keytoolUploadSigned), {
        normalizeFingerprint(_uploadSha256),
      });
    });

    test('reads the SHA-256 digest line of apksigner', () {
      expect(signerSha256s(_apksignerDebugSigned), {
        '4a7c6417f654bd5c73cb60b27c6f3d314c99bd360432a0e3ff26b739bfbe7a3f',
      });
    });

    test('does not mistake the SHA1 line for SHA-256', () {
      expect(
        signerSha256s('\t SHA1: 24:09:31:3E:96:93:03:3F:DC:34:26:F0'),
        isEmpty,
      );
    });

    test('finds nothing in the output for an unsigned file', () {
      expect(signerSha256s('Not a signed jar file'), isEmpty);
    });
  });

  group('checkSigning', () {
    test('passes when the upload key signed the file', () {
      final result = checkSigning(_keytoolUploadSigned, _uploadSha256);
      expect(result.ok, isTrue);
    });

    test('passes for apksigner output of the upload key', () {
      final result = checkSigning(_apksignerUploadSigned, _uploadSha256);
      expect(result.ok, isTrue);
    });

    test('fails for a debug-signed file and names the found key', () {
      final result = checkSigning(_apksignerDebugSigned, _uploadSha256);
      expect(result.ok, isFalse);
      expect(result.message, contains('4a7c6417'));
    });

    test('fails for an unsigned file', () {
      final result = checkSigning('Not a signed jar file', _uploadSha256);
      expect(result.ok, isFalse);
      expect(result.message, contains('no signer'));
    });

    test('fails when the expected fingerprint is empty', () {
      final result = checkSigning(_keytoolUploadSigned, '  ');
      expect(result.ok, isFalse);
    });
  });
}
