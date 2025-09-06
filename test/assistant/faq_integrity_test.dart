import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:clothes_pos/assistant/faq_data.dart';

void main() {
  group('FAQ integrity', () {
    test('ids are unique', () {
      final ids = allFaq().map((e) => e.id).toList();
      final dupes = ids
          .where((id) => ids.where((o) => o == id).length > 1)
          .toSet();
      expect(dupes, isEmpty, reason: 'Duplicate faq ids found: $dupes');
    });

    test('related questions reference existing ids', () {
      final idSet = allFaq().map((e) => e.id).toSet();
      for (final e in allFaq()) {
        if (e.relatedQuestions == null) continue;
        for (final rel in e.relatedQuestions!) {
          expect(
            idSet.contains(rel),
            isTrue,
            reason: 'FAQ ${e.id} references non-existent related id $rel',
          );
        }
      }
    });

    test('image assets exist (where specified)', () {
      for (final e in allFaq()) {
        if (e.imageUrl == null) continue;
        final file = File(e.imageUrl!);
        expect(
          file.existsSync(),
          isTrue,
          reason: 'Missing image asset for ${e.id}: ${e.imageUrl}',
        );
      }
    });

    test('basic Arabic content sanity', () {
      for (final e in allFaq()) {
        expect(
          e.question.trim().isNotEmpty,
          isTrue,
          reason: '${e.id} empty question',
        );
        expect(
          e.answer.trim().isNotEmpty,
          isTrue,
          reason: '${e.id} empty answer',
        );
        // Ensure predominant Arabic letters presence in at least question or answer
        final arabicLetters = RegExp(r'[\u0621-\u064A]');
        final hasArabic =
            arabicLetters.hasMatch(e.question) ||
            arabicLetters.hasMatch(e.answer);
        expect(
          hasArabic,
          isTrue,
          reason: '${e.id} appears to lack Arabic letters',
        );
      }
    });

    test('checksum (update when intentional change)', () {
      final buffer = StringBuffer();
      for (final e in allFaq()) {
        buffer
          ..write(e.id)
          ..write('|')
          ..write(e.question)
          ..write('|')
          ..writeln(e.answer);
      }
      final bytes = utf8.encode(buffer.toString());
      final hash = sha256.convert(bytes).toString();
      // Update this value intentionally when FAQ content changes
      const expected =
          '9f4bf9a5318a5fad667fd8a7671ae4078e88ad842fcd791db5c662eebe87065f';
      if (hash != expected) {
        // Print helpful message for developer to update expected value intentionally
        // ignore: avoid_print
        print('FAQ checksum changed. New value: $hash');
      }
      expect(
        hash,
        expected,
        reason:
            'FAQ content changed. If intentional, update expected checksum.',
      );
    });
  });
}
