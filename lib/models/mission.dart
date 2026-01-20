class Mission {
  final String id;        // 고유 ID (인덱스 역할)
  final String title;     // 미션 이름 (예: "물 마시기")
  bool isCompleted;       // 성공 여부 (Flag)
  String? imagePath;      // 인증샷 경로 (NULL 가능)

  Mission({
    required this.id,
    required this.title,
    this.isCompleted = false,
    this.imagePath,       // 사진은 처음엔 없으니까 null
  });

  // [직렬화] Struct -> JSON (저장할 때 사용)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'isCompleted': isCompleted,
      'imagePath': imagePath,
    };
  }

  // [역직렬화] JSON -> Struct (불러올 때 사용)
  factory Mission.fromJson(Map<String, dynamic> json) {
    return Mission(
      id: json['id'],
      title: json['title'],
      isCompleted: json['isCompleted'],
      imagePath: json['imagePath'],
    );
  }
}

// 기획서에 따른 고정된 미션 리스트 (Hardcoded List)
final List<Mission> defaultMissions = [
  Mission(id: '1', title: '아침 8시에 기상하기'),
  Mission(id: '2', title: '아침 약 먹기'),
  Mission(id: '3', title: '따듯한 물 한 잔 마시기'),
  Mission(id: '4', title: '창문 환기하기'),
  Mission(id: '5', title: '저녁 음식 준비해놓기'),
];