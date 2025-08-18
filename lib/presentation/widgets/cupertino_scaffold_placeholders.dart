import 'package:flutter/cupertino.dart';

class CupertinoPlaceholderPage extends StatelessWidget {
  final String title;
  final String message;
  const CupertinoPlaceholderPage({super.key, required this.title, required this.message});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(middle: Text(title)),
      child: SafeArea(
        child: Center(child: Text(message, textDirection: TextDirection.rtl)),
      ),
    );
  }
}

