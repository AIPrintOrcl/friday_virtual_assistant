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
        // ai 챗붓
    {
      // "model": "gpt-3.5-turbo",
      "model": "ft:gpt-3.5-turbo-0125:::A5T7hY6p",
      "messages": [
        {
          "role": "user",
          "content": userInput,
        },
      ],
      // "tools": tools,
      "max_tokens": 100,
      "temperature": 0.7,
      "n": 1,
    }
    :
    // ai 이미지 생성
    {
      "prompt": userInput,  // For image generation, we use 'prompt'
      "n": 1,
      "size": "1024x1024"  // Image size for image generation
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