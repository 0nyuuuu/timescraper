import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

class InvitePayload {
  // ⚠️ 데모용 시크릿. 나중에 서버/Remote Config로 옮기는 게 정석.
  // 지금은 "변조 방지용" 최소 구현이라 앱 안에 둠.
  static const String _secret = 'TIMESCRAPER_INVITE_SECRET_CHANGE_ME';

  /// nonce 생성 (base64url)
  static String _nonce() {
    final bytes = List<int>.generate(16, (_) => Random.secure().nextInt(256));
    return base64UrlEncode(bytes).replaceAll('=', '');
  }

  /// range 직렬화 (YYYY-MM-DD)
  static String _d(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  /// payload 본문 생성 (signature 제외)
  static Map<String, dynamic> buildUnsigned({
    required DateTime startDate,
    required DateTime endDate,
    required int startHour,
    required int endHour,
    required String inviterId,
  }) {
    final nonce = _nonce();
    return {
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
    // 정렬된 JSON 문자열로 고정 (서명 안정화)
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
  }) {
    final unsigned = buildUnsigned(
      startDate: startDate,
      endDate: endDate,
      startHour: startHour,
      endHour: endHour,
      inviterId: inviterId,
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
    if (v is List) {
      return v.map(_sorted).toList();
    }
    return v;
  }
}
