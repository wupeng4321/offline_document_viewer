import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offline_document_viewer/src/document_view.dart';

void main() {
  testWidgets('document WebView starts full size and stays mounted', (
    WidgetTester tester,
  ) async {
    final GlobalKey webViewKey = GlobalKey();
    Widget surface() => Directionality(
      textDirection: TextDirection.ltr,
      child: Center(
        child: SizedBox(
          width: 300,
          height: 400,
          child: DocumentRenderSurface(
            backgroundColor: const Color(0xFFFFFFFF),
            webView: _TrackedView(key: webViewKey),
          ),
        ),
      ),
    );

    await tester.pumpWidget(surface());
    final State<StatefulWidget> initialState = tester.state(
      find.byKey(webViewKey),
    );
    expect(tester.getSize(find.byKey(webViewKey)), const Size(300, 400));

    await tester.pumpWidget(surface());
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
