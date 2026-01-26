/// Hardcoded instruction lists matching React Native implementation
/// These define the question ranges for each instruction type
class Instructions {
  static const Map<String, Map<String, List<String>>> hardcodedInstructions = {
    'TOPIK Ⅱ': {
      '듣기': [
        '[1~3] 다음을 듣고 가장 알맞은 그림 또는 그래프를 고르십시오.',
        '[4~8] 다음을 듣고 이어질 수 있는 말로 가장 알맞은 것을 고르십시오.',
        '[9~12] 다음을 듣고 여자가 이어서 할 행동으로 가장 알맞은 것을 고르십시오.',
        '[13~16] 다음을 듣고 들은 내용과 같은 것을 고르십시오.',
        '[17~20] 다음을 듣고 남자의 중심 생각으로 가장 알맞은 것을 고르십시오.',
        '[21~36] 다음을 듣고 물음에 답하십시오.',
        '[37~50] 다음은 (교양 프로그램/강연/다큐멘터리)입니다. 잘 듣고 물음에 답하십시오.',
      ],
      '읽기': [
        '[1~2] ( )에 들어갈 말로 가장 알맞은 것을 고르십시오.',
        '[3~4] 밑줄 친 부분과 의미가 가장 비슷한 것을 고르십시오.',
        '[5~8] 다음은 무엇에 대한 글인지 고르십시오.',
        '[9~12] 다음 글 또는 그래프의 내용과 같은 것을 고르십시오.',
        '[13~15] 다음을 순서에 맞게 배열한 것을 고르십시오.',
        '[16~18] ( )에 들어갈 말로 가장 알맞은 것을 고르십시오.',
        '[19~24] 다음을 읽고 물음에 답하십시오.',
        '[25~27] 다음 신문 기사의 제목을 가장 잘 설명한 것을 고르십시오.',
        '[28~31] ( )에 들어갈 말로 가장 알맞은 것을 고르십시오.',
        '[32~34] 다음을 읽고 글의 내용과 같은 것을 고르십시오.',
        '[35~38] 다음을 읽고 글의 주제로 가장 알맞은 것을 고르십시오.',
        '[39~41] 주어진 문장이 들어갈 곳으로 가장 알맞은 것을 고르십시오.',
        '[42~47] 다음을 읽고 물음에 답하십시오.',
        '[48~50] 다음을 읽고 물음에 답하십시오.',
      ],
    },
    'TOPIK Ⅰ': {
      '듣기': [
        '[1~4] 다음을 듣고 <보기>와 같이 물음에 맞는 대답을 고르십시오.',
        '[5~6] 다음을 듣고 <보기>와 같이 이어지는 말을 고르십시오.',
        '[7~10] 여기는 어디입니까? <보기>와 같이 알맞은 것을 고르십시오.',
        '[11~14] 다음은 무엇에 대해 말하고 있습니까? <보기>와 같이 알맞은 것을 고르십시오.',
        '[15~16] 다음 대화를 듣고 알맞은 그림을 고르십시오.',
        '[17~21] 다음을 듣고 <보기>와 같이 대화 내용과 같은 것을 고르십시오.',
        '[22~24] 다음을 듣고 여자의 중심 생각을 고르십시오.',
        '[25~30] 다음을 듣고 물음에 답하십시오.',
      ],
      '읽기': [
        '[31~33] 무엇에 대한 이야기입니까? <보기>와 같이 알맞은 것을 고르십시오.',
        '[34~39] <보기>와 같이 ( )에 들어갈 말로 가장 알맞은 것을 고르십시오.',
        '[40~42] 다음을 읽고 맞지 않는 것을 고르십시오.',
        '[43~45] 다음을 읽고 내용이 같은 것을 고르십시오.',
        '[46~48] 다음을 읽고 중심 생각을 고르십시오.',
        '[49~56] 다음을 읽고 물음에 답하십시오.',
        '[57~58] 다음을 순서에 맞게 배열한 것을 고르십시오.',
        '[59~70] 다음을 읽고 물음에 답하십시오.',
      ],
    },
  };

  /// Extract question range from instruction
  /// Example: "[1~3] ..." returns {start: 1, end: 3}
  static Map<String, int>? extractRange(String instruction) {
    final regex = RegExp(r'\[(\d+)~(\d+)\]');
    final match = regex.firstMatch(instruction);
    
    if (match != null) {
      return {
        'start': int.parse(match.group(1)!),
        'end': int.parse(match.group(2)!),
      };
    }
    return null;
  }

  /// Check if question number is in range
  static bool isNumberInRange(int number, List<Map<String, int>> ranges) {
    return ranges.any((range) => 
      number >= range['start']! && number <= range['end']!
    );
  }

  /// Normalize instruction for display (remove <보기> tags)
  static String normalizeInstruction(String instruction) {
    return instruction
        .replaceAll('<보기>', '')
        .replaceAll('<보기와 같이>', '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Get instructions for level and skill
  static List<String> getInstructions(String level, String skill) {
    return hardcodedInstructions[level]?[skill] ?? [];
  }
}
