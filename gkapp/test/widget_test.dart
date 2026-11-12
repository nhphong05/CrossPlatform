import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:gkapp/models/lecturer.dart';
import 'package:gkapp/screens/login_screen.dart';
import 'package:gkapp/screens/lecturer_list_screen.dart';
import 'package:gkapp/services/auth_api.dart';
import 'package:gkapp/services/lecturer_api.dart';
import 'package:gkapp/services/lecturer_repository.dart';
import 'package:gkapp/widgets/lecturer_card.dart';

void main() {
  test('Android emulator API defaults to the host machine', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    final client = MockClient((request) async {
      expect(request.url.toString(), 'http://10.0.2.2:3000/api/lecturers');
      return http.Response('[]', 200);
    });

    try {
      expect(await LecturerApi(client: client).getAll(), isEmpty);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  test(
    'login sends credentials to the auth endpoint and returns a token',
    () async {
      final client = MockClient((request) async {
        expect(request.url.path, '/api/auth/login');
        expect(request.method, 'POST');
        expect(request.headers['content-type'], 'application/json');
        expect(request.body, '{"username":"admin","password":"secret"}');
        return http.Response('{"token":"test-token","expiresIn":28800}', 200);
      });

      expect(
        await AuthApi(client: client).login('admin', 'secret'),
        'test-token',
      );
    },
  );

  test('lecturer API sends the bearer token', () async {
    final client = MockClient((request) async {
      expect(request.headers['authorization'], 'Bearer test-token');
      return http.Response('[]', 200);
    });

    await LecturerApi(token: 'test-token', client: client).getAll();
  });

  test('lecturer JSON uses only the required database fields', () {
    const lecturer = Lecturer(
      id: 'GV001',
      fullname: 'Nguyễn Minh Anh',
      image: 'data:image/png;base64,AA==',
      sumClass: 4,
    );

    expect(lecturer.toJson(), {
      'IDGV': 'GV001',
      'Fullname': 'Nguyễn Minh Anh',
      'Image': 'data:image/png;base64,AA==',
      'SumClass': 4,
    });
    expect(Lecturer.fromJson(lecturer.toJson()).sumClass, 4);
  });

  test('lecturer draft omits the system-generated IDGV', () {
    const lecturer = LecturerDraft(
      fullname: 'Nguyễn Minh Anh',
      image: 'data:image/png;base64,AA==',
      sumClass: 4,
    );

    expect(lecturer.toJson(), {
      'Fullname': 'Nguyễn Minh Anh',
      'Image': 'data:image/png;base64,AA==',
      'SumClass': 4,
    });
  });

  test('creating a lecturer sends no IDGV to the server', () async {
    final client = MockClient((request) async {
      expect(request.method, 'POST');
      expect(request.body, contains('"Fullname":"Nguyễn Minh Anh"'));
      expect(request.body, isNot(contains('IDGV')));
      return http.Response('', 201);
    });

    await LecturerApi(client: client).create(
      const LecturerDraft(
        fullname: 'Nguyễn Minh Anh',
        image: 'data:image/png;base64,AA==',
        sumClass: 4,
      ),
    );
  });

  test('lecturer rejects a fractional SumClass value', () {
    expect(
      () => Lecturer.fromJson({
        'IDGV': 'GV001',
        'Fullname': 'Nguyễn Minh Anh',
        'Image': '',
        'SumClass': 1.5,
      }),
      throwsFormatException,
    );
  });

  test('API accepts an empty 204 response after deleting a lecturer', () async {
    final client = MockClient((request) async {
      expect(request.method, 'DELETE');
      expect(request.url.path, '/api/lecturers/GV001');
      return http.Response('', 204);
    });

    await LecturerApi(client: client).delete('GV001');
  });

  testWidgets('empty state prompts user to add the first lecturer', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: LecturerListScreen(repository: _EmptyLecturerRepository()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Chưa có giảng viên'), findsOneWidget);
    expect(find.text('Thêm giảng viên'), findsWidgets);
  });

  testWidgets('login screen validates empty credentials', (tester) async {
    var loginCalled = false;
    await tester.pumpWidget(
      MaterialApp(
        home: LoginScreen(onLogin: (_, _) async => loginCalled = true),
      ),
    );

    await tester.tap(find.text('Đăng nhập'));
    await tester.pumpAndSettle();

    expect(find.text('Vui lòng nhập tên đăng nhập.'), findsOneWidget);
    expect(find.text('Vui lòng nhập mật khẩu.'), findsOneWidget);
    expect(loginCalled, isFalse);
  });

  testWidgets('class filter shows only lecturers with no classes', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: LecturerListScreen(
          repository: _LecturerListRepository([
            _lecturer('GV001', 'Bình', 0),
            _lecturer('GV002', 'An', 3),
            _lecturer('GV003', 'Cường', 1),
          ]),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ChoiceChip, 'Chưa có lớp'));
    await tester.pumpAndSettle();

    expect(find.text('GV001'), findsOneWidget);
    expect(find.text('GV002'), findsNothing);
    expect(find.text('GV003'), findsNothing);
  });

  testWidgets('sort selection orders lecturers by class count', (tester) async {
    tester.view.physicalSize = const Size(1200, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: LecturerListScreen(
          repository: _LecturerListRepository([
            _lecturer('GV001', 'Bình', 0),
            _lecturer('GV002', 'An', 3),
            _lecturer('GV003', 'Cường', 1),
          ]),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('lecturer-sort')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Số lớp: giảm dần'));
    await tester.pumpAndSettle();

    final visibleLecturers = find
        .byType(LecturerCard)
        .evaluate()
        .map((element) => (element.widget as LecturerCard).lecturer.id)
        .toList();
    expect(visibleLecturers, ['GV002', 'GV003', 'GV001']);
  });

  testWidgets('failed request does not look like a genuinely empty database', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: LecturerListScreen(repository: _UnavailableLecturerRepository()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Không kết nối được máy chủ'), findsOneWidget);
    expect(find.text('Chưa có giảng viên'), findsNothing);
  });
}

Lecturer _lecturer(String id, String fullname, int sumClass) =>
    Lecturer(id: id, fullname: fullname, image: '', sumClass: sumClass);

class _LecturerListRepository implements LecturerRepository {
  _LecturerListRepository(this.lecturers);

  final List<Lecturer> lecturers;

  @override
  Future<void> create(LecturerDraft lecturer) async {}

  @override
  Future<void> delete(String id) async {}

  @override
  Future<List<Lecturer>> getAll() async => lecturers;

  @override
  Future<void> update(Lecturer lecturer) async {}
}

class _EmptyLecturerRepository implements LecturerRepository {
  @override
  Future<void> create(LecturerDraft lecturer) async {}

  @override
  Future<void> delete(String id) async {}

  @override
  Future<List<Lecturer>> getAll() async => [];

  @override
  Future<void> update(Lecturer lecturer) async {}
}

class _UnavailableLecturerRepository implements LecturerRepository {
  @override
  Future<void> create(LecturerDraft lecturer) async {}

  @override
  Future<void> delete(String id) async {}

  @override
  Future<List<Lecturer>> getAll() async {
    throw Exception('Backend không sẵn sàng.');
  }

  @override
  Future<void> update(Lecturer lecturer) async {}
}
