import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../models/invite_event_model.dart';

class InviteService {
  // ⚠️ InvitePayload.dart의 _secret과 반드시 동일해야 함
  static const String _secret = 'TIMESCRAPER_INVITE_SECRET_CHANGE_ME';

  /// ✅ 딥링크에서 data 파라미터 추출
  static String? parseInviteData(Uri uri) {
    // 우리가 만든 링크: timescraper://invite?data=xxxx
    return uri.queryParameters['data'];
  }

  /// ✅ data(base64url(json)) → Map 디코딩
  static Map<String, dynamic> decodeDataToPayload(String data) {
    final padded = _padBase64(data);
    final jsonStr = utf8.decode(base64Url.decode(padded));
    final decoded = jsonDecode(jsonStr);
    if (decoded is! Map<String, dynamic>) {
      throw FormatException('payload 형식이 올바르지 않습니다.');
    }
    return decoded;
  }

  /// ✅ signature 검증
  static bool verifyPayload(Map<String, dynamic> payload) {
    if (!payload.containsKey('signature')) return false;

    final signature = payload['signature'];
    if (signature is! String) return false;

    // unsigned = signature 제외
    final unsigned = Map<String, dynamic>.from(payload)..remove('signature');
    final normalized = jsonEncode(_sorted(unsigned));

    final hmacSha256 = Hmac(sha256, utf8.encode(_secret));
    final digest = hmacSha256.convert(utf8.encode(normalized));
    final expected = base64UrlEncode(digest.bytes).replaceAll('=', '');

    return signature == expected;
  }

  /// ✅ payload → InviteEvent 변환 (id는 nonce 사용)
  static InviteEvent toInviteEvent(Map<String, dynamic> payload) {
    final range = payload['range'];
    if (range is! Map) throw FormatException('range가 없습니다.');

    final start = range['start'] as String?;
    final end = range['end'] as String?;
    final startHour = range['startHour'];
    final endHour = range['endHour'];

    final nonce = payload['nonce'] as String?;
    if (start == null || end == null || nonce == null) {
      throw FormatException('payload 필수값이 누락되었습니다.');
    }
    if (startHour is! int || endHour is! int) {
      throw FormatException('시간 정보가 올바르지 않습니다.');
    }

    final startDate = DateTime.parse(start); // YYYY-MM-DD
    final endDate = DateTime.parse(end);

    return InviteEvent(
      id: nonce,
      startDate: startDate,
      endDate: endDate,
      startHour: startHour,
      endHour: endHour,
    );
  }

  static String? parseInviterId(Map<String, dynamic> payload) {
    final inviterId = payload['inviterId'];
    return inviterId is String ? inviterId : null;
  }

  static String _padBase64(String s) {
    // base64url은 길이가 4의 배수가 아닐 수 있어 padding 보정
    final mod = s.length % 4;
    if (mod == 0) return s;
    return s + '=' * (4 - mod);
  }

  static dynamic _sorted(dynamic v) {
    if (v is Map) {
      final keys = v.keys.map((e) => e.toString()).toList()..sort();
      final res = <String, dynamic>{};
      for (final k in keys) {
        res[k] = _sorted(v[k]);
      }
      return res;
    }
    if (v is List) {
      return v.map(_sorted).toList();
    }
    return v;
  }
}
