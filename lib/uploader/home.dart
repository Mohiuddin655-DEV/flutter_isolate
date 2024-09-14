import 'package:flutter/material.dart';

import 'isolated_tab.dart';

class HomePage extends StatelessWidget {
  final int isolateCount;

  const HomePage({
    super.key,
    required this.isolateCount,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: isolateCount,
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: const Text('Isolate'),
          bottom: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.center,
            padding: EdgeInsets.zero,
            tabs: List.generate(isolateCount, (index) {
              return Tab(text: '${index + 1}');
            }),
          ),
        ),
        body: TabBarView(
          children: List.generate(isolateCount, (index) {
            return IsolatedAdminPage(isolate: index);
          }),
        ),
      ),
    );
  }
}
