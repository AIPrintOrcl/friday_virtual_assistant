import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:friday_virtual_assistant/api/api_service.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  TextEditingController userInputTextEditingController = TextEditingController();
  final SpeechToText speechToTextInstance = SpeechToText();
  String recordedAudioString = "";
  bool isLoading = false;
  String modeOpenAI = "chat";
  String imageUrlFromOpenAI = "";
  String answerTextFromOpenAI = "";

  void initializeSpeechToText() async {
    await speechToTextInstance.initialize();

    setState(() {

    });
  }

  void startListeninNow() async {
    FocusScope.of(context).unfocus();

    await speechToTextInstance.listen(onResult: onSpeechToTextResult);

    setState(() {

    });
  }

  void stopListeninNow() async {
    await speechToTextInstance.stop();

    setState(() {

    });
  }

  void onSpeechToTextResult(SpeechRecognitionResult recognitionResult) {
    recordedAudioString = recognitionResult.recognizedWords;

    speechToTextInstance.isListening ? null : sendRequestToOpenAI(recordedAudioString);

    print("Speech Result: ${recordedAudioString.toString()}");
  }

  // openAI 관련 함수
  Future<void> sendRequestToOpenAI(String userInput) async {
    stopListeninNow();

    setState(() {
      isLoading = true;
    });

    //send the request to openAI using our APIService
    await APIService().requestOpenAI(userInput, modeOpenAI, 2000).then((value) {
      setState(() {
        isLoading = false;
      });

      if(value.statusCode == 401) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(
                  "Api Key you are/were using expired or it is not working anymore.",
                ),
            ),
        );
      }

      userInputTextEditingController.clear();

      final responseAvailable = jsonDecode(value.body); // API 받은 인코딩된 응답 내용을 디코딩함.

      if(modeOpenAI == "chat") { // ai chat
         answerTextFromOpenAI = utf8.decode(responseAvailable["choices"][0]["text"].toString().codeUnits);
      } else { // ai image
        setState(() {
          imageUrlFromOpenAI = responseAvailable["data"][0]["url"];
        });
      }
    }).catchError((errorMessage) {
      setState(() {
        isLoading = false;

        SnackBar(
            content: Text(
              "Error: " + errorMessage.toString(),
            ),
        );
      });
    });

  }

  @override
  void initState() {
    super.initState();

    initializeSpeechToText();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 음성 sound
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.white,
        onPressed: (){

        },
        child: Padding(
          padding: const EdgeInsets.all(4.0),
          child: Image.asset(
            "assets/images/sound.png",
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
          "assets/images/logo.png",
          width: 140,
        ),
        titleSpacing: 10,
        elevation: 2,
        actions: [

          //chat
          Padding(
            padding: const EdgeInsets.only(right: 4, top: 4),
            child: InkWell(
              onTap: () {

              },
              child: const Icon(
                Icons.chat,
                size: 40,
                color: Colors.white,
              ),
            ),
          ),

          //image
          Padding(
            padding: const EdgeInsets.only(right: 8, left: 4),
            child: InkWell(
              onTap: () {

              },
              child: const Icon(
                Icons.image,
                size: 40,
                color: Colors.white,
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
                  onTap: () {
                    speechToTextInstance.isListening
                        ? stopListeninNow()
                        : startListeninNow();
                  },
                  child: speechToTextInstance.isListening
                      ? Center(child: LoadingAnimationWidget.beat(
                        size: 300,
                        color: speechToTextInstance.isListening
                            ? Colors.deepPurple
                            : isLoading
                            ? Colors.deepPurple[400]!
                            : Colors.deepPurple[200]!,
                      ),
                  ) // ai 듣는 중
                      : Image.asset( // ai 대기 상태
                    "assets/images/assistant_icon.png",
                    height: 300,
                    width: 300,
                  ),
                ),
              ),

              const SizedBox(
                height: 50,
              ),

              //채팅 입력 및 보내기
              Row(
                children: [
                  //텍스트 입력. text field
                  Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 4.0),
                        child: TextField(
                          controller: userInputTextEditingController,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: "무엇을 도와드릴까요?",
                          ),
                        ),
                      )
                  ),

                  const SizedBox(width: 10,),

                  // 메시지 보내기 button
                  InkWell(
                    onTap: ()
                    {
                      if(userInputTextEditingController.text.isNotEmpty) {
                        sendRequestToOpenAI(userInputTextEditingController.text.toString());
                      }

                      print('send user input : ${userInputTextEditingController.text}');
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
                  )
                ],
              ),

            ],
          ),
        ),
      ),
    );
  }
}
