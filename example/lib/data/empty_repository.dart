// import 'package:jetleaf/jetleaf.dart';
// import 'package:jetleaf_data/jetleaf_data.dart';
// import 'package:jetleaf_data/annotation.dart';
// import 'package:jetleaf_scheduling/jetleaf_scheduling.dart';

// final class Empty {}

// @Repository()
// class EmptyRepository extends CrudRepository<Empty, int> {}

// @Service()
// @RequiredAll()
// class ReposTest {
//   final EmptyRepository repository;

//   int _attemptCount = 0;

//   ReposTest(this.repository);

//   @Scheduled(fixedRate: Duration(seconds: 10))
//   Future<void> tryGet() async {
//     _attemptCount++;
//     final result = await repository.findById(0);
//     print("Find by id - $result - $_attemptCount");
//   }
// }