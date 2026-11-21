/// Retained by the bell host while a notification destination is open.
class NotificationViewState {
  String filter = 'All';
  String search = '';
  int searchRevision = 0;

  void resetFilters() {
    filter = 'All';
    search = '';
    searchRevision++;
  }
}
