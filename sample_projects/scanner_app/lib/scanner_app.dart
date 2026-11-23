import 'package:jetleaf/jetleaf.dart';

Future<void> main(List<String> args) async {
  // Notice: aotRegistrar is intentionally omitted (null)!
  // This exercises the scanner fallback branch:
  // if (_aotRegistrar case AotRegistrar registrar) { ... } else { await runScan(...); }
  final context = await JetleafApplication.run(
    const ScannerApp(),
    args,
  );

  if (context != null) {
    final greeter = await context.getPod<ScannerGreeterService>('scannerGreeterService');
    print(greeter.greet('Developer'));
    await context.close();
  }
}

@Configuration()
@JetleafApplicationStarter()
final class ScannerApp implements PodFactoryCustomizer {
  const ScannerApp();

  @override
  Future<void> customize(ConfigurablePodFactory podFactory, Environment environment) async {
    await podFactory.registerSingleton(
      'scannerGreeterService',
      Class<ScannerGreeterService>(),
      object: ObjectHolder(
        const ScannerGreeterService(),
        packageName: 'scanner_app',
        qualifiedName: 'package:scanner_app/scanner_app.dart.ScannerGreeterService',
      ),
    );

    await podFactory.registerSingleton(
      'scannerTaskRunner',
      Class<ScannerTaskRunner>(),
      object: ObjectHolder(
        ScannerTaskRunner(const ScannerGreeterService()),
        packageName: 'scanner_app',
        qualifiedName: 'package:scanner_app/scanner_app.dart.ScannerTaskRunner',
      ),
    );
  }
}

@Service()
final class ScannerGreeterService {
  const ScannerGreeterService();

  String greet(String name) => 'Hello from Scanner-discovered service, $name!';
}

@Component()
final class ScannerTaskRunner implements ApplicationRunner {
  final ScannerGreeterService greeter;
  bool ran = false;

  ScannerTaskRunner(this.greeter);

  @override
  int getOrder() => 0;

  @override
  Future<void> run(ApplicationArguments args) async {
    ran = true;
  }
}