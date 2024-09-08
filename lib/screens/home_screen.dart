import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:friday_virtual_assistant/api/api_service.dart';
import 'package:image_downloader/image_downloader.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:text_to_speech/text_to_speech.dart';



class HomeScreen extends StatefulWidget
{
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}



class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin
{
  TextEditingController userInputTextEditingController = TextEditingController();
  final SpeechToText speechToTextInstance = SpeechToText();
  String recordedAudioString = "";
  bool isLoading = false;
  bool speakFRIDAY = true;
  String modeOpenAI = "chat";
  String imageUrlFromOpenAI = "";
  String answerTextFromOpenAI = "";
  String interest_level = ""; // 관심도
  final TextToSpeech textToSpeechInstance = TextToSpeech();


  void initializeSpeechToText() async
  {
    await speechToTextInstance.initialize();

    setState(() {

    });
  }

  void startListeningNow() async
  {
    FocusScope.of(context).unfocus();

    await speechToTextInstance.listen(onResult: onSpeechToTextResult);

    setState(() {

    });
  }

  void stopListeningNow() async
  {
    await speechToTextInstance.stop();

    setState(() {

    });
  }

  void onSpeechToTextResult(SpeechRecognitionResult recognitionResult)
  {
    recordedAudioString = recognitionResult.recognizedWords;

    speechToTextInstance.isListening ? null : sendRequestToOpenAI(recordedAudioString);

    print("Speech Result:");
    print(recordedAudioString);
  }

