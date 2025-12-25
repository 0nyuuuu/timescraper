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
      // ❌ 여기서 ready를 false로 쓰지 말 것 (리셋 방지)
    }, SetOptions(merge: true));
  }

  /// role: 'inviter' or 'joiner'
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

  static Stream<bool> bothReadyStream(String inviteId) {
    return _db.collection('invites').doc(inviteId).snapshots().map((snap) {
      final data = snap.data();
      if (data == null) return false;
      final a = data['inviterReady'] == true;
      final b = data['joinerReady'] == true;
      return a && b;
    });
  }

  static Future<void> waitUntilBothReady(String inviteId) async {
    await for (final ready in bothReadyStream(inviteId)) {
      if (ready) return;
    }
  }
}
