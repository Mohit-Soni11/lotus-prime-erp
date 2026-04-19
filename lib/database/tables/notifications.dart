import 'package:drift/drift.dart';
import 'base_table.dart';

@DataClassName('Notification')
// "Show Unread Notifications" query fast karne ke liye
@TableIndex(name: 'idx_notif_read', columns: {#isRead, #role}) 
class Notifications extends Table with BaseTable {
  
  TextColumn get role => text().withDefault(const Constant('all'))(); 
  TextColumn get type => text()(); 
  TextColumn get title => text()();
  TextColumn get desc => text()();
  
  BoolColumn get isRead => boolean().withDefault(const Constant(false))();
}