  Future<void> sendRequestToOpenAI(String userInput) async {
    stopListeningNow();

    setState(() {
      isLoading = true;
    });

    try {
      // API 호출 전 로그 출력
      print("OpenAI에 보낼 요청: $userInput");

      // OpenAI API로 요청 보내기
      var response = await APIService().requestOpenAI(userInput, modeOpenAI, 2000);

      setState(() {
        isLoading = false;
      });

      if (response.statusCode == 401) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("API 키가 만료되었거나 작동하지 않습니다."),
          ),
        );
        return;
      }

      // 응답 데이터 출력
      print("OpenAI로부터 받은 응답: ${response.body}");

      // 응답을 JSON으로 변환
      final responseAvailable = jsonDecode(response.body);

      if (responseAvailable == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("OpenAI 응답이 비어있습니다."),
          ),
        );
        return;
      }

      if (modeOpenAI == "chat") {
        // ChatGPT 응답 처리
        if (responseAvailable["choices"] != null &&
            responseAvailable["choices"].isNotEmpty) {
          setState(() {
            answerTextFromOpenAI = utf8.decode(
                responseAvailable["choices"][0]['message']['content'].toString().codeUnits);
            interest_level = utf8.decode(
                responseAvailable["choices"][0]['message']['interest_level'].toString().codeUnits);
            print("ChatGPT 응답: $answerTextFromOpenAI");
            print("ChatGPT 관심도: $interest_level");

            //텍스트를 음성으로 변환
            if(speakFRIDAY) {
              textToSpeechInstance.speak(answerTextFromOpenAI);
            }
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("OpenAI 응답에 텍스트가 없습니다."),
            ),
          );
        }
      } else {
        // 이미지 생성 처리
        if (responseAvailable["data"] != null &&
            responseAvailable["data"].isNotEmpty) {
          setState(() {
            imageUrlFromOpenAI = responseAvailable["data"][0]["url"];
            print("생성된 이미지 URL: $imageUrlFromOpenAI");
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("이미지 URL을 가져올 수 없습니다."),
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("오류 발생: ${e.toString()}"),
        ),
      );
    }
  }



  @override
  void initState() {
    super.initState();

    initializeSpeechToText();
  }

  @override
  Widget build(BuildContext context)
  {
    return Scaffold(
      // ai 응답 음성/음소거 설정
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.white,
        onPressed: ()
        {
          if(!isLoading) {
            setState(() {
              speakFRIDAY = !speakFRIDAY;
            });
          }

          textToSpeechInstance.stop();
        },
        // 음성 설정
        child: speakFRIDAY ? Padding(
          padding: const EdgeInsets.all(4.0),
          child: Image.asset(
              "assets/images/sound.png"
          ),
          // 음소거 설정
        ) : Padding(
          padding: const EdgeInsets.all(4.0),
          child: Image.asset(
              "assets/images/mute.png"
          ),
        ),
      ),
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: [
                    Colors.purpleAccent.shade100,
                    Colors.deepPurple,
                  ]
              )
          ),
        ),
        title: Image.asset(
          "assets/images/app_icon.png",
          width: 40,
        ),
        titleSpacing: 10,
        elevation: 2,
        actions: [
          //chat
          Padding(
            padding: const EdgeInsets.only(right: 4, top: 4),
            child: InkWell(
              onTap: ()
              {
                setState(() {
                  modeOpenAI = "chat";
                });
              },
              child: Icon(
                Icons.chat,
                size: 40,
                color: modeOpenAI == "chat" ? Colors.white : Colors.grey,
              ),
            ),
          ),

          //image
          Padding(
            padding: const EdgeInsets.only(right: 8, left: 4),
            child: InkWell(
              onTap: ()
              {
                setState(() {
                  modeOpenAI = "image";
                });
              },
              child: Icon(
                Icons.image,
                size: 40,
                color: modeOpenAI == "image" ? Colors.white : Colors.grey,
              ),
            ),
          ),

        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [

              const SizedBox(height: 40,),

              //image
              Center(
                child: InkWell(
                  onTap: ()
                  {
                    speechToTextInstance.isListening
                        ? stopListeningNow()
                        : startListeningNow();
                  },
                  child: speechToTextInstance.isListening
                      ? Center(child: LoadingAnimationWidget.beat(
                    size: 300,
                    color: speechToTextInstance.isListening
                        ? Colors.deepPurple
                        : isLoading
                        ? Colors.deepPurple[400]!
                        : Colors.deepPurple[200]!,
                  ),)
                      : Image.asset(
                    "assets/gif/egg0.gif",
                    height: 300,
                    width: 300,
                  ),
                ),
              ),

              const SizedBox(
                height: 50,
              ),

              //text field with a button
              Row(
                children: [

                  //text field
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 4.0),
                      child: TextField(
                        controller: userInputTextEditingController,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: "개구니와 이야기해 보세요.",
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 10,),

                  //button
                  InkWell(
                    onTap: ()
                    {
                      if(userInputTextEditingController.text.isNotEmpty)
                      {
                        sendRequestToOpenAI(userInputTextEditingController.text.toString());
                        userInputTextEditingController.clear();
                      }
                    },
                    child: AnimatedContainer(
                      padding: const EdgeInsets.all(15),
                      decoration: const BoxDecoration(
                          shape: BoxShape.rectangle,
                          color: Colors.deepPurpleAccent
                      ),
                      duration: const Duration(
                        milliseconds: 1000,
                      ),
                      curve: Curves.bounceInOut,
                      child: const Icon(
                        Icons.send,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                  ),

                ],
              ),

              const SizedBox(
                height: 24,
              ),

              //display result
              modeOpenAI == "chat"
                  ? SelectableText(
                    answerTextFromOpenAI,
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                  : modeOpenAI == "image" && imageUrlFromOpenAI.isNotEmpty
                  ? Column(
                    //image
                    children: [
                      Image.network(
                        imageUrlFromOpenAI,
                      ),
                      const SizedBox(height: 14,),
                      // 이미지 저장 버튼
                      ElevatedButton(
                          onPressed: () async {
                            String? imageStatus = await ImageDownloader.downloadImage(imageUrlFromOpenAI);

                            if(imageStatus != null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text("Image downloaded Successfully.")
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                          ),
                        child: Text(
                          "이미지 저장",
                          style: TextStyle(
                            color: Colors.white,
                          ),
                        ),
                      )
                    ],
                  )
                  : Container()
            ],
          ),
        ),
      ),
    );
  }
}
