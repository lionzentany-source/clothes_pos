import 'dart:convert';
import 'package:shelf/shelf.dart';

Future<Response> handleWebhook(Request request) async {
  if (request.method == 'GET') {
    return _handleVerification(request);
  } else if (request.method == 'POST') {
    return _handleEvent(request);
  } else {
    return Response(405);
  }
}

Response _handleVerification(Request request) {
  final hubMode = request.url.queryParameters['hub.mode'];
  final hubChallenge = request.url.queryParameters['hub.challenge'];
  final hubVerifyToken = request.url.queryParameters['hub.verify_token'];

  // TODO: Get verifyToken from a secure config
  const verifyToken = 'YOUR_VERIFY_TOKEN'; // Replace with your verify token

  if (hubMode == 'subscribe' && hubVerifyToken == verifyToken) {
    return Response.ok(hubChallenge);
  } else {
    return Response.forbidden('Invalid verification token');
  }
}

Future<Response> _handleEvent(Request request) async {
  final body = await request.readAsString();
  final data = jsonDecode(body);

  if (data['object'] == 'page') {
    for (final entry in data['entry']) {
      for (final message in entry['messaging']) {
        // TODO: Process the message
        // ignore: avoid_print
        print('Received message: $message');
      }
    }
  }

  return Response.ok('EVENT_RECEIVED');
}
