import 'package:flutter_test/flutter_test.dart';
import 'package:clothes_pos/core/services/facebook_api_service.dart';
import 'package:clothes_pos/presentation/settings/bloc/settings_cubit.dart';
import 'package:mockito/mockito.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:clothes_pos/core/config/constants.dart';

class FakeClient extends http.BaseClient {
  final Future<http.Response> Function(http.BaseRequest) _handler;
  FakeClient(this._handler);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final resp = await _handler(request);
    final stream = Stream.value(resp.bodyBytes);
    return http.StreamedResponse(
      stream,
      resp.statusCode,
      headers: resp.headers,
    );
  }
}

class FakeSettingsCubit extends Mock implements SettingsCubit {
  final SettingsState _state;
  FakeSettingsCubit(this._state);

  @override
  SettingsState get state => _state;
}

void main() {
  group('FacebookApiService', () {
    late FacebookApiService service;
    late FakeClient mockClient;
    late FakeSettingsCubit mockSettingsCubit;

    setUp(() {
      mockSettingsCubit = FakeSettingsCubit(
        const SettingsState(
          currency: 'USD',
          facebookPageAccessToken: 'dummy_token',
          facebookPageId: 'dummy_page_id',
        ),
      );

      // create a fake client that will be configured per-test
      mockClient = FakeClient((_) async => http.Response('{}', 200));

      service = FacebookApiService(mockSettingsCubit, client: mockClient);
    });

    test('fetchNewMessages returns parsed messages from mock', () async {
      final fakeResponse = {
        'data': [
          {
            'id': 'conv1',
            'messages': {
              'data': [
                {
                  'id': 'msg1',
                  'message': 'Hello!',
                  'created_time': DateTime.now().toIso8601String(),
                  'from': {'id': 'user1'},
                },
              ],
            },
          },
        ],
      };

      final uri = Uri.parse(
        'https://graph.facebook.com/${ApiConstants.facebookApiVersion}/dummy_page_id/conversations?fields=messages{from,message,created_time,id}&access_token=dummy_token',
      );
      // replace handler to return desired fake response for this test
      mockClient = FakeClient((request) async {
        if (request.url == uri) {
          return http.Response(
            jsonEncode(fakeResponse),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('{}', 404);
      });
      service = FacebookApiService(mockSettingsCubit, client: mockClient);

      final messages = await service.fetchNewMessages(
        DateTime.now().subtract(const Duration(days: 1)),
      );
      expect(messages, isList);
      expect(messages.length, 1);
      expect(messages.first.messageText, 'Hello!');
    });
  });
}
