import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';
import 'package:server/webhook_handler.dart';

void main() async {
  final router = Router();

  router.all('/webhook', (request) {
    return handleWebhook(request);
  });

  final handler = const Pipeline().addHandler(router.call);

  final server = await io.serve(handler, 'localhost', 8080);
  // ignore: avoid_print
  print('Server listening on port ${server.port}');
}
