import 'package:flutter_test/flutter_test.dart';
import 'package:photo_management_app/album/view/album_page.dart';
import 'package:photo_management_app/app/app.dart';

void main() {
  group('App', () {
    testWidgets('renders CounterPage', (tester) async {
      await tester.pumpWidget(const App());
      expect(find.byType(AlbumPage), findsOneWidget);
    });
  });
}
