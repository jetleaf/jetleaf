// import 'dart:async';

// import 'package:jetleaf/jetleaf.dart';
// import 'package:jetleaf_intercept/jetleaf_intercept.dart';

// import '../core/common_infrastructure.dart';

// @Service()
// final class Intercepting with Interceptable {
//   void doSomething() async {
//     return when(() => print("Hello"));
//   }

//   Future<User> getUser() async => when<User>(() => User(name: "", email: ""));

//   Future<User?> getNullableUser() async => when<User?>(() => User(name: "", email: ""));
// }

// @Component()
// final class CustomMethodInterceptor implements ConditionalMethodInterceptor {
//   @override
//   bool canIntercept(Method method) => true;

//   @override
//   FutureOr<T?> intercept<T>(MethodInvocation<T> intercepted) async {
//     print("${intercepted.getMethod().getName()} for ${T} is nullable");
//     return null;
//   }
// }