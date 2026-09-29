import 'package:jetleaf_lang/src/comparator/order_comparator.dart';
import 'package:jetleaf_lang/src/comparator/ordered.dart';
import 'package:test/test.dart';

class TestOrdered implements Ordered {
  final int order;
  
  TestOrdered(this.order);

  @override
  int getOrder() => order;
}

class TestPriorityOrdered implements PriorityOrdered {
  final int order;
  
  TestPriorityOrdered(this.order);

  @override
  int getOrder() => order;
}

class TestOrderSourceProvider extends OrderSourceProvider {
  final Map<Object, Object> sources;
  
  TestOrderSourceProvider(this.sources);
  
  @override
  Object? getOrderSource(Object obj) => sources[obj];
}

void main() {
  group('OrderComparator', () {
    test('should sort PriorityOrdered before Ordered', () {
      final priority = TestPriorityOrdered(100);
      final regular = TestOrdered(0);
      
      final result = OrderComparator.INSTANCE.compare(priority, regular);
      expect(result, lessThan(0));
    });
    
    test('should sort by order value within same type', () {
      final lowPriority = TestOrdered(100);
      final highPriority = TestOrdered(0);
      
      final result = OrderComparator.INSTANCE.compare(highPriority, lowPriority);
      expect(result, lessThan(0));
    });
    
    test('should use LOWEST_PRECEDENCE for non-Ordered objects', () {
      final ordered = TestOrdered(Ordered.LOWEST_PRECEDENCE);
      final nonOrdered = Object();
      
      final result = OrderComparator.INSTANCE.compare(ordered, nonOrdered);
      expect(result, 0);
    });
    
    test('should sort lists correctly', () {
      final list = [
        TestOrdered(100),
        TestPriorityOrdered(200),
        TestOrdered(0),
        TestPriorityOrdered(0),
      ];
      
      OrderComparator.sortList(list);
      
      // PriorityOrdered should come first, then Ordered by order value
      expect(list[0], isA<PriorityOrdered>());
      expect((list[0] as PriorityOrdered).getOrder(), 0);
      expect(list[1], isA<PriorityOrdered>());
      expect((list[1] as PriorityOrdered).getOrder(), 200);
      expect(list[2], isA<Ordered>());
      expect((list[2]).getOrder(), 0);
      expect(list[3], isA<Ordered>());
      expect((list[3]).getOrder(), 100);
    });
    
    test('should handle source provider', () {
      final obj = Object();
      final source = TestOrdered(42);
      final provider = TestOrderSourceProvider({obj: source});
      final comparator = OrderComparator.INSTANCE.withSource(provider);
      
      final result = comparator.compare(obj, TestOrdered(42));
      expect(result, 0);
    });
    
    test('should handle iterable source provider', () {
      final obj = Object();
      final sources = [TestOrdered(10), TestOrdered(20)];
      final provider = TestOrderSourceProvider({obj: sources});
      final comparator = OrderComparator.INSTANCE.withSource(provider);
      
      final result = comparator.compare(obj, TestOrdered(10));
      expect(result, 0);
    });
    
    test('sortIfNecessary should handle lists', () {
      final list = [TestOrdered(100), TestOrdered(0)];
      OrderComparator.sortIfNecessary(list);
      
      expect((list[0] as Ordered).getOrder(), 0);
      expect((list[1] as Ordered).getOrder(), 100);
    });
    
    test('sortIfNecessary should ignore non-lists', () {
      final nonList = TestOrdered(0);
      expect(() => OrderComparator.sortIfNecessary(nonList), returnsNormally);
    });
  });
}