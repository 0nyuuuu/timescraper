class InviteService {
  static String createInviteLink(String inviteId) {
    // 실제 배포 시 도메인만 교체
    return 'https://timescraper.app/invite/$inviteId';
  }

  static String? parseInviteId(Uri uri) {
    if (uri.pathSegments.length >= 2 &&
        uri.pathSegments.first == 'invite') {
      return uri.pathSegments[1];
    }
    return null;
  }
}
