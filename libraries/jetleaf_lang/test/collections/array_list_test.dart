import 'package:test/test.dart';
import 'package:jetleaf_lang/lang.dart';

void main() {
  group('ArrayList Tests', () {
    test('constructor and basic operations', () {
      ArrayList<String> list = ArrayList<String>();
      expect(list.isEmpty, isTrue);
      expect(list.size(), equals(0));
    });

    test('add and get operations', () {
      ArrayList<String> list = ArrayList<String>();
      
      expect(list.add("Hello"), isTrue);
      expect(list.add("World"), isTrue);
      
      expect(list.size(), equals(2));
      expect(list.get(0), equals("Hello"));
      expect(list.get(1), equals("World"));
      expect(list[0], equals("Hello")); // operator overload
    });

    test('insert operation', () {
      ArrayList<String> list = ArrayList<String>();
      list.add("Hello");
      list.add("World");
      list.insert(1, "Beautiful");
      
      expect(list.size(), equals(3));
      expect(list.get(0), equals("Hello"));
      expect(list.get(1), equals("Beautiful"));
      expect(list.get(2), equals("World"));
    });

    test('set operation', () {
      ArrayList<String> list = ArrayList<String>();
      list.add("Hello");
      list.add("World");
      
      String old = list.set(1, "Universe");
      expect(old, equals("World"));
      expect(list.get(1), equals("Universe"));
      
      list[0] = "Hi"; // operator overload
      expect(list.get(0), equals("Hi"));
    });

    test('remove operations', () {
      ArrayList<String> list = ArrayList<String>();
      list.add("Hello");
      list.add("World");
      list.add("Hello");
      
      expect(list.remove("Hello"), isTrue);
      expect(list.size(), equals(2));
      expect(list.get(0), equals("World"));
      expect(list.get(1), equals("Hello"));
      
      String removed = list.removeAt(0);
      expect(removed, equals("World"));
      expect(list.size(), equals(1));
    });

    test('contains and indexOf', () {
      ArrayList<String> list = ArrayList<String>();
      list.add("Hello");
      list.add("World");
      list.add("Hello");
      
      expect(list.contains("Hello"), isTrue);
      expect(list.contains("Universe"), isFalse);
      expect(list.indexOf("Hello"), equals(0));
      expect(list.lastIndexOf("Hello"), equals(2));
      expect(list.indexOf("Universe"), equals(-1));
    });

    test('addAll and insertAll', () {
      ArrayList<String> list = ArrayList<String>();
      list.add("Hello");
      
      expect(list.addAll(["World", "Universe"]), isTrue);
      expect(list.size(), equals(3));
      
      expect(list.insertAll(1, ["Beautiful", "Amazing"]), isTrue);
      expect(list.size(), equals(5));
      expect(list.get(1), equals("Beautiful"));
      expect(list.get(2), equals("Amazing"));
    });

    test('subList', () {
      ArrayList<String> list = ArrayList<String>();
      list.addAll(["A", "B", "C", "D", "E"]);
      
      ArrayList<String> sub = list.subList(1, 4);
      expect(sub.size(), equals(3));
      expect(sub.get(0), equals("B"));
      expect(sub.get(1), equals("C"));
      expect(sub.get(2), equals("D"));
    });

    test('clear', () {
      ArrayList<String> list = ArrayList<String>();
      list.addAll(["A", "B", "C"]);
      
      list.clear();
      expect(list.isEmpty, isTrue);
      expect(list.size(), equals(0));
    });

    test('sort and reverse', () {
      ArrayList<String> list = ArrayList<String>();
      list.addAll(["C", "A", "B"]);
      
      list.sort();
      expect(list.get(0), equals("A"));
      expect(list.get(1), equals("B"));
      expect(list.get(2), equals("C"));
      
      list.reverse();
      expect(list.get(0), equals("C"));
      expect(list.get(1), equals("B"));
      expect(list.get(2), equals("A"));
    });

    test('from constructor', () {
      ArrayList<String> list = ArrayList.from(["A", "B", "C"]);
      expect(list.size(), equals(3));
      expect(list.get(0), equals("A"));
    });

    test('toList and toArray', () {
      ArrayList<String> list = ArrayList<String>();
      list.addAll(["A", "B", "C"]);
      
      List<String> dartList = list.toList();
      expect(dartList.length, equals(3));
      expect(dartList[0], equals("A"));
      
      List<String> array = list.toArray();
      expect(array.length, equals(3));
    });

    test('iterator', () {
      ArrayList<String> list = ArrayList<String>();
      list.addAll(["A", "B", "C"]);
      
      List<String> iterated = [];
      for (String item in list) {
        iterated.add(item);
      }
      
      expect(iterated, equals(["A", "B", "C"]));
    });

    test('equality', () {
      ArrayList<String> list1 = ArrayList.from(["A", "B", "C"]);
      ArrayList<String> list2 = ArrayList.from(["A", "B", "C"]);
      ArrayList<String> list3 = ArrayList.from(["A", "B", "D"]);
      
      expect(list1 == list2, isTrue);
      expect(list1 == list3, isFalse);
      expect(list1.hashCode, equals(list2.hashCode));
    });
  });
}
