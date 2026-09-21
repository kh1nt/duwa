import 'package:duwa/models/game_night_model.dart';
import 'package:duwa/models/group_model.dart';
import 'package:duwa/services/firebase_service.dart';
import 'package:duwa/viewmodels/groups_viewmodel.dart';
import 'package:duwa/views/common/gmail_logo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SSO, Gmail Logo, and Short Squad Codes Tests', () {
    testWidgets('GmailLogoWidget renders vector canvas without exception', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: GmailLogoWidget(size: 24),
            ),
          ),
        ),
      );
      expect(find.byType(GmailLogoWidget), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
    });

    test('generateSquadCode produces arcade-style short codes (SQ-XXXX)', () {
      final code = FirebaseService().generateSquadCode();
      expect(code.startsWith('SQ-'), isTrue);
      expect(code.length, equals(7)); // 'SQ-' + 4 chars
      final suffix = code.substring(3);
      expect(RegExp(r'^[A-Z0-9]{4}$').hasMatch(suffix), isTrue);
    });

    test('GamerGroupModel.displaySquadCode uses squadCode or generates short fallback', () {
      const groupWithCode = GamerGroupModel(
        id: 'long-group-uuid-12345678',
        name: 'Alpha Crew',
        tagline: 'Gaming',
        iconEmoji: '🔥',
        members: [],
        squadCode: 'SQ-99Z1',
      );
      expect(groupWithCode.displaySquadCode, equals('SQ-99Z1'));

      const groupWithoutCode = GamerGroupModel(
        id: 'group987654321',
        name: 'Beta Squad',
        tagline: 'Casual',
        iconEmoji: '🎮',
        members: [],
      );
      expect(groupWithoutCode.displaySquadCode, equals('SQ-GROU'));
    });

    test('GameNightModel.displayRoomCode standardizes to DUWA-XXXX format', () {
      final session = GameNightModel(
        id: 'session-id-4567',
        title: 'Friday Night LAN',
        group: const GamerGroupModel(
          id: 'g1',
          name: 'Crew',
          tagline: '',
          iconEmoji: '🎮',
          members: [],
        ),
        organizerName: 'Host',
        scheduledDateTime: DateTime.now(),
        formattedDate: 'Friday, Oct 10',
        formattedTime: '8:00 PM',
        status: GameNightStatus.ready,
        players: const [],
      );
      expect(session.displayRoomCode, equals('DUWA-SESS'));
    });

    test('GroupsViewModel generates short squadCode on addGroup', () {
      final vm = GroupsViewModel();
      vm.addGroup(name: 'Viper Crew', tagline: 'Competitive', emoji: '🐍');

      expect(vm.groups.isNotEmpty, isTrue);
      final newSquad = vm.groups.first;
      expect(newSquad.name, equals('Viper Crew'));
      expect(newSquad.squadCode, isNotNull);
      expect(newSquad.squadCode!.startsWith('SQ-'), isTrue);
      expect(newSquad.squadCode!.length, equals(7));
      expect(newSquad.displaySquadCode, equals(newSquad.squadCode));
    });

    test('GroupsViewModel addMemberToSquad enforces member uniqueness and preserves IDs', () async {
      final vm = GroupsViewModel();
      vm.addGroup(name: 'Raid Team', tagline: 'MMO', emoji: '⚔️');
      final squadId = vm.groups.first.id;

      final added = await vm.addMemberToSquad(
        squadId: squadId,
        memberName: 'Valkyrie',
        userId: 'user-valk-123',
        username: '@valk_wings',
        avatarEmoji: '⚡',
      );
      expect(added, isTrue);
      expect(vm.groups.first.members.any((m) => m.name == 'Valkyrie'), isTrue);
      expect(vm.groups.first.memberUids.contains('user-valk-123'), isTrue);

      // Duplicate addition should be rejected
      final duplicate = await vm.addMemberToSquad(
        squadId: squadId,
        memberName: 'Valkyrie',
      );
      expect(duplicate, isFalse);
    });
  });
}
