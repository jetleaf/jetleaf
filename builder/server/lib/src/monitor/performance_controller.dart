import 'package:jetleaf/core.dart';
import 'package:jetleaf_monitor/jetleaf_monitor.dart';
import 'package:jetleaf_web/jetleaf_web.dart';

@RequiredAll()
@RestController("/monitor")
class PerformanceController {
  final MonitoringService _monitoringService;
  const PerformanceController(this._monitoringService);

  @GetMapping(path: "/{name}")
  Future<ResponseBody<Performance>> getPerformance(@PathVariable() String name) async {
    if (_monitoringService.getPerformance(name) case final performance?) {
      return ResponseBody.of(HttpStatus.OK, performance);
    }

    return ResponseBody.notFound();
  }

  @GetMapping()
  Future<ResponseBody<List<Performance>>> getPerformances() async {
    return ResponseBody.of(HttpStatus.OK, _monitoringService.getPerformances());
  }
}