import 'dart:io';

class PythonEnvironmentService {
  static const String minPythonVersion = '3.8.0';

  Future<bool> isPythonInstalled() async {
    try {
      if (Platform.isWindows) {
        var result = await Process.run('python', ['--version']);
        return result.exitCode == 0 && _isValidVersion(result.stdout.toString());
      } else {
        var result = await Process.run('python3', ['--version']);
        return result.exitCode == 0 && _isValidVersion(result.stdout.toString());
      }
    } catch (e) {
      return false;
    }
  }

  Future<bool> verifyPip() async {
    try {
      final result = await Process.run(
        Platform.isWindows ? 'pip' : 'pip3',
        ['--version'],
      );
      return result.exitCode == 0;
    } catch (e) {
      return false;
    }
  }

  bool _isValidVersion(String versionOutput) {
    // Python version output format: "Python 3.8.0"
    final match = RegExp(r'Python (\d+)\.(\d+)\.(\d+)').firstMatch(versionOutput);
    if (match == null) return false;

    final major = int.parse(match.group(1)!);
    final minor = int.parse(match.group(2)!);
    
    // Check if version is >= 3.8
    // Accept only Python 3.8.x, 3.9.x, 3.10.x, or 3.11.x
    return major == 3 && (minor == 8 || minor == 9 || minor == 10 || minor == 11);
  }

  Future<bool> installPackage(String package, {String? version}) async {
    try {
      final args = [
        '-m', 'pip', 'install', '--user',
        if (version != null) '$package==$version' else package
      ];

      final result = await Process.run(
        Platform.isWindows ? 'python' : 'python3',
        args,
      );
      return result.exitCode == 0;
    } catch (e) {
      print('Failed to install package $package: $e');
      return false;
    }
  }

  Future<bool> verifyPackage(String package) async {
    try {
      final result = await Process.run(
        Platform.isWindows ? 'python' : 'python3',
        ['-m', 'pip', 'show', package],
      );
      return result.exitCode == 0;
    } catch (e) {
      return false;
    }
  }

  Future<String?> getPythonPath() async {
    try {
      if (Platform.isWindows) {
        final result = await Process.run('where', ['python']);
        return result.exitCode == 0 ? result.stdout.toString().trim() : null;
      } else {
        final result = await Process.run('which', ['python3']);
        return result.exitCode == 0 ? result.stdout.toString().trim() : null;
      }
    } catch (e) {
      return null;
    }
  }
}