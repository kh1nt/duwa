import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/duwa_theme.dart';
import '../../models/game_night_model.dart';
import '../../viewmodels/game_night_viewmodel.dart';
import '../common/bouncy_tap.dart';
import '../common/duwa_buttons.dart';

/// Modal bottom sheet for organizers to edit an existing game night session's details:
/// title, date & time, host note, location, and Discord/voice channel URL.
class EditGameNightSheet extends StatefulWidget {
  final GameNightModel session;
  final GameNightViewModel gameNightVm;
  final DuwaThemeData duwaTheme;

  const EditGameNightSheet({
    super.key,
    required this.session,
    required this.gameNightVm,
    required this.duwaTheme,
  });

  static Future<void> show(
    BuildContext context, {
    required GameNightModel session,
    required GameNightViewModel gameNightVm,
    required DuwaThemeData duwaTheme,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: duwaTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => EditGameNightSheet(
        session: session,
        gameNightVm: gameNightVm,
        duwaTheme: duwaTheme,
      ),
    );
  }

  @override
  State<EditGameNightSheet> createState() => _EditGameNightSheetState();
}

class _EditGameNightSheetState extends State<EditGameNightSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _noteController;
  late final TextEditingController _locationController;
  late final TextEditingController _voiceController;

  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final s = widget.session;
    _titleController = TextEditingController(text: s.title);
    _noteController = TextEditingController(text: s.description);
    _locationController = TextEditingController(text: s.location?.name ?? '');
    _voiceController = TextEditingController(text: s.voiceChannelUrl ?? '');

    _selectedDate = s.scheduledDateTime ?? DateTime.now().add(const Duration(hours: 4));
    
    if (s.scheduledDateTime != null) {
      _selectedTime = TimeOfDay(
        hour: s.scheduledDateTime!.hour,
        minute: s.scheduledDateTime!.minute,
      );
    } else {
      _selectedTime = const TimeOfDay(hour: 20, minute: 0);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _noteController.dispose();
    _locationController.dispose();
    _voiceController.dispose();
    super.dispose();
  }

  String _formatDateString(DateTime date) {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${weekdays[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}';
  }

  String _formatTimeString(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.dark(
            primary: widget.duwaTheme.primaryAccent,
            surface: widget.duwaTheme.surface,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (ctx, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.dark(
            primary: widget.duwaTheme.primaryAccent,
            surface: widget.duwaTheme.surface,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  void _saveChanges() {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please provide a session title')),
      );
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() => _isLoading = true);

    final fullDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    final timeStr = _formatTimeString(_selectedTime);

    widget.gameNightVm.updateSessionDetails(
      widget.session.id,
      title: title,
      description: _noteController.text.trim(),
      scheduledDateTime: fullDateTime,
      formattedTime: timeStr,
      voiceChannelUrl: _voiceController.text.trim(),
      locationName: _locationController.text.trim(),
    );

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Session details updated! 🎮')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.duwaTheme;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, bottomInset + 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: t.cardBorder,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Sheet Title
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: t.primaryAccent.withAlpha(25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.tune_rounded, color: t.primaryAccent, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Edit Session Details',
                        style: TextStyle(
                          color: t.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                      Text(
                        'Update schedule, venue, host notes, and voice channel',
                        style: TextStyle(color: t.textMuted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: t.textMuted, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Session Title Input
            _buildLabel('SESSION TITLE', t),
            const SizedBox(height: 6),
            _buildTextField(
              controller: _titleController,
              hint: 'e.g. Friday Ranked Grind',
              icon: Icons.sports_esports_rounded,
              t: t,
            ),
            const SizedBox(height: 16),

            // Date & Time Row
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('DATE', t),
                      const SizedBox(height: 6),
                      BouncyTap(
                        onTap: _pickDate,
                        child: _buildPickerTile(
                          icon: Icons.calendar_today_rounded,
                          text: _formatDateString(_selectedDate),
                          t: t,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('START TIME', t),
                      const SizedBox(height: 6),
                      BouncyTap(
                        onTap: _pickTime,
                        child: _buildPickerTile(
                          icon: Icons.access_time_rounded,
                          text: _formatTimeString(_selectedTime),
                          t: t,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Voice Channel / Party Room URL
            _buildLabel('DISCORD VOICE / PARTY LINK', t),
            const SizedBox(height: 6),
            _buildTextField(
              controller: _voiceController,
              hint: 'https://discord.gg/... or Meet link',
              icon: Icons.headset_mic_rounded,
              t: t,
            ),
            const SizedBox(height: 16),

            // Location / Venue
            _buildLabel('VENUE / LOCATION', t),
            const SizedBox(height: 6),
            _buildTextField(
              controller: _locationController,
              hint: 'Discord Voice #1 or banilad crib',
              icon: Icons.place_rounded,
              t: t,
            ),
            const SizedBox(height: 16),

            // Host Note
            _buildLabel('HOST NOTE / COZY RITUAL', t),
            const SizedBox(height: 6),
            _buildTextField(
              controller: _noteController,
              hint: 'Bring snacks, energy drinks & good vibes only ☕',
              icon: Icons.coffee_rounded,
              maxLines: 2,
              t: t,
            ),
            const SizedBox(height: 24),

            // Save CTA
            DuwaButton(
              label: 'Save Changes',
              icon: Icons.check_circle_rounded,
              isFullWidth: true,
              isLoading: _isLoading,
              onPressed: _saveChanges,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text, DuwaThemeData t) {
    return Text(
      text,
      style: TextStyle(
        color: t.textSecondary,
        fontSize: 10.5,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.0,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required DuwaThemeData t,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: t.surfaceHighest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: t.cardBorder, width: 1),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: Row(
        crossAxisAlignment: maxLines > 1 ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Padding(
            padding: EdgeInsets.only(top: maxLines > 1 ? 12 : 0),
            child: Icon(icon, size: 18, color: t.primaryAccent),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              maxLines: maxLines,
              style: TextStyle(
                color: t.textPrimary,
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(
                  color: t.textMuted.withAlpha(140),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPickerTile({
    required IconData icon,
    required String text,
    required DuwaThemeData t,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: t.surfaceHighest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: t.cardBorder, width: 1),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Row(
        children: [
          Icon(icon, size: 16, color: t.primaryAccent),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: t.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: t.textMuted),
        ],
      ),
    );
  }
}
