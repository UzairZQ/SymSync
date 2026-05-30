enum SessionTab { dashboard, session, summary, profile }

extension SessionTabLabel on SessionTab {
  String get label {
    switch (this) {
      case SessionTab.dashboard:
        return 'Dashboard';
      case SessionTab.session:
        return 'Session';
      case SessionTab.summary:
        return 'Summary';
      case SessionTab.profile:
        return 'Profile';
    }
  }
}
