import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offline_document_viewer/src/document_view.dart';

void main() {
  testWidgets('document WebView stays mounted behind a loading cover', (
    WidgetTester tester,
  ) async {
    final GlobalKey webViewKey = GlobalKey();
    const Key coverKey = ValueKey<String>('loading-cover');
    bool ready = false;
    Widget surface() => Directionality(
      textDirection: TextDirection.ltr,
      child: Center(
        child: SizedBox(
          width: 300,
          height: 400,
          child: DocumentRenderSurface(
            backgroundColor: const Color(0xFFFFFFFF),
            webView: _TrackedView(key: webViewKey),
            ready: ready,
            loadingCover: const ColoredBox(
              key: coverKey,
              color: Color(0xFFFFFFFF),
            ),
          ),
        ),
      ),
    );

    await tester.pumpWidget(surface());
    final State<StatefulWidget> initialState = tester.state(
      find.byKey(webViewKey),
    );
    expect(tester.getSize(find.byKey(webViewKey)), const Size(300, 400));
    expect(find.byKey(coverKey), findsOneWidget);

    ready = true;
    await tester.pumpWidget(surface());
    expect(find.byKey(coverKey), findsNothing);
    expect(tester.state(find.byKey(webViewKey)), same(initialState));
    expect(tester.getSize(find.byKey(webViewKey)), const Size(300, 400));
  });
}

class _TrackedView extends StatefulWidget {
  const _TrackedView({super.key});

  @override
  State<_TrackedView> createState() => _TrackedViewState();
}

class _TrackedViewState extends State<_TrackedView> {
  @override
  Widget build(BuildContext context) => const SizedBox.expand();
}
