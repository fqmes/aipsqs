import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';

class WorkersAI {
  final String baseUrl;
  final String apiKey;

  WorkersAI({required this.baseUrl, required this.apiKey});

  static Future<WorkersAI> create(FirebaseFirestore firestore) async {
    final configSnapshot =
        await firestore.collection('config').doc('workers').get();

    if (configSnapshot.exists && configSnapshot.data() != null) {
      final configData = configSnapshot.data()!;
      final apiKey = configData['apiKey'];
      final baseUrl = configData['baseUrl'];

      return WorkersAI(baseUrl: baseUrl, apiKey: apiKey);
    } else {
      throw Exception("WorkersAI config not found");
    }
  }

  Future<List<Map<String, dynamic>>> generateQuiz(
    String topic,
    String difficulty,
    int number,
  ) async {
    try {
      final uri = Uri.parse(baseUrl);

      final payload = {
        "prompt":
            ''' Generate $number multiple choice quiz questions on the topic "$topic" with "$difficulty" difficulty.
Each object must follow this exact format:
{"question": "Your question here?", "options": ["Option 1", "Option 2", "Option 3", "Option 4"], "answer": "Exact matching option text"}
STRICT RULES:
- Use ONLY plain ASCII text.
- Do NOT use LaTeX, Unicode symbols (like π, £, €, ∑), or math notation.
- Avoid special characters or formatting (e.g., bold, bullet points).
- Keep each question under 100 characters.
- Keep each option under 40 characters.
- "answer" must exactly match one of the options.
- Return ONLY a valid JSON array with no extra text or comments.
- JSON must be valid and parsable. ''',
      };

      final response = await http.post(
        uri,
        headers: {
          "Authorization": "Bearer $apiKey",
          "Content-Type": "application/json",
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);

        if (responseBody['success'] == true &&
            responseBody['result']['response'] != null) {
          String jsonString = responseBody['result']['response'].trim();

          if (!jsonString.startsWith("[")) {
            final firstBracket = jsonString.indexOf("[");
            if (firstBracket != -1)
              jsonString = jsonString.substring(firstBracket);
          }
          if (!jsonString.endsWith("]")) {
            jsonString += "]";
          }

          try {
            final parsedJson = jsonDecode(jsonString);

            if (parsedJson is List) {
              final cleaned =
                  parsedJson.map<Map<String, dynamic>>((item) {
                    if (item.containsKey('correct') &&
                        !item.containsKey('answer')) {
                      item['answer'] = item['correct'];
                    }
                    return Map<String, dynamic>.from(item);
                  }).toList();

              print("✅ Parsed AI quiz: $cleaned");
              return cleaned;
            } else {
              throw Exception(
                "Invalid JSON format received (not a List): $jsonString",
              );
            }
          } catch (_) {
            print("⚠️ Falling back to partial object recovery...");

            final objectMatches =
                RegExp(
                  r'\{[\s\S]*?\}',
                ).allMatches(jsonString).map((m) => m.group(0)!).toList();

            final validQuestions = <Map<String, dynamic>>[];

            for (var obj in objectMatches) {
              try {
                final parsed = jsonDecode(obj);
                if (parsed is Map<String, dynamic> &&
                    parsed.containsKey('question') &&
                    parsed.containsKey('options') &&
                    parsed.containsKey('answer')) {
                  validQuestions.add(parsed);
                }
              } catch (_) {
                continue;
              }
            }

            if (validQuestions.isEmpty) {
              throw Exception("No valid questions found.");
            }

            print("✅ Recovered ${validQuestions.length} valid quiz questions");
            return validQuestions;
          }
        } else {
          throw Exception(
            "API response indicates failure or missing 'response': ${response.body}",
          );
        }
      } else {
        throw Exception(
          "Failed to get a response: ${response.statusCode}, ${response.body}",
        );
      }
    } catch (e) {
      throw Exception("Error occurred during quiz generation: $e");
    }
  }
}
