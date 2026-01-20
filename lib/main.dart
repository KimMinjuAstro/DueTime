// 파일 맨 위에 추가
import 'dart:io'; // 파일 시스템 접근용 (File 클래스)
import 'package:image_picker/image_picker.dart'; // 카메라 구동 드라이버
import 'package:path_provider/path_provider.dart'; // 저장 경로 확보용
import 'package:path/path.dart' as path; // 경로 문자열 조작용 (join 등)
import 'package:flutter/material.dart';
import 'models/mission.dart';
import 'package:provider/provider.dart'; // 상태 관리 라이브러리
import 'providers/mission_provider.dart'; // 방금 만든 파일

void main() {
  // 앱이 실행될 때 Provider를 장착하고 시작함
  runApp(
    MultiProvider(
      providers: [
        // MissionProvider를 앱 전체에 공급하겠다고 선언
        ChangeNotifierProvider(create: (_) => MissionProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mission App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

 class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. 데이터 가져오기 (감시 시작)
    final missionProvider = context.watch<MissionProvider>();
    final missions = missionProvider.missions;
    
    // 2. 퍼센트 계산
    double progress = 0.0;
    if (missions.isNotEmpty) {
      progress = missionProvider.completedCount / missions.length;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('오늘의 미션'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          // [게이지 바 영역]
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("달성률", style: TextStyle(fontWeight: FontWeight.bold)),
                    Text("${(progress * 100).toInt()}%"), 
                  ],
                ),
                const SizedBox(height: 10),
                TweenAnimationBuilder<double>(
                  // Tween: "0부터 progress까지 값을 변환해라"
                  // (처음 빌드될 때만 0부터 시작하고, 그 뒤로는 현재 값 -> 새로운 값으로 알아서 연결됩니다)
                  tween: Tween<double>(begin: 0, end: progress),
                  
                  // Duration: 애니메이션 시간 (0.8초 추천)
                  duration: const Duration(milliseconds: 500),
                  
                  // Curve: 속도 곡선 (easeOutCubic: 처음에 슉 가다가 끝에서 부드럽게 멈춤)
                  curve: Curves.easeOutCubic, 
                  
                  builder: (context, value, _) {
                    return LinearProgressIndicator(
                      value: value, // 여기가 핵심! (progress 대신 계산된 value를 넣음)
                      minHeight: 20,
                      backgroundColor: Colors.grey[300],
                      color: Colors.blueAccent,
                      borderRadius: BorderRadius.circular(10),
                    );
                  },
                ),
              ],
            ),
          ),
          
          // [미션 리스트 영역]
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: missions.length,
              itemBuilder: (context, index) {
                final mission = missions[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  color: mission.isCompleted ? Colors.grey[200] : Colors.white,
                  child: ListTile(
                    onTap: () {
                      context.read<MissionProvider>().toggleMission(mission.id);
                    },
                    // [기능: 길게 누르면 삭제]
                    onLongPress: () {
                      context.read<MissionProvider>().deleteMission(mission.id);
                    },
                    leading: Checkbox(
                      value: mission.isCompleted,
                      onChanged: (val) {
                        context.read<MissionProvider>().toggleMission(mission.id);
                      },
                    ),
                    title: Text(
                      mission.title,
                      style: TextStyle(
                        decoration: mission.isCompleted 
                            ? TextDecoration.lineThrough 
                            : null,
                        color: mission.isCompleted ? Colors.grey : Colors.black,
                      ),
                    ),
                    // [기능: 카메라/갤러리 연동]
                    trailing: InkWell(
                      onTap: () async {
                        final picker = ImagePicker();
                        // 갤러리로 테스트 중이시면 아래 줄 그대로 쓰시고, 
                        // 나중에 카메라로 바꾸려면 ImageSource.camera로 고치세요.
                        // final XFile? image = await picker.pickImage(source: ImageSource.gallery);
                        final XFile? image = await picker.pickImage(source: ImageSource.camera);

                        if (image != null) {
                          final directory = await getApplicationDocumentsDirectory();
                          final fileName = '${mission.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
                          final savedImage = await File(image.path).copy('${directory.path}/$fileName');
                          
                          if (context.mounted) {
                            context.read<MissionProvider>().setMissionImage(mission.id, savedImage.path);
                          }
                        }
                      },
                      child: mission.imagePath == null
                          ? const Icon(Icons.camera_alt_outlined, size: 30, color: Colors.blue)
                          : ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                File(mission.imagePath!),
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                              ),
                            ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      // ★★★ [여기가 추가된 버튼입니다!] ★★★
      // Scaffold의 body가 끝난 직후에 floatingActionButton이 옵니다.
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // 입력 버퍼(Controller) 생성
          TextEditingController textController = TextEditingController();

          // 팝업창(Dialog) 띄우기
          showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: const Text('새로운 미션 추가'),
                content: TextField(
                  controller: textController,
                  decoration: const InputDecoration(
                    hintText: '예: 영양제 먹기',
                  ),
                  autofocus: true, // 창 뜨자마자 키보드 올리기
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context), // 취소
                    child: const Text('취소'),
                  ),
                  TextButton(
                    onPressed: () {
                      if (textController.text.isNotEmpty) {
                        // Provider에게 데이터 추가 요청 (Add Node)
                        context.read<MissionProvider>().addMission(textController.text);
                        Navigator.pop(context); // 창 닫기
                      }
                    },
                    child: const Text('추가'),
                  ),
                ],
              );
            },
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}