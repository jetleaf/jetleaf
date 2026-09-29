import 'package:example/retry/try.dart';
import 'package:jetleaf_web/jetleaf_web.dart';

import '../core/common_infrastructure.dart';

@RestController("/users")
class GetWeb {
  final RetryTestService retry;

  GetWeb(this.retry);

  /// GET `/users/{id}?username=Frank&email=frank@gmail.com`
  ///
  /// Retrieves a user by ID, with additional request parameters.
  @GetMapping(path: "/{id}")
  Future<User> getUser(
    @RequestParam() String username,
    @PathVariable() String id,
    @RequestParam() String email,
  ) async {
    await retry.pingServerWithRetry();
    throw NotFoundException("Not found");
    // return User(name: username, email: email, id: id);
  }

  /// POST `/users`
  ///
  /// Updates or creates a new user based on the provided JSON body.
  @PostMapping()
  Future<User> updateUser(@RequestBody() User user) async {
    await retry.sendHeartbeatWithRetry();
    return user;
  }

  /// DELETE `/users/{id}`
  ///
  /// Deletes a user and returns a confirmation message.
  @DeleteMapping(path: "/{id}")
  Future<Map<String, dynamic>> deleteUser(@PathVariable() String id) async {
    return {
      "status": "deleted",
      "id": id,
      "timestamp": DateTime.now().toIso8601String(),
    };
  }

  /// GET `/users`
  ///
  /// Returns a list of all users. Demonstrates returning a collection.
  @GetMapping(path: "/")
  Future<List<User>> getAllUsers() async {
    return [
      User(name: "Alice", email: "alice@example.com", id: "1"),
      User(name: "Bob", email: "bob@example.com", id: "2"),
      User(name: "Charlie", email: "charlie@example.com", id: "3"),
    ];
  }

  /// PUT `/users/{id}`
  ///
  /// Demonstrates partial updates — similar to HTTP PATCH semantics.
  @PutMapping(path: "/{id}")
  Future<User> replaceUser(
    @PathVariable() String id,
    @RequestBody() User user,
  ) async {
    // Replace the ID from the path, ensure consistency
    return user.copyWith(id: id);
  }

  /// PATCH `/users/{id}`
  ///
  /// Updates only specific fields of a user.
  @PatchMapping(path: "/{id}")
  Future<User> patchUser(
    @PathVariable() String id,
    @RequestBody() Map<String, dynamic> fields,
  ) async {
    // Example partial update logic (mock)
    final existing = User(name: "Existing", email: "existing@example.com", id: id);
    final updated = User(
      name: fields["name"] ?? existing.name,
      email: fields["email"] ?? existing.email,
    );
    return updated;
  }

  /// GET `/users/search`
  ///
  /// Demonstrates complex query parameters.
  @GetMapping(path: "/search")
  Future<List<User>> searchUsers(
    @RequestParam(required: false) String? name,
    @RequestParam(required: false) String? email,
  ) async {
    // Mocked filtering logic
    final allUsers = [
      User(name: "Alice", email: "alice@example.com", id: "1"),
      User(name: "Bob", email: "bob@example.com", id: "2"),
      User(name: "Charlie", email: "charlie@example.com", id: "3"),
    ];

    return allUsers
        .where((u) =>
            (name == null || u.name.contains(name)) &&
            (email == null || u.email == email))
        .toList();
  }

  /// GET `/users/status`
  ///
  /// Demonstrates returning a custom media type (e.g., text/plain).
  @GetMapping(
    path: "/status",
    produces: [MediaType.TEXT_PLAIN],
  )
  Future<String> getStatus() async {
    return "Jetleaf User API is healthy ✅ (${DateTime.now().toIso8601String()})";
  }
}

@WebView("/welcome")
final class HtmlView extends RenderableView {
  @override
  Future<String> render(ViewContext context) async {
    final username = context.getQueryParam("username") ?? "Guest";
    context.setViewAttributes({"id": "user"});

    // Return a complete HTML page
    return """
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>Welcome Page</title>
  <style>
    body { font-family: Arial, sans-serif; background-color: #f0f0f0; padding: 2rem; }
    h1 { color: #333; }
  </style>
</head>
<body>
  <h1>Welcome, $username!</h1>
  <p>We're glad to see you here. Enjoy your stay!</p>
</body>
</html>
""";
  }
}

@WebView("/forgot-password/{emailAddress}")
final class SimplePageView extends RenderableWebView {
  @override
  Future<PageView> render(ViewContext context) async {
    final email = context.getPathVariable("emailAddress") ?? "";

    // Use PageView to render template with dynamic data
    return PageView("forgot-password")
      ..addAttribute("email", email)
      ..addAttribute("message", email.isEmpty
          ? "Please enter your email to reset your password."
          : "A password reset link has been sent to $email.");
  }
}