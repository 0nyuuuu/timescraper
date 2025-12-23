import 'package:cloud_firestore/cloud_firestore.dart';

class InviteSyncService {
  static final _db = FirebaseFirestore.instance;

  /// invites/{inviteId} 문서 생성/업데이트 (range & inviterId 저장)
  static Future<void> upsertInviteMeta({
    required String inviteId,
    required String inviterId,
    required Map<String, dynamic> range, // {start,end,startHour,endHour}
  }) async {
    await _db.collection('invites').doc(inviteId).set({
      'inviterId': inviterId,
      'range': range,
      'createdAt': FieldValue.serverTimestamp(),
      // ready flags
      'inviterReady': false,
      'joinerReady': false,
    }, SetOptions(merge: true));
  }

  /// role: 'inviter' or 'joiner'
  /// weeklyTable: { "1":[0,1,...], "2":[...], ... }  (weekday 1..7)
  /// monthBusy: { "2025-12":[0/1...], "2026-01":[...] }
  static Future<void> uploadUserTables({
    required String inviteId,
    required String role, // inviter|joiner
    required String userId,
    required Map<String, dynamic> weeklyTable,
    required Map<String, dynamic> monthBusy,
  }) async {
    final doc = _db.collection('invites').doc(inviteId);

    await doc.collection('participants').doc(role).set({
      'userId': userId,
      'weeklyTable': weeklyTable,
      'monthBusy': monthBusy,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await doc.set({
      role == 'inviter' ? 'inviterReady' : 'joinerReady': true,
    }, SetOptions(merge: true));
  }

  /// both ready 스트림
  static Stream<bool> bothReadyStream(String inviteId) {
    return _db.collection('invites').doc(inviteId).snapshots().map((snap) {
      final data = snap.data();
      if (data == null) return false;
      final a = data['inviterReady'] == true;
      final b = data['joinerReady'] == true;
      return a && b;
    });
  }

  /// 둘 다 준비되면 1번만 true 리턴
  static Future<void> waitUntilBothReady(String inviteId) async {
    await for (final ready in bothReadyStream(inviteId)) {
      if (ready) return;
    }
  }
}
