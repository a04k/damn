import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../notification_service.dart';

class AddTaskPage extends StatefulWidget {
  const AddTaskPage({super.key});

  @override
  State<AddTaskPage> createState() => _AddTaskPageState();
}

class _AddTaskPageState extends State<AddTaskPage> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descController = TextEditingController();

  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  String importance = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.blueGrey),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text(
          "Add Task",
          style: TextStyle(
            color: Color(0xFF1F2C5C),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Task Name", style: labelStyle),
              const SizedBox(height: 6),
              inputBox(titleController, hint: "Enter task name"),
              const SizedBox(height: 16),
              const Text("Description", style: labelStyle),
              const SizedBox(height: 6),
              descriptionBox(descController),
              const SizedBox(height: 16),
              const Text("Deadline", style: labelStyle),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: dateBox(
                      title:
                          selectedDate == null
                              ? "Pick a date"
                              : DateFormat(
                                'MMMM dd, yyyy',
                              ).format(selectedDate!),
                      onTap: pickDate,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: dateBox(
                      title:
                          selectedTime == null
                              ? "Pick time"
                              : selectedTime!.format(context),
                      onTap: pickTime,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              const Text("Importance", style: labelStyle),
              const SizedBox(height: 8),
              Row(
                children: [
                  priorityButton("Low", Colors.green),
                  const SizedBox(width: 10),
                  priorityButton("Medium", Colors.orange),
                  const SizedBox(width: 10),
                  priorityButton("High", Colors.red),
                ],
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1F2C96),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: saveTask,
                  child: const Text(
                    "Save",
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void saveTask() {
    if (titleController.text.isEmpty ||
        selectedDate == null ||
        selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please complete all required fields")),
      );
      return;
    }

    final notificationId = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    final task = {
      "title": titleController.text,
      "description": descController.text,
      "date": selectedDate,
      "time": selectedTime,
      "priority": importance,
      "course": "General",
      "notificationId": notificationId,
    };

    // Schedule notifications (1 day and 1 hour before)
    final scheduledDate = DateTime(
      selectedDate!.year,
      selectedDate!.month,
      selectedDate!.day,
      selectedTime!.hour,
      selectedTime!.minute,
    );

    NotificationService.scheduleTaskNotifications(
      id: notificationId,
      title: task['title'] as String,
      dueDate: scheduledDate,
      body: 'Your task "${task['title']}" is due soon!',
    );

    Navigator.pop(context, task);
  }

  Future pickDate() async {
    DateTime? date = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (date != null) setState(() => selectedDate = date);
  }

  Future pickTime() async {
    TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: selectedTime ?? TimeOfDay.now(),
    );
    if (time != null) setState(() => selectedTime = time);
  }

  Widget priorityButton(String text, Color color) {
    bool isSelected = importance == text;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => importance = text),
        child: Container(
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? color : const Color(0xFFEEC97A),
            ),
            color: isSelected ? color.withOpacity(0.15) : Colors.transparent,
          ),
          child: Text(
            text,
            style: TextStyle(
              color: isSelected ? color : const Color(0xFF1F2C5C),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

const labelStyle = TextStyle(
  color: Color(0xFF1F2C5C),
  fontSize: 14,
  fontWeight: FontWeight.w600,
);

Widget inputBox(TextEditingController controller, {required String hint}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12),
    decoration: boxDecoration,
    child: TextField(
      controller: controller,
      decoration: InputDecoration(border: InputBorder.none, hintText: hint),
    ),
  );
}

Widget descriptionBox(TextEditingController controller) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: boxDecoration,
    child: TextField(
      controller: controller,
      maxLines: 5,
      decoration: const InputDecoration(border: InputBorder.none),
    ),
  );
}

Widget dateBox({required String title, required VoidCallback onTap}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      height: 50,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: boxDecoration,
      child: Text(title, style: const TextStyle(color: Color(0xFF1F2C5C))),
    ),
  );
}

const boxDecoration = BoxDecoration(
  borderRadius: BorderRadius.all(Radius.circular(10)),
  border: Border.fromBorderSide(
    BorderSide(color: Color(0xFFEEC97A), width: 1.4),
  ),
);
