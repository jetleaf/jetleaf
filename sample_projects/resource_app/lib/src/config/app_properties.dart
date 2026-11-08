import 'package:jetleaf_core/annotation.dart';

@ConfigurationProperty(prefix: 'app')
class AppProperties {
  String name = 'default-app';
  String description = 'default-description';
  int port = 8080;
}