import 'models/firestore_models_test.dart' as models_test;
import 'services/cache_service_test.dart' as cache_test;
import 'utils/date_formatter_test.dart' as date_test;
import 'services/permission_service_test.dart' as permission_test;

void main() {
  models_test.main();
  cache_test.main();
  date_test.main();
  permission_test.main();
}
