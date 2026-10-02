import 'package:jetleaf/jetleaf.dart';
import 'package:jetleaf_resource/jetleaf_resource.dart';
import 'package:jetleaf_web/jetleaf_web.dart';
import 'package:supabase/supabase.dart';

Future<void> main(List<String> args) async {
  final context = await JetleafApplication.run(BuilderApplication(), args);
  if (context != null) {
    print("Application is up and running");
  }
}

@Configuration()
@EnableResource()
@Author("Evaristus")
@JetleafApplicationStarter()
final class BuilderApplication {
  const BuilderApplication();

  @Pod()
  CorsConfiguration corsConfiguration() {
    final valueString = Env<String>("ALLOWED_ORIGINS").value();
    final values = valueString.split(", ");
    return CorsConfiguration(allowedOrigins: values);
  }

  @Pod()
  SupabaseClient supabaseClient() {
    final supabaseUrl = Env<String>("SUPABASE_URL").value();
    final supabaseKey = Env<String>("SUPABASE_KEY").value();
    return SupabaseClient(supabaseUrl, supabaseKey);
  }
}