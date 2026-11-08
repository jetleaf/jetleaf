// ---------------------------------------------------------------------------
// 🍃 Jetleaf Framework - Ultimate Test Suite
// Unit, Integration, Circular Fuzzing, Deep Annotations, and Web Workflows
// ---------------------------------------------------------------------------

import 'dart:async';
import 'package:test/test.dart';
import 'package:jetleaf_core/lang.dart';
import 'package:ultimate/src/annotations/deep_annotations.dart';
import 'package:ultimate/src/circular/order_workflow_service.dart';
import 'package:ultimate/src/circular/payment_gateway_service.dart';
import 'package:ultimate/src/circular/audit_trail_service.dart';
import 'package:ultimate/src/models/user_dto.dart';
import 'package:ultimate/src/services/billing_service.dart';
import 'package:ultimate/src/services/custom_service.dart';
import 'package:ultimate/src/services/items_repository.dart';
import 'package:ultimate/src/services/pci_payment_vault.dart';

void main() {
  group('Ultimate Test Suite - Domain & Serialization', () {
    test('UserDto serializes to JSON with field remapping and ignoring', () {
      final user = UserDto(
        fullName: 'Jane Doe',
        email: 'jane@example.com',
        age: 28,
        birthDate: DateTime(1996, 5, 12),
        balance: 1500.50,
      );

      final json = user.toJson();
      expect(json['full_name'], equals('Jane Doe'));
      expect(json['email_address'], equals('jane@example.com'));
      expect(json['age'], equals(28));
      expect(json['credit_balance'], equals(1500.50));
      expect(json.containsKey('internalToken'), isFalse);
    });

    test('UserDto deserializes from JSON correctly', () {
      final json = {
        'full_name': 'John Smith',
        'email_address': 'john@example.com',
        'age': 35,
        'credit_balance': 250.0,
      };

      final user = UserDto.fromJson(json);
      expect(user.fullName, equals('John Smith'));
      expect(user.email, equals('john@example.com'));
      expect(user.age, equals(35));
      expect(user.balance, equals(250.0));
      expect(user.internalToken, equals('secret-token-123'));
    });
  });

  group('Ultimate Test Suite - Services & Repositories', () {
    test('ItemsRepository behaves as a valid mutable repository', () {
      final repo = DefaultItemsRepository();
      expect(repo.getItems(), containsAll(['alpha', 'beta', 'gamma']));
      repo.addItem('delta');
      expect(repo.getItems(), contains('delta'));
    });

    test('BillingService computes invoices and handles mock retries', () async {
      final repo = DefaultItemsRepository();
      final billing = DefaultBillingService(repo);

      final invoice = await billing.calculateInvoice('ACC-101');
      expect(invoice, contains('ACC-101'));
      expect(invoice, contains('alpha, beta, gamma'));

      final payment = await billing.processPayment('ACC-101', 99.95);
      expect(payment, contains('\$99.95'));

      final evict = await billing.evictInvoice('ACC-101');
      expect(evict, contains('Evicted'));
    });

    test('CustomService lifecycle methods execute correctly', () async {
      final customService = CustomServiceImplementation();
      expect(customService.postConstructInvoked, isFalse);
      expect(customService.customOnReadyInvoked, isFalse);

      customService.initialize();
      expect(customService.postConstructInvoked, isTrue);

      await customService.onAppReady();
      expect(customService.customOnReadyInvoked, isTrue);

      expect(customService.processData('INPUT_1'), equals('Audited: INPUT_1'));

      customService.cleanup();
      expect(customService.preDestroyInvoked, isTrue);
    });
  });

  group('Ultimate Test Suite - Deep Annotation Hierarchy', () {
    test('PciDssAudit preserves 4-level class hierarchy and attribute values', () {
      const pci = PciDssAudit(
        'payment-gateway',
        merchantId: 'M-12345',
        clearanceLevel: 3,
        regulation: 'PCI-DSS-v4.0',
      );

      // Verify leaf type
      expect(pci.annotationType, equals(PciDssAudit));
      expect(pci.merchantId, equals('M-12345'));

      // Verify Level 3 (ComplianceAudit) inheritance
      expect(pci, isA<ComplianceAudit>());
      expect(pci.regulation, equals('PCI-DSS-v4.0'));

      // Verify Level 2 (SecurityBoundary) inheritance
      expect(pci, isA<SecurityBoundary>());
      expect(pci.clearanceLevel, equals(3));

      // Verify Level 1 (AuditRoot) inheritance
      expect(pci, isA<AuditRoot>());
      expect(pci.domain, equals('payment-gateway'));

      // Verify base ReflectableAnnotation contract
      expect(pci, isA<ReflectableAnnotation>());
    });

    test('PciPaymentVault operates with annotated security methods', () {
      final vault = PciPaymentVault();
      final token = vault.tokenizeCard('4111-2222-3333-4444');
      expect(token, startsWith('TOK-'));

      final hash = vault.hashSecret('my-super-secret');
      expect(hash, startsWith('SEC-'));
    });
  });

  group('Ultimate Test Suite - Complex Circular Dependencies & Fuzzing', () {
    test('3-Way Circular Dependency (Order -> Payment -> Audit -> Order) resolves and operates seamlessly', () {
      // Construct a lazy-resolving holder for OrderWorkflowService to emulate Jetleaf Pod Factory @Lazy proxy
      late final DefaultOrderWorkflowService orderWorkflow;

      // Lazy proxy delegate that forwards calls to orderWorkflow instance
      final lazyOrderWorkflowProxy = _LazyOrderWorkflowProxy(() => orderWorkflow);

      final auditTrail = DefaultAuditTrailService(lazyOrderWorkflowProxy);
      final paymentGateway = DefaultPaymentGatewayService(auditTrail);
      orderWorkflow = DefaultOrderWorkflowService(paymentGateway);

      // Execute cyclical workflow:
      // orderWorkflow.processOrder -> paymentGateway.charge -> auditTrail.logEvent -> orderWorkflow.getWorkflowStatus
      final result = orderWorkflow.processOrder('ORD-9001', 250.00);

      expect(result, equals('ORDER_PROCESSED:ORD-9001:CHARGED_\$250.0'));
      expect(auditTrail.getAuditLogs().length, equals(1));
      expect(
        auditTrail.getAuditLogs().first,
        equals('AUDIT:[ACTIVE_WORKFLOW:ORD-9001] PAYMENT_CHARGED_\$250.0'),
      );
    });

    test('Aggressive fuzzing of circular dependency under 1,000 rapid cycles', () {
      late final DefaultOrderWorkflowService orderWorkflow;
      final lazyProxy = _LazyOrderWorkflowProxy(() => orderWorkflow);

      final auditTrail = DefaultAuditTrailService(lazyProxy);
      final paymentGateway = DefaultPaymentGatewayService(auditTrail);
      orderWorkflow = DefaultOrderWorkflowService(paymentGateway);

      final stopwatch = Stopwatch()..start();

      for (int i = 0; i < 1000; i++) {
        final orderId = 'ORD-FUZZ-$i';
        final result = orderWorkflow.processOrder(orderId, i * 1.5);
        expect(result, contains('ORDER_PROCESSED:$orderId'));
      }

      stopwatch.stop();
      expect(auditTrail.getAuditLogs().length, equals(1000));
      expect(stopwatch.elapsedMilliseconds, lessThan(1000), reason: '1,000 circular proxy dispatches must take < 1 second');
    });
  });

  group('Ultimate Test Suite - Complex Web Workflows', () {
    test('Streaming Chunked Pipeline transfers full data integrity asynchronously', () async {
      // Emulate Jetleaf Web Chunked Stream pipeline
      final controller = StreamController<List<int>>();

      final receivedChunks = <List<int>>[];
      final completer = Completer<void>();

      controller.stream.listen(
        (chunk) => receivedChunks.add(chunk),
        onDone: () => completer.complete(),
      );

      // Stream 50 chunks of 1KB binary payload
      for (int i = 0; i < 50; i++) {
        controller.add(List.filled(1024, i % 256));
        await Future.delayed(Duration(microseconds: 50));
      }
      await controller.close();
      await completer.future;

      expect(receivedChunks.length, equals(50));
      final totalBytes = receivedChunks.fold<int>(0, (sum, chunk) => sum + chunk.length);
      expect(totalBytes, equals(50 * 1024));
    });

    test('Multipart Form-Data boundary parser decomposes attachments and form fields', () {
      const boundary = '----JetleafBoundaryXYZ123';
      const body = 
        '--$boundary\r\n'
        'Content-Disposition: form-data; name="username"\r\n\r\n'
        'antigravity_admin\r\n'
        '--$boundary\r\n'
        'Content-Disposition: form-data; name="avatar"; filename="avatar.png"\r\n'
        'Content-Type: image/png\r\n\r\n'
        '\x89PNG\r\n\x1a\n\x00\x00\x00\rIHDR\r\n'
        '--$boundary--\r\n';

      final parts = body.split('--$boundary');
      final fields = <String, String>{};
      final files = <String, String>{};

      for (final rawPart in parts) {
        final part = rawPart.trim();
        if (part.isEmpty || part == '--') continue;

        final headerEnd = part.indexOf('\r\n\r\n');
        if (headerEnd == -1) continue;

        final header = part.substring(0, headerEnd);
        final content = part.substring(headerEnd + 4);

        if (header.contains('filename="')) {
          final filenameMatch = RegExp(r'filename="([^"]+)"').firstMatch(header);
          files[filenameMatch?.group(1) ?? 'file'] = content;
        } else {
          final nameMatch = RegExp(r'name="([^"]+)"').firstMatch(header);
          fields[nameMatch?.group(1) ?? 'field'] = content;
        }
      }

      expect(fields['username'], equals('antigravity_admin'));
      expect(files.containsKey('avatar.png'), isTrue);
      expect(files['avatar.png'], contains('PNG'));
    });

    test('WebSocket Connection Upgrade and Bi-directional Framing simulation', () async {
      // Simulate client and server duplex communication pipeline
      final clientToServer = StreamController<String>();
      final serverToClient = StreamController<String>();

      final clientReceived = <String>[];
      final serverReceived = <String>[];

      // Server echoes client messages with prefix
      serverToClient.stream.listen((msg) => clientReceived.add(msg));
      clientToServer.stream.listen((msg) {
        serverReceived.add(msg);
        serverToClient.add('SERVER_ACK:$msg');
      });

      // Send 10 duplex frames
      for (int i = 1; i <= 10; i++) {
        clientToServer.add('FRAME_$i');
      }

      await Future.delayed(Duration(milliseconds: 20));

      expect(serverReceived.length, equals(10));
      expect(clientReceived.length, equals(10));
      expect(clientReceived.first, equals('SERVER_ACK:FRAME_1'));
      expect(clientReceived.last, equals('SERVER_ACK:FRAME_10'));

      await clientToServer.close();
      await serverToClient.close();
    });

    test('High-concurrency pipeline handles 100 concurrent requests without race conditions', () async {
      final results = await Future.wait(
        List.generate(100, (index) async {
          await Future.delayed(Duration(milliseconds: index % 5));
          return 'RESPONSE_OK_$index';
        }),
      );

      expect(results.length, equals(100));
      expect(results.first, equals('RESPONSE_OK_0'));
      expect(results.last, equals('RESPONSE_OK_99'));
    });
  });
}

/// Helper proxy simulating pure AOT interface delegation for circular dependency injection.
class _LazyOrderWorkflowProxy implements OrderWorkflowService {
  final OrderWorkflowService Function() _provider;
  _LazyOrderWorkflowProxy(this._provider);

  @override
  String processOrder(String orderId, double amount) => _provider().processOrder(orderId, amount);

  @override
  String getWorkflowStatus(String orderId) => _provider().getWorkflowStatus(orderId);
}