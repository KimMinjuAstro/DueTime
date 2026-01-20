import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart'; // [필수] 날짜 포맷팅 도구
import '../models/mission.dart';

class MissionProvider with ChangeNotifier {
  List<Mission> _missions = [];

  MissionProvider() {
    _loadMissions();
  }

  List<Mission> get missions => _missions;

  // [기능] 오늘 날짜 구하기 (예: "2024-05-20")
  String _getTodayDate() {
    // intl 패키지가 없으면 에러가 날 수 있으니, 터미널에 'flutter pub add intl' 확인해주세요.
    // 만약 귀찮으면 그냥 DateTime.now().toString().split(' ')[0] 써도 됩니다.
    return DateFormat('yyyy-MM-dd').format(DateTime.now());
    // return "2100-12-12";
  }

  Future<void> _loadMissions() async {
    final prefs = await SharedPreferences.getInstance();
    
    // 1. 저장된 날짜 확인
    final String? savedDate = prefs.getString('saved_date');
    final String todayDate = _getTodayDate();
    
    final String? jsonString = prefs.getString('mission_list');

    // 데이터가 없으면 초기화
    if (jsonString == null) {
      _initDefaultMissions();
      return;
    }

    // 2. 날짜 비교 (Reset Logic)
    if (savedDate != todayDate) {
      print("날짜가 변경되었습니다! ($savedDate -> $todayDate) 미션을 초기화합니다.");
      // 날짜가 다르면 -> 기존 데이터 불러오되, 체크(isCompleted)만 모두 false로 강제 변경
      List<dynamic> jsonList = jsonDecode(jsonString);
      _missions = jsonList.map((item) {
        Mission m = Mission.fromJson(item);
        m.isCompleted = false; // 강제 초기화
        return m;
      }).toList();
      
      // 초기화된 상태를 바로 저장해둠
      _saveMissions(); 
    } else {
      print("같은 날짜입니다. 상태를 유지합니다.");
      // 날짜가 같으면 -> 그냥 불러옴
      List<dynamic> jsonList = jsonDecode(jsonString);
      _missions = jsonList.map((item) => Mission.fromJson(item)).toList();
    }
    
    notifyListeners();
  }

  void _initDefaultMissions() {
    _missions = [
    Mission(id: '1', title: '아침 8시에 기상하기'),
    Mission(id: '2', title: '아침 약 먹기'),
    Mission(id: '3', title: '따듯한 물 한 잔 마시기'),
    Mission(id: '4', title: '창문 환기하기'),
    Mission(id: '5', title: '저녁 음식 준비해놓기'),];
    notifyListeners();
  }

  Future<void> _saveMissions() async {
    final prefs = await SharedPreferences.getInstance();
    String jsonString = jsonEncode(_missions.map((m) => m.toJson()).toList());
    
    await prefs.setString('mission_list', jsonString);
    // ★ 핵심: 저장할 때 "오늘 날짜"도 같이 도장을 찍어둠
    await prefs.setString('saved_date', _getTodayDate());
  }

  void toggleMission(String id) {
    final index = _missions.indexWhere((m) => m.id == id);
    if (index != -1) {
      _missions[index].isCompleted = !_missions[index].isCompleted;
      notifyListeners();
      _saveMissions();
    }
  }

  // [기능 4] 미션 인증샷 경로 저장 (추가된 코드)
  void setMissionImage(String id, String imagePath) {
    final index = _missions.indexWhere((m) => m.id == id);
    if (index != -1) {
      _missions[index].imagePath = imagePath;
      _missions[index].isCompleted = true; // 사진 찍으면 자동으로 완료 처리 (옵션)
      
      notifyListeners();
      _saveMissions();
    }
  }

  // [기능 5] 새로운 미션 추가하기 (Create)
  void addMission(String title) {
    // 1. 새로운 객체 생성 (Memory Allocation)
    final newMission = Mission(
      // ID는 겹치지 않게 현재 시간(Timestamp)을 사용
      id: DateTime.now().toString(), 
      title: title,
    );
    
    // 2. 리스트에 추가 (Append)
    _missions.add(newMission);
    
    // 3. 알림 및 저장 (Update & Save)
    notifyListeners();
    _saveMissions();
  }
  
  // [기능 6] 미션 삭제하기 (Delete) - 친구가 추가하다가 오타 낼 수도 있으니까 서비스로 넣어둡시다.
  void deleteMission(String id) {
    _missions.removeWhere((m) => m.id == id);
    notifyListeners();
    _saveMissions();
  }

  int get completedCount {
    return _missions.where((m) => m.isCompleted).length;
  }
}