import 'package:flutter/material.dart';
import 'dart:async';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../widgets/glass_card.dart';
import '../theme/app_theme.dart';
import '../services/notification_service.dart';
import '../widgets/animated_button.dart';
import 'dart:math' as math;
import '../services/reminder_service.dart';
import 'package:provider/provider.dart';
import '../models/reminder_model.dart';
import '../widgets/glowing_icon_button.dart';

// Renamed from NotificationScreen to AlertsScreen
class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _AlertsScreenState();
}

// Renamed from _NotificationScreenState to _AlertsScreenState
class _AlertsScreenState extends State<NotificationScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  final NotificationService _notificationService = NotificationService();
  Timer? _refreshTimer;
  late ReminderService _reminderService;
  bool _isLoading = false;
  List<Reminder> _reminders = [];
  
  // List of preset workout reminders that can be scheduled
  final List<Map<String, dynamic>> _presetReminders = [
    {
      'title': 'Morning Run',
      'message': 'Time for your morning run! Get ready for a great start to your day.',
      'time': TimeOfDay(hour: 7, minute: 0),
      'type': 'workout',
      'icon': FontAwesomeIcons.personRunning,
      'color': Colors.blue,
    },
    {
      'title': 'Drink Water',
      'message': 'Stay hydrated! Remember to drink a glass of water.',
      'time': TimeOfDay(hour: 10, minute: 0),
      'type': 'water',
      'icon': FontAwesomeIcons.droplet,
      'color': Colors.cyan,
    },
    {
      'title': 'Stand Up',
      'message': 'Time to get up and stretch for a few minutes.',
      'time': TimeOfDay(hour: 14, minute: 0),
      'type': 'other',
      'icon': FontAwesomeIcons.personWalking,
      'color': Colors.green,
    },
    {
      'title': 'Evening Workout',
      'message': 'Don\'t forget your evening strength workout.',
      'time': TimeOfDay(hour: 18, minute: 30),
      'type': 'workout',
      'icon': FontAwesomeIcons.dumbbell,
      'color': Colors.purple,
    },
    {
      'title': 'Sleep Time',
      'message': 'Time to wind down and prepare for sleep.',
      'time': TimeOfDay(hour: 22, minute: 0),
      'type': 'other',
      'icon': FontAwesomeIcons.bed,
      'color': Colors.indigo,
    },
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animationController.forward();
    
    // Initialize notification service
    _notificationService.initialize();
    
    // Initialize reminder service
    _reminderService = Provider.of<ReminderService>(context, listen: false);
    _loadReminders();
    
    // Don't automatically create demo timers
    // _createDemoTimers();
    
    // Refresh UI every second to update timers
    _refreshTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
    
    // Listen for notification changes
    _notificationService.addListener(_updateState);
  }
  
  void _updateState() {
    if (mounted) setState(() {});
  }
  
  // Method to create demo timers if needed - not called automatically
  void _createDemoTimers() {
    _notificationService.createDemoTimers();
  }

  // Load reminders from the service
  Future<void> _loadReminders() async {
    setState(() {
      _isLoading = true;
    });
    
    await _reminderService.loadReminders();
    
    setState(() {
      _reminders = _reminderService.reminders;
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _refreshTimer?.cancel();
    _notificationService.dispose();
    super.dispose();
  }

  // Show add reminder dialog
  void _showAddReminderDialog(BuildContext context) {
    String title = 'Workout Reminder';
    String message = 'Time for your workout!';
    String reminderType = 'workout';
    TimeOfDay selectedTime = TimeOfDay.now();
    
    final reminderTypes = ['workout', 'water', 'medication', 'meal', 'other'];
    
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Colors.grey[900],
              title: const Text('Add Reminder'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      decoration: InputDecoration(
                        labelText: 'Title',
                        filled: true,
                        fillColor: Colors.grey[800],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      style: const TextStyle(color: Colors.white),
                      onChanged: (value) {
                        title = value.isNotEmpty ? value : 'Workout Reminder';
                      },
                      controller: TextEditingController(text: title),
                    ),
                    const SizedBox(height: 16),
                    
                    TextField(
                      decoration: InputDecoration(
                        labelText: 'Message',
                        filled: true,
                        fillColor: Colors.grey[800],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      style: const TextStyle(color: Colors.white),
                      onChanged: (value) {
                        message = value.isNotEmpty ? value : 'Time for your workout!';
                      },
                      controller: TextEditingController(text: message),
                    ),
                    const SizedBox(height: 16),
                    
                    // Reminder type dropdown
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'Reminder Type',
                        filled: true,
                        fillColor: Colors.grey[800],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      style: const TextStyle(color: Colors.white),
                      dropdownColor: Colors.grey[800],
                      value: reminderType,
                      items: reminderTypes
                          .map((type) => DropdownMenuItem(
                                value: type,
                                child: Text(type.capitalize()),
                              ))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            reminderType = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Time picker button
                    GestureDetector(
                      onTap: () async {
                        final TimeOfDay? time = await showTimePicker(
                          context: context,
                          initialTime: selectedTime,
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: const ColorScheme.dark(
                                  primary: AppTheme.primaryColor,
                                  onPrimary: Colors.black,
                                  surface: Colors.grey,
                                  onSurface: Colors.white,
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        
                        if (time != null) {
                          setState(() {
                            selectedTime = time;
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey[800],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Reminder Time',
                              style: TextStyle(
                                color: Colors.white70,
                              ),
                            ),
                            Text(
                              '${selectedTime.hour > 12 ? selectedTime.hour - 12 : selectedTime.hour == 0 ? 12 : selectedTime.hour}:${selectedTime.minute.toString().padLeft(2, '0')} ${selectedTime.hour >= 12 ? 'PM' : 'AM'}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancel'),
                ),
                AnimatedGlowButton(
                  text: 'Add',
                  onPressed: () async {
                    // Create a DateTime for the selected time
                    final now = DateTime.now();
                    DateTime reminderDateTime = DateTime(
                      now.year,
                      now.month,
                      now.day,
                      selectedTime.hour,
                      selectedTime.minute,
                    );
                    
                    // If the time is in the past, schedule it for tomorrow
                    if (reminderDateTime.isBefore(now)) {
                      reminderDateTime = reminderDateTime.add(const Duration(days: 1));
                    }
                    
                    // Add reminder
                    await _reminderService.addReminder(
                      title: title,
                      message: message,
                      reminderTime: reminderDateTime,
                      type: reminderType,
                    );
                    
                    // Reload reminders
                    _loadReminders();
                    
                    Navigator.of(context).pop();
                  },
                  color: AppTheme.primaryColor,
                  textColor: Colors.black,
                  width: 100,
                  height: 40,
                  addCloudyHover: true,
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get the active timers and scheduled notifications
    final activeTimers = _notificationService.getActiveTimers();
    final scheduledNotifications = _notificationService.getScheduledNotifications();
    
    return Scaffold(
      body: FadeTransition(
        opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOut,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(top: 80, left: 16.0, right: 16.0, bottom: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Active timers section
              if (activeTimers.isNotEmpty) ...[
                const Text(
                  'Active Timers',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: activeTimers.length,
                  itemBuilder: (context, index) {
                    final timer = activeTimers[index];
                    return _buildTimerCard(timer);
                  },
                ),
                const SizedBox(height: 24),
              ],
              
              // Scheduled workouts section
              const Text(
                'Workout Reminders',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildWorkoutReminders(),
              
              const SizedBox(height: 24),
              
              // Quick actions
              const Text(
                'Quick Actions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildQuickActions(),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildTimerCard(Map<String, dynamic> timer) {
    final id = timer['id'];
    final title = timer['title'];
    final progress = _notificationService.getTimerProgress(id);
    final remainingTime = _notificationService.formatRemainingTime(id);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: GlassCard(
        borderRadius: 16,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  remainingTime,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Progress bar
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[800],
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () {
                    _notificationService.cancelNotification(id);
                  },
                  icon: const Icon(Icons.cancel, size: 16),
                  label: const Text('Cancel'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildWorkoutReminders() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (_reminders.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.notifications_off,
              size: 64,
              color: Colors.grey[600],
            ),
            const SizedBox(height: 16),
            Text(
              'No reminders set',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 24),
            AnimatedGlowButton(
              text: 'Add Reminder',
              onPressed: () => _showAddReminderDialog(context),
              color: AppTheme.primaryColor,
              textColor: Colors.black,
              width: 160,
              height: 45,
              addCloudyHover: true,
            ),
            const SizedBox(height: 24),
            const Text(
              'Preset Reminders',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildPresetReminders(),
          ],
        ),
      );
    }
    
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _reminders.length + 1, // +1 for the preset reminders section
      itemBuilder: (context, index) {
        if (index == _reminders.length) {
          // Last item is the preset reminders section
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Text(
                  'Preset Reminders',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              _buildPresetReminders(),
            ],
          );
        }
        
        final reminder = _reminders[index];
        
        // Format time for display
        final reminderTime = reminder.reminderTime;
        final hour = reminderTime.hour % 12 == 0 ? 12 : reminderTime.hour % 12;
        final minute = reminderTime.minute.toString().padLeft(2, '0');
        final period = reminderTime.hour >= 12 ? 'PM' : 'AM';
        final timeString = '$hour:$minute $period';
        
        // Get icon and color based on reminder type
        IconData icon = Icons.notifications;
        Color color = Colors.blue;
        
        switch (reminder.type) {
          case 'workout':
            icon = FontAwesomeIcons.dumbbell;
            color = Colors.purple;
            break;
          case 'water':
            icon = FontAwesomeIcons.droplet;
            color = Colors.blue;
            break;
          case 'medication':
            icon = FontAwesomeIcons.pills;
            color = Colors.red;
            break;
          case 'meal':
            icon = FontAwesomeIcons.utensils;
            color = Colors.green;
            break;
          default:
            icon = FontAwesomeIcons.bell;
            color = Colors.orange;
        }
        
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: GlassCard(
            borderRadius: 16,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                GlowingContainer(
                  glowColor: color,
                  height: 50,
                  width: 50,
                  borderRadius: 25,
                  padding: EdgeInsets.zero,
                  glowIntensity: reminder.isActive ? 0.5 : 0.1,
                  child: Center(
                    child: FaIcon(
                      icon,
                      color: color,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reminder.title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: reminder.isActive ? Colors.white : Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Make time clickable to change
                      GestureDetector(
                        onTap: () => _showTimePickerDialogForReminder(context, reminder),
                        child: Row(
                          children: [
                            Text(
                              timeString,
                              style: TextStyle(
                                color: reminder.isActive ? Colors.grey[400] : Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.edit,
                              size: 12,
                              color: reminder.isActive ? Colors.grey[400] : Colors.grey[600],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        reminder.message,
                        style: TextStyle(
                          color: reminder.isActive ? Colors.grey[400] : Colors.grey[600],
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    GlowingIconButton(
                      icon: Icons.delete,
                      onPressed: () => _showDeleteReminderDialog(reminder),
                      size: 20,
                      color: Colors.red,
                    ),
                    const SizedBox(width: 8),
                    Switch(
                      value: reminder.isActive,
                      onChanged: (value) async {
                        await _reminderService.toggleReminderActive(reminder.id!, value);
                        _loadReminders();
                      },
                      activeColor: AppTheme.primaryColor,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child: GlassCard(
            borderRadius: 16,
            padding: const EdgeInsets.all(16),
            onTap: () {
              // Schedule a quick workout reminder
              _scheduleQuickReminder();
            },
            child: Stack(
              children: [
                // Add cloudy hover effect
                Positioned.fill(
                  child: CustomPaint(
                    painter: CloudyEffectPainter(
                      color: AppTheme.primaryColor,
                      animationValue: 0.5,
                    ),
                  ),
                ),
                Column(
                  children: [
                    Icon(
                      Icons.timer,
                      size: 32,
                      color: AppTheme.primaryColor,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Quick Timer',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: GlassCard(
            borderRadius: 16,
            padding: const EdgeInsets.all(16),
            onTap: () {
              // Cancel all timers and notifications
              _notificationService.cancelAllNotifications();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('All timers and notifications cleared'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: Stack(
              children: [
                // Add cloudy hover effect
                Positioned.fill(
                  child: CustomPaint(
                    painter: CloudyEffectPainter(
                      color: Colors.redAccent,
                      animationValue: 0.5,
                    ),
                  ),
                ),
                Column(
                  children: [
                    const Icon(
                      Icons.clear_all,
                      size: 32,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Clear All',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
  
  void _scheduleQuickReminder() {
    // Show a dialog to set a quick timer
    showDialog(
      context: context,
      builder: (context) {
        int minutes = 5; // Default 5 minutes
        String workoutName = 'Quick Workout';
        bool startWorkoutAutomatically = true;
        
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Colors.grey[900],
              title: const Text('Set Quick Timer'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Set a timer duration (minutes):'),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: () {
                          if (minutes > 1) {
                            setState(() {
                              minutes--;
                            });
                          }
                        },
                        icon: const Icon(Icons.remove),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$minutes',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          setState(() {
                            minutes++;
                          });
                        },
                        icon: const Icon(Icons.add),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'Workout Name',
                      filled: true,
                      fillColor: Colors.grey[800],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    style: const TextStyle(color: Colors.white),
                    onChanged: (value) {
                      workoutName = value.isNotEmpty ? value : 'Quick Workout';
                    },
                    controller: TextEditingController(text: workoutName),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Checkbox(
                        value: startWorkoutAutomatically,
                        onChanged: (value) {
                          setState(() {
                            startWorkoutAutomatically = value ?? true;
                          });
                        },
                        activeColor: AppTheme.primaryColor,
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Start workout automatically when timer finishes',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancel'),
                ),
                AnimatedGlowButton(
                  text: 'Start',
                  onPressed: () {
                    // Create a unique ID for this timer
                    final id = DateTime.now().millisecondsSinceEpoch;
                    
                    // Set the timer
                    _notificationService.setWorkoutTimer(
                      workoutName,
                      Duration(minutes: minutes),
                    );
                    
                    // If auto-start is enabled, schedule a workout to start when timer finishes
                    if (startWorkoutAutomatically) {
                      // Schedule the notification to start the workout
                      final scheduledTime = DateTime.now().add(Duration(minutes: minutes));
                      _notificationService.scheduleWorkoutReminder(
                        id: id,
                        title: 'Start $workoutName',
                        body: 'Your timer is complete. Time to start your workout!',
                        scheduledTime: scheduledTime,
                      );
                      
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('$workoutName will automatically start in $minutes minutes'),
                          duration: const Duration(seconds: 3),
                        ),
                      );
                    }
                    
                    Navigator.of(context).pop();
                  },
                  color: AppTheme.primaryColor,
                  textColor: Colors.black,
                  width: 100,
                  height: 40,
                  addCloudyHover: true,
                ),
              ],
            );
          },
        );
      },
    );
  }
  
  // Show delete reminder dialog
  void _showDeleteReminderDialog(Reminder reminder) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Delete Reminder'),
        content: Text('Are you sure you want to delete "${reminder.title}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (reminder.id != null) {
                await _reminderService.deleteReminder(reminder.id!);
                // Reload reminders
                _loadReminders();
                
                // Show confirmation
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${reminder.title} has been deleted'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
              if (mounted) {
                Navigator.pop(context);
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
  
  // Show time picker dialog for changing reminder time
  void _showTimePickerDialogForReminder(BuildContext context, Reminder reminder) async {
    final initialTime = TimeOfDay(
      hour: reminder.reminderTime.hour,
      minute: reminder.reminderTime.minute,
    );
    
    final selectedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppTheme.primaryColor,
              onPrimary: Colors.black,
              surface: Colors.grey,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (selectedTime != null) {
      // Create a new DateTime with the selected time
      final now = DateTime.now();
      final newDateTime = DateTime(
        now.year,
        now.month,
        now.day,
        selectedTime.hour,
        selectedTime.minute,
      );
      
      // Update the reminder
      await _reminderService.updateReminder(
        id: reminder.id!,
        reminderTime: newDateTime,
      );
      
      // Reload reminders
      _loadReminders();
    }
  }
  
  // Build preset reminders section
  Widget _buildPresetReminders() {
    return Container(
      height: 120,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _presetReminders.length,
        itemBuilder: (context, index) {
          final preset = _presetReminders[index];
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () => _addPresetReminder(preset),
              child: Container(
                width: 100,
                decoration: BoxDecoration(
                  color: Colors.grey[850],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: preset['color'],
                    width: 1,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FaIcon(
                      preset['icon'],
                      color: preset['color'],
                      size: 24,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      preset['title'],
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${preset['time'].hour > 12 ? preset['time'].hour - 12 : preset['time'].hour == 0 ? 12 : preset['time'].hour}:${preset['time'].minute.toString().padLeft(2, '0')} ${preset['time'].hour >= 12 ? 'PM' : 'AM'}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[400],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
  
  // Add preset reminder
  Future<void> _addPresetReminder(Map<String, dynamic> preset) async {
    // Create a DateTime for the selected time
    final now = DateTime.now();
    DateTime reminderDateTime = DateTime(
      now.year,
      now.month,
      now.day,
      preset['time'].hour,
      preset['time'].minute,
    );
    
    // If the time is in the past, schedule it for tomorrow
    if (reminderDateTime.isBefore(now)) {
      reminderDateTime = reminderDateTime.add(const Duration(days: 1));
    }
    
    // Add reminder
    final success = await _reminderService.addReminder(
      title: preset['title'],
      message: preset['message'],
      reminderTime: reminderDateTime,
      type: preset['type'],
    );
    
    if (success) {
      // Reload reminders
      _loadReminders();
      
      // Show confirmation
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${preset['title']} reminder added'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }
}

class CloudyEffectPainter extends CustomPainter {
  final Color color;
  final double animationValue;
  
  CloudyEffectPainter({
    required this.color,
    required this.animationValue,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(42); // Fixed seed for consistency
    final numClouds = 5;
    
    for (int i = 0; i < numClouds; i++) {
      final offsetX = random.nextDouble() * size.width;
      final offsetY = random.nextDouble() * size.height;
      final radius = size.width * 0.1 * (0.5 + random.nextDouble());
      
      // Calculate oscillating opacity based on animation value
      final phase = (i / numClouds) * 2 * math.pi;
      final opacity = 0.1 + 0.1 * math.sin(animationValue * 2 * math.pi + phase);
      
      final paint = Paint()
        ..color = color.withOpacity(opacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);
      
      canvas.drawCircle(Offset(offsetX, offsetY), radius, paint);
    }
    
    // Add a subtle glow around the card edges
    final glowPaint = Paint()
      ..color = color.withOpacity(0.1)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rRect = RRect.fromRectAndRadius(rect, Radius.circular(16));
    
    canvas.drawRRect(rRect, glowPaint);
  }
  
  @override
  bool shouldRepaint(CloudyEffectPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}

// Extension to capitalize first letter of a string
extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
} 