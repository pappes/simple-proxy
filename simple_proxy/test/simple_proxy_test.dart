import 'package:simple_proxy/tunnel_handler.dart';
import 'package:test/test.dart';

void main() {
  test_modifyRequestHeaders({
    Map orig = const {},
    Map mods = const {},
    Map expected = const {},
  }) {
    modifyRequestHeaders(orig, mods);
    expect(expected, orig);
  }

  test('modifyRequestHeaders', () {
    test_modifyRequestHeaders(orig: {}, mods: {}, expected: {});
    test_modifyRequestHeaders(
      orig: {'abc': '123'},
      mods: {},
      expected: {'abc': '123'},
    );
    test_modifyRequestHeaders(
      orig: {},
      mods: {'abc': '123'},
      expected: {'abc': '123'},
    );
    test_modifyRequestHeaders(
      orig: {'abc': '123'},
      mods: {'def': '456'},
      expected: {'abc': '123', 'def': '456'},
    );
    test_modifyRequestHeaders(
      orig: {'abc': '123'},
      mods: {'def': '456', 'xyz': '987'},
      expected: {'abc': '123', 'def': '456', 'xyz': '987'},
    );
    test_modifyRequestHeaders(
      orig: {'abc': '123'},
      mods: {'def': '456', 'abc': '987'},
      expected: {'abc': '987', 'def': '456'},
    );
  });
}
