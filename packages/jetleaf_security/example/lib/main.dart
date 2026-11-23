import 'package:jetleaf/jetleaf.dart';

import 'package:jetleaf_security/annotation.dart';

void main(List<String> args) async {
  final context = await JetleafApplication.run(
    SecurityDemoApplication(),
    args,
  );

  if (context != null) {
    print('Security example started: ${context.getDisplayName()}');
  }
}

@EnableWebSecurity()
@EnableMethodSecurity(
  prePostEnabled: true,
  securedEnabled: true,
  jsr250Enabled: true,
)
@JetleafApplicationStarter()
class SecurityDemoApplication {}
