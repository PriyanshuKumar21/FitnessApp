import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/reminder_service.dart';
import '../models/reminder_model.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  final _types = ['Workout', 'Water', 'Medication', 'Stretching', 'Other'];
  String _activeFilter = 'All';
  
  @override
  void initState() {
    super.initState();
    // Load reminders when screen is opened
    Future.microtask(() => 
      Provider.of<ReminderService>(context, listen: false).loadReminders()
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Consumer<ReminderService>(
        builder: (context, reminderService, child) {
          if (reminderService.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            );
          }
          
          final reminders = _filterReminders(reminderService.reminders);
          
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 80),
              _buildFilterChips(),
              Expanded(
                child: reminders.isEmpty
                    ? _buildEmptyState()
                    : _buildRemindersList(reminders),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add, color: Colors.black),
        onPressed: () => _showAddReminderDialog(context),
      ),
    );
  }
  
  Widget _buildFilterChips() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildFilterChip('All'),
          ..._types.map((type) => _buildFilterChip(type)),
          _buildFilterChip('Today'),
          _buildFilterChip('Upcoming'),
        ],
      ),
    );
  }
  
  Widget _buildFilterChip(String label) {
    final isActive = _activeFilter == label;
    
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: isActive,
        label: Text(label),
        backgroundColor: Colors.grey[800],
        selectedColor: AppTheme.primaryColor.withOpacity(0.2),
        checkmarkColor: AppTheme.primaryColor,
        labelStyle: TextStyle(
          color: isActive ? AppTheme.primaryColor : Colors.white,
        ),
        side: BorderSide(
          color: isActive ? AppTheme.primaryColor : Colors.grey[700]!,
        ),
        onSelected: (selected) {
          setState(() {
            _activeFilter = label;
          });
        },
      ),
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_off,
            size: 64,
            color: Colors.grey[600],
          ),
          const SizedBox(height: 16),
          Text(
            'No reminders found',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap + to add a new reminder',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildRemindersList(List<Reminder> reminders) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: reminders.length,
      itemBuilder: (context, index) {
        final reminder = reminders[index];
        final timeFormat = DateFormat('h:mm a');
        final dateFormat = DateFormat('MMM d, yyyy');
        
        return Dismissible(
          key: Key('reminder-${reminder.id}'),
          background: Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.red[900]!.withOpacity(0.8),
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.centerRight,
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          direction: DismissDirection.endToStart,
          onDismissed: (direction) => _deleteReminder(reminder.id!),
          child: GlassCard(
            margin: const EdgeInsets.symmetric(vertical: 8),
            borderRadius: 16,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        _getReminderIcon(reminder.type),
                        const SizedBox(width: 8),
                        Text(
                          reminder.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        // Edit button
                        IconButton(
                          icon: const Icon(Icons.edit, size: 20),
                          onPressed: () => _showEditReminderDialog(context, reminder),
                        ),
                        // Toggle active state
                        Switch(
                          value: reminder.isActive,
                          activeColor: AppTheme.primaryColor,
                          onChanged: (value) => _toggleReminderActive(reminder.id!, value),
                        ),
                      ],
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reminder.message,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[300],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.access_time, size: 16, color: AppTheme.primaryColor),
                          const SizedBox(width: 4),
                          Text(
                            timeFormat.format(reminder.reminderTime),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Icon(Icons.calendar_today, size: 16, color: Colors.grey[400]),
                          const SizedBox(width: 4),
                          Text(
                            dateFormat.format(reminder.reminderTime),
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[400],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _getReminderIcon(String type) {
    switch (type.toLowerCase()) {
      case 'workout':
        return const Icon(Icons.fitness_center, color: Colors.orange);
      case 'water':
        return const Icon(Icons.water_drop, color: Colors.blue);
      case 'medication':
        return const Icon(Icons.medication, color: Colors.red);
      case 'stretching':
        return const Icon(Icons.self_improvement, color: Colors.purple);
      default:
        return const Icon(Icons.notifications, color: AppTheme.primaryColor);
    }
  }
  
  List<Reminder> _filterReminders(List<Reminder> reminders) {
    if (_activeFilter == 'All') {
      return reminders;
    } else if (_activeFilter == 'Today') {
      final reminderService = Provider.of<ReminderService>(context, listen: false);
      return reminderService.getTodayReminders();
    } else if (_activeFilter == 'Upcoming') {
      final reminderService = Provider.of<ReminderService>(context, listen: false);
      return reminderService.getUpcomingReminders();
    } else {
      return reminders.where((r) => r.type.toLowerCase() == _activeFilter.toLowerCase()).toList();
    }
  }
  
  Future<void> _showAddReminderDialog(BuildContext context) async {
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController();
    final messageController = TextEditingController();
    String selectedType = _types[0];
    DateTime selectedDate = DateTime.now().add(const Duration(minutes: 30));
    
    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Add Reminder'),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title field
                      TextFormField(
                        controller: titleController,
                        decoration: const InputDecoration(
                          labelText: 'Title',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a title';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Message field
                      TextFormField(
                        controller: messageController,
                        decoration: const InputDecoration(
                          labelText: 'Message',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 2,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a message';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Type dropdown
                      DropdownButtonFormField<String>(
                        value: selectedType,
                        decoration: const InputDecoration(
                          labelText: 'Type',
                          border: OutlineInputBorder(),
                        ),
                        items: _types.map((type) {
                          return DropdownMenuItem<String>(
                            value: type,
                            child: Text(type),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              selectedType = value;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Date and time
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.calendar_today),
                              label: Text(DateFormat('MMM d, yyyy').format(selectedDate)),
                              onPressed: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: selectedDate,
                                  firstDate: DateTime.now(),
                                  lastDate: DateTime.now().add(const Duration(days: 365)),
                                );
                                if (date != null) {
                                  setState(() {
                                    selectedDate = DateTime(
                                      date.year,
                                      date.month,
                                      date.day,
                                      selectedDate.hour,
                                      selectedDate.minute,
                                    );
                                  });
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.access_time),
                              label: Text(DateFormat('h:mm a').format(selectedDate)),
                              onPressed: () async {
                                final time = await showTimePicker(
                                  context: context,
                                  initialTime: TimeOfDay.fromDateTime(selectedDate),
                                );
                                if (time != null) {
                                  setState(() {
                                    selectedDate = DateTime(
                                      selectedDate.year,
                                      selectedDate.month,
                                      selectedDate.day,
                                      time.hour,
                                      time.minute,
                                    );
                                  });
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.black,
                  ),
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      _addReminder(
                        title: titleController.text,
                        message: messageController.text,
                        reminderTime: selectedDate,
                        type: selectedType,
                      );
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }
  
  Future<void> _showEditReminderDialog(BuildContext context, Reminder reminder) async {
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController(text: reminder.title);
    final messageController = TextEditingController(text: reminder.message);
    String selectedType = reminder.type;
    DateTime selectedDate = reminder.reminderTime;
    
    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Edit Reminder'),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title field
                      TextFormField(
                        controller: titleController,
                        decoration: const InputDecoration(
                          labelText: 'Title',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a title';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Message field
                      TextFormField(
                        controller: messageController,
                        decoration: const InputDecoration(
                          labelText: 'Message',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 2,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a message';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Type dropdown
                      DropdownButtonFormField<String>(
                        value: selectedType,
                        decoration: const InputDecoration(
                          labelText: 'Type',
                          border: OutlineInputBorder(),
                        ),
                        items: _types.map((type) {
                          return DropdownMenuItem<String>(
                            value: type,
                            child: Text(type),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              selectedType = value;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Date and time
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.calendar_today),
                              label: Text(DateFormat('MMM d, yyyy').format(selectedDate)),
                              onPressed: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: selectedDate,
                                  firstDate: DateTime.now(),
                                  lastDate: DateTime.now().add(const Duration(days: 365)),
                                );
                                if (date != null) {
                                  setState(() {
                                    selectedDate = DateTime(
                                      date.year,
                                      date.month,
                                      date.day,
                                      selectedDate.hour,
                                      selectedDate.minute,
                                    );
                                  });
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.access_time),
                              label: Text(DateFormat('h:mm a').format(selectedDate)),
                              onPressed: () async {
                                final time = await showTimePicker(
                                  context: context,
                                  initialTime: TimeOfDay.fromDateTime(selectedDate),
                                );
                                if (time != null) {
                                  setState(() {
                                    selectedDate = DateTime(
                                      selectedDate.year,
                                      selectedDate.month,
                                      selectedDate.day,
                                      time.hour,
                                      time.minute,
                                    );
                                  });
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.black,
                  ),
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      _updateReminder(
                        id: reminder.id!,
                        title: titleController.text,
                        message: messageController.text,
                        reminderTime: selectedDate,
                        type: selectedType,
                      );
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }
  
  Future<void> _addReminder({
    required String title,
    required String message,
    required DateTime reminderTime,
    required String type,
  }) async {
    final reminderService = Provider.of<ReminderService>(context, listen: false);
    
    final success = await reminderService.addReminder(
      title: title,
      message: message,
      reminderTime: reminderTime,
      type: type,
    );
    
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reminder added successfully')),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(reminderService.error ?? 'Failed to add reminder')),
      );
    }
  }
  
  Future<void> _updateReminder({
    required int id,
    required String title,
    required String message,
    required DateTime reminderTime,
    required String type,
  }) async {
    final reminderService = Provider.of<ReminderService>(context, listen: false);
    
    final success = await reminderService.updateReminder(
      id: id,
      title: title,
      message: message,
      reminderTime: reminderTime,
      type: type,
    );
    
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reminder updated successfully')),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(reminderService.error ?? 'Failed to update reminder')),
      );
    }
  }
  
  Future<void> _toggleReminderActive(int id, bool isActive) async {
    final reminderService = Provider.of<ReminderService>(context, listen: false);
    
    await reminderService.toggleReminderActive(id, isActive);
  }
  
  Future<void> _deleteReminder(int id) async {
    final reminderService = Provider.of<ReminderService>(context, listen: false);
    
    final success = await reminderService.deleteReminder(id);
    
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reminder deleted')),
      );
    }
  }
} 