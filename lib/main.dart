import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const MonoLauncherApp());
}

class MonoLauncherApp extends StatelessWidget {
  const MonoLauncherApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
      title: 'Mono Launcher',
      theme: const CupertinoThemeData(brightness: Brightness.light, primaryColor: CupertinoColors.systemBlue),
      home: const LauncherHomePage(),
    );
  }
}

class LauncherHomePage extends StatefulWidget {
  const LauncherHomePage({Key? key}) : super(key: key);

  @override
  _LauncherHomePageState createState() => _LauncherHomePageState();
}

class _LauncherHomePageState extends State<LauncherHomePage> {
  List<Map<String, dynamic>> _apps = [];
  bool _isLoading = true;
  static const MethodChannel _channel = MethodChannel('com.example.mono_launcher/apps');

  @override
  void initState() {
    super.initState();
    _loadApps();
  }

  Future<void> _loadApps() async {
    try {
      final List<dynamic> apps = await _channel.invokeMethod('getInstalledApps');
      setState(() {
        _apps = apps.map((app) {
          final Map<dynamic, dynamic> castedApp = app as Map<dynamic, dynamic>;
          return {
            'name': castedApp['name'] as String,
            'packageName': castedApp['packageName'] as String,
            'icon': castedApp['icon'] as Uint8List?,
          };
        }).toList();
        _isLoading = false;
      });
    } on PlatformException catch (e) {
      print("Failed to get apps: '${e.message}'.");
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _openApp(String packageName) async {
    try {
      await _channel.invokeMethod('openApp', {'packageName': packageName});
    } on PlatformException catch (e) {
      print("Failed to open app: '${e.message}'.");

      // Показываем iOS-style диалог об ошибке
      showCupertinoDialog(
        context: context,
        builder: (BuildContext context) => CupertinoAlertDialog(
          title: const Text('Cannot Open App'),
          content: Text('Failed to open app: ${e.message}'),
          actions: [CupertinoDialogAction(child: const Text('OK'), onPressed: () => Navigator.of(context).pop())],
        ),
      );
    }
  }

  Future<bool> _onWillPop() async {
    bool? exitConfirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (BuildContext context) => CupertinoAlertDialog(
        title: const Text('Exit Launcher'),
        content: const Text('Are you sure you want to exit the launcher?'),
        actions: [
          CupertinoDialogAction(child: const Text('Cancel'), onPressed: () => Navigator.of(context).pop(false)),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('Exit'),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );

    return exitConfirmed ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: CupertinoPageScaffold(
        child: SafeArea(
          top: false,
          bottom: false,
          child: _isLoading
              ? const Center(child: CupertinoActivityIndicator(radius: 20))
              : _apps.isEmpty
              ? const Center(
                  child: Text('No apps found', style: TextStyle(fontSize: 18, color: CupertinoColors.systemGrey)),
                )
              : Padding(
                  padding: const EdgeInsets.all(0),
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 0.8,
                    ),
                    itemCount: _apps.length,
                    itemBuilder: (context, index) {
                      final app = _apps[index];
                      return _buildAppIcon(app);
                    },
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildAppIcon(Map<String, dynamic> app) {
    return GestureDetector(
      onTap: () => _openApp(app['packageName']),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Иконка приложения
          SizedBox(
            width: 60,
            height: 60,

            child: app['icon'] != null
                ? Image.memory(app['icon'] as Uint8List, fit: BoxFit.cover)
                : const Icon(CupertinoIcons.app, size: 30, color: CupertinoColors.systemGrey),
          ),
          const SizedBox(height: 8),
          Text(
            app['name'] ?? 'Unknown',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
