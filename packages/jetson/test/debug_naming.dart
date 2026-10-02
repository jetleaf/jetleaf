import 'package:jetson/src/naming_strategy/naming_strategies.dart';

void main() {
  final snake = SnakeCaseNamingStrategy();
  print('user_name -> ${snake.toDartName("user_name")}');
  print('first_name -> ${snake.toDartName("first_name")}');
  print('http_request -> ${snake.toDartName("http_request")}');
}