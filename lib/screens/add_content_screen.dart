import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../core/api_config.dart';
import '../providers/app_mode_provider.dart';
import '../providers/app_session_provider.dart';
import '../services/data_service.dart';
import '../models/course.dart';
import '../models/user.dart';

/// Content type enum for professor content creation
enum ContentType { lecture, assignment, exam }

/// Main screen for adding content (professors only)
class AddContentScreen extends ConsumerStatefulWidget {
  const AddContentScreen({super.key});

  @override
  ConsumerState<AddContentScreen> createState() => _AddContentScreenState();
}

class _AddContentScreenState extends ConsumerState<AddContentScreen> {
  // State
  ContentType? _selectedType;
  List<Course> _courses = [];
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _errorMessage;
  
  // Attachments
  List<String> _uploadedFiles = [];
  bool _isUploading = false;

  // Form controllers
  final _formKey = GlobalKey<FormState>();
  String? _selectedCourseId;
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _pointsController = TextEditingController(text: '100');
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _pointsController.dispose();
    super.dispose();
  }

  Future<void> _loadCourses() async {
    final user = ref.read(currentUserProvider).value;
    if (user == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'User session not found';
      });
      return;
    }

    try {
      final courses = await DataService.getProfessorCourses(user.email);
      
      if (mounted) {
        setState(() {
          _courses = courses;
          _isLoading = false;
          if (courses.isEmpty) {
            _errorMessage = 'No courses assigned. Contact admin to assign courses.';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  void _selectType(ContentType type) {
    setState(() => _selectedType = type);
  }

  void _goBack() {
    if (_selectedType != null) {
      setState(() => _selectedType = null);
    } else if (context.canPop()) {
      context.pop();
    } else {
      context.go('/home');
    }
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: const TimeOfDay(hour: 23, minute: 59),
      );

      if (time != null && mounted) {
        setState(() {
          _selectedDate = DateTime(date.year, date.month, date.day, time.hour, time.minute);
        });
      }
    }
  }

  Future<void> _pickAndUploadFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
      );

      if (result != null) {
        setState(() => _isUploading = true);

        // Create request
        var request = http.MultipartRequest('POST', Uri.parse('${ApiConfig.baseUrl}/upload'));
        
        // Add headers
        final authHeader = ApiConfig.authHeaders['Authorization'];
        if (authHeader != null) {
           request.headers['Authorization'] = authHeader;
        }

        // Add file
        if (result.files.first.bytes != null) {
          // Web or bytes provided
          request.files.add(http.MultipartFile.fromBytes(
            'file',
            result.files.first.bytes!,
            filename: result.files.first.name,
          ));
        } else if (result.files.first.path != null) {
          // Mobile/Desktop
          request.files.add(await http.MultipartFile.fromPath(
            'file',
            result.files.first.path!,
          ));
        }

        // Send
        var streamedResponse = await request.send();
        var response = await http.Response.fromStream(streamedResponse);

        if (response.statusCode == 200 || response.statusCode == 201) {
          final data = jsonDecode(response.body);
          if (data['success'] == true && data['fileUrl'] != null) {
            setState(() {
              _uploadedFiles.add(data['fileUrl']);
              _isUploading = false;
            });
            _showMessage('Uploaded: ${result.files.first.name}', isError: false);
          } else {
             throw Exception(data['message'] ?? 'Upload failed');
          }
        } else {
          throw Exception('Server error: ${response.statusCode}');
        }
      }
    } catch (e) {
      setState(() => _isUploading = false);
      _showMessage('Error uploading: $e', isError: true);
    }
  }

  Future<void> _addLink() async {
    final controller = TextEditingController();
    final link = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Link'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'https://example.com',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                Navigator.pop(context, controller.text.trim());
              }
            }, 
            child: const Text('Add')
          ),
        ],
      ),
    );
    
    if (link != null && link.isNotEmpty) {
      setState(() {
        _uploadedFiles.add(link.startsWith('http') ? link : 'https://$link');
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCourseId == null) {
      _showMessage('Please select a course', isError: true);
      return;
    }
    if (_needsDate && _selectedDate == null) {
      _showMessage('Please select a date', isError: true);
      return;
    }

    setState(() => _isSubmitting = true);

    bool success = false;

    try {
      switch (_selectedType) {
        case ContentType.lecture:
          success = await DataService.createContent(
            courseId: _selectedCourseId!,
            title: _titleController.text.trim(),
            description: _descriptionController.text.trim(),
            contentType: 'LECTURE',
            attachments: _uploadedFiles,
          );
          break;
        case ContentType.assignment:
          success = await DataService.createAssignment(
            courseId: _selectedCourseId!,
            title: _titleController.text.trim(),
            description: _descriptionController.text.trim(),
            dueDate: _selectedDate!,
            maxPoints: int.tryParse(_pointsController.text) ?? 100,
            attachments: _uploadedFiles,
          );
          break;
        case ContentType.exam:
          success = await DataService.createExam(
            courseId: _selectedCourseId!,
            title: _titleController.text.trim(),
            description: _descriptionController.text.trim(),
            examDate: _selectedDate!,
            maxPoints: int.tryParse(_pointsController.text) ?? 100,
            attachments: _uploadedFiles,
          );
          break;
        default:
          break;
      }
    } catch (e) {
      debugPrint('Error creating content: $e');
      success = false;
    }

    setState(() => _isSubmitting = false);

    if (success) {
      if (mounted) {
        _showMessage('$_typeName created! Students have been notified.', isError: false);
        _resetForm();
      }
    } else {
      if (mounted) {
        _showMessage('Failed to create ${_typeName.toLowerCase()}', isError: true);
      }
    }
  }

  void _resetForm() {
    setState(() {
      _selectedType = null;
      _selectedCourseId = null;
      _titleController.clear();
      _descriptionController.clear();
      _pointsController.text = '100';
      _selectedDate = null;
      _uploadedFiles.clear();
    });
  }

  void _showMessage(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Helpers
  bool get _needsDate => _selectedType == ContentType.assignment || _selectedType == ContentType.exam;
  
  String get _typeName {
    switch (_selectedType) {
      case ContentType.lecture: return 'Lecture';
      case ContentType.assignment: return 'Assignment';
      case ContentType.exam: return 'Exam';
      default: return 'Content';
    }
  }

  Color get _typeColor {
    switch (_selectedType) {
      case ContentType.lecture: return const Color(0xFF10B981);
      case ContentType.assignment: return const Color(0xFF3B82F6);
      case ContentType.exam: return const Color(0xFFEF4444);
      default: return const Color(0xFF6366F1);
    }
  }

  IconData get _typeIcon {
    switch (_selectedType) {
      case ContentType.lecture: return Icons.menu_book;
      case ContentType.assignment: return Icons.assignment;
      case ContentType.exam: return Icons.quiz;
      default: return Icons.add;
    }
  }

  @override
  Widget build(BuildContext context) {
    final appMode = ref.watch(appModeControllerProvider);

    // Access check
    if (appMode != AppMode.professor) {
      return _buildAccessDenied();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: _goBack,
        ),
        title: Text(
          _selectedType == null ? 'Add Content' : 'New $_typeName',
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null && _courses.isEmpty
              ? _buildError()
              : _selectedType == null
                  ? _buildTypeSelection()
                  : _buildForm(),
    );
  }

  Widget _buildAccessDenied() {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.go('/home'),
        ),
        title: const Text('Access Denied', style: TextStyle(color: Colors.black)),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_outline, size: 80, color: Color(0xFF9CA3AF)),
            SizedBox(height: 16),
            Text(
              'Professor access required',
              style: TextStyle(fontSize: 18, color: Color(0xFF6B7280)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.warning_amber, size: 64, color: Color(0xFFF59E0B)),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Color(0xFF6B7280)),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _errorMessage = null;
                });
                _loadCourses();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeSelection() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'What would you like to create?',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Select content type to get started',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 32),
          
          _buildTypeCard(
            type: ContentType.lecture,
            title: 'Lecture',
            subtitle: 'Add lecture materials and notes',
            icon: Icons.menu_book,
            color: const Color(0xFF10B981),
          ),
          const SizedBox(height: 16),
          
          _buildTypeCard(
            type: ContentType.assignment,
            title: 'Assignment',
            subtitle: 'Create assignments with deadlines',
            icon: Icons.assignment,
            color: const Color(0xFF3B82F6),
          ),
          const SizedBox(height: 16),
          
          _buildTypeCard(
            type: ContentType.exam,
            title: 'Exam',
            subtitle: 'Schedule exams and assessments',
            icon: Icons.quiz,
            color: const Color(0xFFEF4444),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeCard({
    required ContentType type,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () => _selectType(type),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 28, color: color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: TextStyle(color: Colors.grey[600])),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Type badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: _typeColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_typeIcon, size: 18, color: _typeColor),
                const SizedBox(width: 8),
                Text(_typeName, style: TextStyle(color: _typeColor, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          
          const SizedBox(height: 24),

          // Course dropdown
          _buildLabel('Course'),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _selectedCourseId,
            decoration: _inputDecoration('Select a course'),
            items: _courses.map((c) => DropdownMenuItem(
              value: c.id,
              child: Text('${c.code} - ${c.name}', overflow: TextOverflow.ellipsis),
            )).toList(),
            onChanged: (v) => setState(() => _selectedCourseId = v),
            validator: (v) => v == null ? 'Required' : null,
          ),

          const SizedBox(height: 20),

          // Title
          _buildLabel('Title'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _titleController,
            decoration: _inputDecoration('Enter title'),
            validator: (v) => v == null || v.isEmpty ? 'Required' : null,
          ),

          const SizedBox(height: 20),

          // Description
          _buildLabel('Description'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _descriptionController,
            decoration: _inputDecoration('Enter description'),
            maxLines: 4,
            validator: (v) => v == null || v.isEmpty ? 'Required' : null,
          ),

          // Attachments UI
          const SizedBox(height: 20),
          _buildLabel('Attachments'),
          const SizedBox(height: 8),
          if (_uploadedFiles.isNotEmpty)
            Column(
              children: _uploadedFiles.map((url) {
                final name = url.split('/').last.split('-').length > 1 
                  ? url.split('/').last.split('-').skip(1).join('-') 
                  : url.split('/').last;
                  
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.attach_file, size: 16, color: Colors.blue),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          name,
                          style: const TextStyle(fontSize: 13, color: Colors.blue),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      InkWell(
                        onTap: () => setState(() => _uploadedFiles.remove(url)),
                        child: const Padding(
                          padding: EdgeInsets.all(4.0),
                          child: Icon(Icons.close, size: 16, color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isUploading ? null : _pickAndUploadFile,
                  icon: _isUploading 
                      ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2)) 
                      : const Icon(Icons.attach_file, size: 16),
                  label: Text(_isUploading ? "Uploading..." : "Attach File", style: const TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    elevation: 0,
                    side: const BorderSide(color: Color(0xFFD1D5DB)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _addLink,
                  icon: const Icon(Icons.link, size: 16),
                  label: const Text("Add Link", style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    elevation: 0,
                    side: const BorderSide(color: Color(0xFFD1D5DB)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ],
          ),

          // Points and Date (for assignment/exam only)
          if (_needsDate) ...[
            const SizedBox(height: 20),
            
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('Points'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _pointsController,
                        decoration: _inputDecoration('100'),
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Required';
                          if (int.tryParse(v) == null) return 'Invalid';
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel(_selectedType == ContentType.exam ? 'Exam Date' : 'Due Date'),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: _selectDate,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFFD1D5DB)),
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.white,
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.calendar_today, size: 20, color: Colors.grey[600]),
                              const SizedBox(width: 8),
                              Text(
                                _selectedDate != null
                                    ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                                    : 'Select date',
                                style: TextStyle(
                                  color: _selectedDate != null ? Colors.black : Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 32),

          // Submit button
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: _typeColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                disabledBackgroundColor: _typeColor.withOpacity(0.5),
              ),
              child: _isSubmitting
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text('Create $_typeName', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: _typeColor, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    );
  }
}