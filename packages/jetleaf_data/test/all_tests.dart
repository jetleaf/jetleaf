// test/all_tests.dart

import 'package:test/test.dart';

import 'smoke_test.dart' as smoke_tests;
import 'query/part_tree_test.dart' as query_tests;
import 'query/parameter_binder_test.dart' as binder_tests;
import 'dialect/postgres_dialect_test.dart' as postgres_tests;
import 'dialect/mysql_dialect_test.dart' as mysql_tests;
import 'dialect/sqlite_dialect_test.dart' as sqlite_tests;
import 'dialect/mongo_dialect_test.dart' as mongo_tests;
import 'dialect/dialect_registry_test.dart' as registry_tests;
import 'mapping/entity_metadata_test.dart' as mapping_tests;
import 'repository/simple_jetleaf_repository_test.dart' as repository_tests;
import 'repository/repository_proxy_test.dart' as proxy_tests;
import 'transaction/transactional_test.dart' as transaction_tests;
import 'migration/migration_runner_test.dart' as migration_tests;
import 'driver/connection_pool_test.dart' as pool_tests;

void main() {
  group('Jetleaf Data Unit Tests', () {
    smoke_tests.main();
    query_tests.main();
    binder_tests.main();
    postgres_tests.main();
    mysql_tests.main();
    sqlite_tests.main();
    mongo_tests.main();
    registry_tests.main();
    mapping_tests.main();
    repository_tests.main();
    proxy_tests.main();
    transaction_tests.main();
    migration_tests.main();
    pool_tests.main();
  });
}