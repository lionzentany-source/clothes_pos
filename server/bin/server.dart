import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';
import 'package:server/webhook_handler.dart';

void main() async {
  final router = Router();

  router.all('/webhook', handleWebhook);

  final handler = const Pipeline().addHandler(router);

  final server = await io.serve(handler, 'localhost', 8080);
  print('Server listening on port ${server.port}');
}