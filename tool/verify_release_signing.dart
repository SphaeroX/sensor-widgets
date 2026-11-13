// Checks that a release AAB or APK is signed with the Google Play upload key.
//
//   dart run tool/verify_release_signing.dart <file.aab|file.apk> <sha256-file>
//
// <sha256-file> holds the upload certificate's SHA-256 fingerprint (public,
// see android/upload-cert.sha256). AABs are read with `keytool`, APKs with
// `apksigner` (APKs for minSdk 26 have no JAR signature, so keytool cannot
// read them). apksigner is taken from $APKSIGNER or the newest build-tools in
// $ANDROID_HOME / $ANDROID_SDK_ROOT. Exit code 0 = signed with the upload key.
import 'dart:io';

/// Lowercase hex without colons or whitespace.
String normalizeFingerprint(String fingerprint) =>
    fingerprint.replaceAll(RegExp(r'[\s:]'), '').toLowerCase();

final _keytoolSha256 = RegExp(r'^\s*SHA-?256:\s*([0-9A-Fa-f:]+)\s*$');
final _apksignerSha256 = RegExp(
  r'^Signer #\d+ certificate SHA-256 digest:\s*([0-9a-fA-F]+)\s*$',
);

/// SHA-256 fingerprints of all signer certificates in keytool or apksigner
/// output, normalized.
Set<String> signerSha256s(String toolOutput) {
  final found = <String>{};
  for (final line in toolOutput.split(RegExp(r'\r?\n'))) {
    final match =
        _keytoolSha256.firstMatch(line) ?? _apksignerSha256.firstMatch(line);
    if (match != null) found.add(normalizeFingerprint(match.group(1)!));
  }
  return found;
}

class SigningCheck {
  const SigningCheck(this.ok, this.message);

  final bool ok;
  final String message;
}

SigningCheck checkSigning(String toolOutput, String expectedSha256) {
  final expected = normalizeFingerprint(expectedSha256);
  if (expected.isEmpty) {
    return const SigningCheck(false, 'expected fingerprint is empty');
  }
  final found = signerSha256s(toolOutput);
  if (found.isEmpty) {
    return SigningCheck(
      false,
      'no signer certificate found (unsigned, or the tool failed). '
      'Tool output:\n${toolOutput.trim()}',
    );
  }
  if (found.contains(expected)) {
    return const SigningCheck(true, 'signed with the upload key');
  }
  return SigningCheck(
    false,
    'signed with a different key: ${found.join(', ')} '
    '(expected $expected; a debug key means android/key.properties was '
    'missing during the build)',
  );
}

String _apksignerPath() {
  final explicit = Platform.environment['APKSIGNER'];
  if (explicit != null && explicit.isNotEmpty) return explicit;
  final sdk =
      Platform.environment['ANDROID_HOME'] ??
      Platform.environment['ANDROID_SDK_ROOT'];
  if (sdk == null) {
    throw StateError('set APKSIGNER or ANDROID_HOME to find apksigner');
  }
  final versions =
      Directory('$sdk/build-tools').listSync().whereType<Directory>().toList()
        ..sort((a, b) => _compareVersions(a.path, b.path));
  final name = Platform.isWindows ? 'apksigner.bat' : 'apksigner';
  return '${versions.last.path}/$name';
}

int _compareVersions(String a, String b) {
  List<int> parts(String path) => path
      .split(RegExp(r'[\\/]'))
      .last
      .split(RegExp(r'[.-]'))
      .map((p) => int.tryParse(p) ?? 0)
      .toList();
  final pa = parts(a);
  final pb = parts(b);
  for (var i = 0; i < pa.length && i < pb.length; i++) {
    if (pa[i] != pb[i]) return pa[i].compareTo(pb[i]);
  }
  return pa.length.compareTo(pb.length);
}

Future<void> main(List<String> args) async {
  if (args.length != 2) {
    stderr.writeln(
      'usage: dart run tool/verify_release_signing.dart '
      '<file.aab|file.apk> <sha256-file>',
    );
    exit(64);
  }
  final artifact = args[0];
  final expected = File(args[1]).readAsStringSync();
  final result = artifact.toLowerCase().endsWith('.apk')
      ? await Process.run(_apksignerPath(), [
          'verify',
          '--print-certs',
          artifact,
        ], runInShell: Platform.isWindows)
      : await Process.run('keytool', [
          '-J-Duser.language=en',
          '-printcert',
          '-jarfile',
          artifact,
        ], runInShell: Platform.isWindows);
  final check = checkSigning('${result.stdout}\n${result.stderr}', expected);
  (check.ok ? stdout : stderr).writeln('$artifact: ${check.message}');
  exit(check.ok ? 0 : 1);
}
