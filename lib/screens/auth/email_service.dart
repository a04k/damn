import 'dart:convert';
import 'package:http/http.dart' as http;

class EmailService {
  static const String serviceId = 'service_qro3d8f';
  static const String templateId = 'template_ggz2ghg';
  static const String userId = 'KpiEHFZURo_yIgMCl';

  static Future<bool> sendVerificationCode({
    required String toEmail,
    required String code,
  }) async {
    final url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');

    try {
      final response = await http.post(
        url,
        headers: {
          'origin': 'http://localhost',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'service_id': serviceId,
          'template_id': templateId,
          'user_id': userId,
          'template_params': {
            'to_email': toEmail,
            'code': code,
            'time': DateTime.now().add(const Duration(minutes: 3)).toString(),
          },
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
