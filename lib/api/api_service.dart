import 'dart:convert';

import 'package:friday_virtual_assistant/api_key.dart';
import 'package:http/http.dart' as http;

class APIService
{
  Future<http.Response> requestOpenAI(String userInput, String mode, int maximumTokens) async
  {

    const String url = "https://api.openai.com/";
    final String openAiApiUrl = mode == "chat" ? "v1/chat/completions" : "v1/images/generations";

    final body = mode == "chat"
        ?
    {
      "model": "gpt-4",
      "messages": [
        {
          "role": "user",
          "content": userInput,
        }
      ],
      "max_tokens": 2000,
      "temperature": 0.9,
      "n": 1,
    }
        :
    {
      "messages": [
        {
          "role": "user",
          "content": userInput,
        }
      ],
    };

    final responseFromOpenAPI = await http.post(
      Uri.parse(url + openAiApiUrl),
      headers:
      {
        "Content-Type": "application/json",
        "Authorization": "Bearer $apiKey"
      },
      body: jsonEncode(body),
    );

    return responseFromOpenAPI;
  }
}