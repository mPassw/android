import 'package:hive_ce/hive.dart';
import 'package:mpass/dashboard/navigation/passwords/model/password.dart';

part 'hive_adapters.g.dart';

@GenerateAdapters([AdapterSpec<Password>()])
void _() {}
