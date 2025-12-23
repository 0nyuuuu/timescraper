import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import '../models/invite_event_model.dart';

class InvitePayload {
  // ⚠️ 데모용 시크릿. 나중에 서버/Remote Config로 옮기는 게 정석.
  static const String _secret = 'TIMESCRAPER_INVITE_SECRET_CHANGE_ME';

  /// nonce 생성 (base64url)
  static String _nonce() {
    final bytes = List<int>.generate(16, (_) => Random.secure().nextInt(256));
    return base64UrlEncode(bytes).replaceAll('=', '');
  }

  /// date 직렬화 (YYYY-MM-DD)
  static String _d(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  /// date 역직렬화 (YYYY-MM-DD)
  static DateTime _parseDate(String s) {
    final parts = s.split('-');
    if (parts.length != 3) throw FormatException('Invalid date: $s');
    return DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
  }

  /// payload 본문 생성 (signature 제외)
  /// ✅ inviteId를 포함 (Firestore 세션키)
  static Map<String, dynamic> buildUnsigned({
    required DateTime startDate,
    required DateTime endDate,
    required int startHour,
    required int endHour,
    required String inviterId,
    String? inviteId,
  }) {
    final nonce = _nonce();

    return {
      'inviteId': inviteId ?? nonce, // ✅ 없으면 nonce로 대체(최소 동작)
      'range': {
        'start': _d(startDate),
        'end': _d(endDate),
        'startHour': startHour,
        'endHour': endHour,
      },
      'inviterId': inviterId,
      'nonce': nonce,
    };
  }

  /// HMAC-SHA256 signature 생성
  static String sign(Map<String, dynamic> unsignedPayload) {
    final normalized = jsonEncode(_sorted(unsignedPayload));
    final key = utf8.encode(_secret);
    final bytes = utf8.encode(normalized);

    final hmacSha256 = Hmac(sha256, key);
    final digest = hmacSha256.convert(bytes);

    return base64UrlEncode(digest.bytes).replaceAll('=', '');
  }

  /// payload 완성본
  static Map<String, dynamic> buildSigned({
    required DateTime startDate,
    required DateTime endDate,
    required int startHour,
    required int endHour,
    required String inviterId,
    String? inviteId,
  }) {
    final unsigned = buildUnsigned(
      startDate: startDate,
      endDate: endDate,
      startHour: startHour,
      endHour: endHour,
      inviterId: inviterId,
      inviteId: inviteId,
    );

    final signature = sign(unsigned);

    return {
      ...unsigned,
      'signature': signature,
    };
  }

  /// 링크에 넣을 data= (base64url(json))
  static String encodeToParam(Map<String, dynamic> payload) {
    final jsonStr = jsonEncode(_sorted(payload));
    final b64 = base64UrlEncode(utf8.encode(jsonStr)).replaceAll('=', '');
    return b64;
  }

  /// ✅ data 파라미터 디코딩: base64url(json) -> payload Map
  static Map<String, dynamic> decodeParam(String data) {
    final padded = _padBase64Url(data);
    final bytes = base64Url.decode(padded);
    final jsonStr = utf8.decode(bytes);
    final obj = jsonDecode(jsonStr);
    if (obj is! Map) throw FormatException('payload is not a map');
    return obj.cast<String, dynamic>();
  }

  /// ✅ 서명 검증
  static bool verify(Map<String, dynamic> payload) {
    final sig = payload['signature'];
    if (sig is! String || sig.isEmpty) return false;

    final unsigned = Map<String, dynamic>.from(payload)..remove('signature');
    final expected = sign(unsigned);
    return _constantTimeEquals(sig, expected);
  }

  /// ✅ payload -> InviteEvent 변환
  static InviteEvent toInviteEvent(Map<String, dynamic> payload) {
    final inviteId = (payload['inviteId'] as String?) ?? (payload['nonce'] as String?) ?? 'unknown';

    final range = payload['range'];
    if (range is! Map) throw FormatException('range is missing');

    final start = _parseDate(range['start'] as String);
    final end = _parseDate(range['end'] as String);
    final startHour = (range['startHour'] as num).toInt();
    final endHour = (range['endHour'] as num).toInt();

    return InviteEvent(
      id: inviteId,
      startDate: DateTime(start.year, start.month, start.day),
      endDate: DateTime(end.year, end.month, end.day),
      startHour: startHour,
      endHour: endHour,
    );
  }

  /// 딥링크 생성
  /// 예) timescraper://invite?data=xxxxx
  static String buildInviteLink({
    required Map<String, dynamic> payload,
    String scheme = 'timescraper',
    String host = 'invite',
  }) {
    final data = encodeToParam(payload);
    return '$scheme://$host?data=$data';
  }

  // ------- 내부: key 정렬 -------
  static dynamic _sorted(dynamic v) {
    if (v is Map) {
      final keys = v.keys.map((e) => e.toString()).toList()..sort();
      final res = <String, dynamic>{};
      for (final k in keys) {
        res[k] = _sorted(v[k]);
      }
      return res;
    }
    if (v is List) return v.map(_sorted).toList();
    return v;
  }

  static String _padBase64Url(String s) {
    final mod = s.length % 4;
    if (mod == 0) return s;
    return s + '=' * (4 - mod);
  }

  static bool _constantTimeEquals(String a, String b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (int i = 0; i < a.length; i++) {
      diff |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return diff == 0;
  }
}
