import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/game_night_model.dart';
import '../models/group_model.dart';

/// Lightweight Discord Webhook Dispatcher
/// Allows squads to broadcast rich embed session cards directly into their Discord channels
class DiscordService {
  static final DiscordService _instance = DiscordService._internal();
  factory DiscordService() => _instance;
  DiscordService._internal();

  /// Validates if a string is a valid Discord Webhook URL
  bool isValidWebhookUrl(String? url) {
    if (url == null || url.trim().isEmpty) return false;
    final clean = url.trim().toLowerCase();
    return clean.startsWith('https://discord.com/api/webhooks/') ||
        clean.startsWith('https://discordapp.com/api/webhooks/');
  }

  /// Sends a rich session announcement embed to the Discord Webhook
  Future<bool> sendSessionAnnouncement({
    required String webhookUrl,
    required GameNightModel session,
  }) async {
    if (!isValidWebhookUrl(webhookUrl)) {
      debugPrint('Invalid Discord webhook URL provided: $webhookUrl');
      return false;
    }

    try {
      final isVoting = session.status == GameNightStatus.voting;
      final gameDisplay = session.selectedGame?.title ??
          (isVoting
              ? '🗳️ Voting in Progress (${session.votingGames.length} games on ballot)'
              : 'TBD');

      final goingList = session.players
          .where((p) => p.rsvp == RSVPStatus.going)
          .map((p) => p.name)
          .join(', ');
      final rosterText = goingList.isNotEmpty ? goingList : 'Be the first to confirm!';

      final payload = {
        'content': '📢 **Squad Session Briefing!**',
        'embeds': [
          {
            'title': '🎮 ${session.title}',
            'description': 'Organized by **${session.organizerName ?? "Squad"}** for **${session.group.name}**.',
            'color': 0x6366F1, // Blurple / Indigo
            'fields': [
              {
                'name': '📅 Schedule',
                'value': '${session.formattedDate} at ${session.formattedTime}',
                'inline': true,
              },
              {
                'name': '📍 Voice Channel / Venue',
                'value': session.location?.name ?? 'Discord Voice #1',
                'inline': true,
              },
              {
                'name': '🕹️ Game',
                'value': gameDisplay,
                'inline': false,
              },
              {
                'name': '👥 Confirmed (${session.goingCount})',
                'value': rosterText,
                'inline': false,
              },
              {
                'name': '🔑 Join Code in DUWA',
                'value': '`${session.displayRoomCode}`',
                'inline': true,
              },
            ],
            'footer': {
              'text': 'DUWA · Squad Gaming Hub',
            },
            'timestamp': DateTime.now().toIso8601String(),
          }
        ],
      };

      final response = await http.post(
        Uri.parse(webhookUrl.trim()),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      // Discord webhook returns 204 No Content on success
      if (response.statusCode >= 200 && response.statusCode < 300) {
        debugPrint('Discord webhook dispatch success (${response.statusCode})');
        return true;
      } else {
        debugPrint('Discord webhook error (${response.statusCode}): ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('Discord webhook exception: $e');
      return false;
    }
  }
}
