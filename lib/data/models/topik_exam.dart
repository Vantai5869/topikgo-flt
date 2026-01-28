class TOPIKOption {
  final String id;
  final String? text;
  final String? imageSrc;
  final String? alt;
  final bool isCorrect;

  TOPIKOption({
    required this.id,
    this.text,
    this.imageSrc,
    this.alt,
    required this.isCorrect,
  });

  factory TOPIKOption.fromJson(Map<String, dynamic> json) {
    return TOPIKOption(
      id: json['id'] ?? '',
      text: json['text'],
      imageSrc: json['image_src'],
      alt: json['alt'],
      isCorrect: json['is_correct'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (text != null) 'text': text,
      if (imageSrc != null) 'image_src': imageSrc,
      if (alt != null) 'alt': alt,
      'is_correct': isCorrect,
    };
  }
}

class TOPIKOrderingItem {
  final String marker;
  final String text;

  TOPIKOrderingItem({required this.marker, required this.text});

  factory TOPIKOrderingItem.fromJson(Map<String, dynamic> json) {
    return TOPIKOrderingItem(
      marker: json['marker'] ?? '',
      text: json['text'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'marker': marker,
      'text': text,
    };
  }
}

class TOPIKQuestionContent {
  final String type; // 'audio_prompt' | 'text_prompt' | 'image_prompt' | 'text' | 'image' | 'insertion_task' | 'ordering_task'
  final String? value;
  final String? src;
  final String? alt;
  final String? sentenceToInsert;
  final List<TOPIKOrderingItem>? items;
  final List<String>? markers;

  TOPIKQuestionContent({
    required this.type,
    this.value,
    this.src,
    this.alt,
    this.sentenceToInsert,
    this.items,
    this.markers,
  });

  factory TOPIKQuestionContent.fromJson(Map<String, dynamic> json) {
    return TOPIKQuestionContent(
      type: json['type'] ?? 'text',
      value: json['value'],
      src: json['src'],
      alt: json['alt'],
      sentenceToInsert: json['sentence_to_insert'],
      items: (json['items'] as List?)?.map((e) => TOPIKOrderingItem.fromJson(e)).toList(),
      markers: (json['markers'] as List?)?.map((e) => e.toString()).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      if (value != null) 'value': value,
      if (src != null) 'src': src,
      if (alt != null) 'alt': alt,
      if (sentenceToInsert != null) 'sentence_to_insert': sentenceToInsert,
      if (items != null) 'items': items!.map((e) => e.toJson()).toList(),
      if (markers != null) 'markers': markers,
    };
  }
}

class TOPIKQuestion {
  final String id;
  final int number;
  final int points;
  final String? optionType; // 'text' | 'image'
  final TOPIKQuestionContent content;
  final List<TOPIKOption> options;
  final String? questionAudioUrl;
  final String? questionImageUrl;

  TOPIKQuestion({
    required this.id,
    required this.number,
    required this.points,
    this.optionType,
    required this.content,
    required this.options,
    this.questionAudioUrl,
    this.questionImageUrl,
  });

  factory TOPIKQuestion.fromJson(Map<String, dynamic> json) {
    return TOPIKQuestion(
      id: json['id'] ?? '',
      number: json['number'] ?? 0,
      points: json['points'] ?? 0,
      optionType: json['option_type'],
      content: TOPIKQuestionContent.fromJson(json['content'] ?? {}),
      options: (json['options'] as List?)
              ?.map((e) => TOPIKOption.fromJson(e))
              .toList() ??
          [],
      questionAudioUrl: json['question_audio_url'],
      questionImageUrl: json['question_image_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'number': number,
      'points': points,
      if (optionType != null) 'option_type': optionType,
      'content': content.toJson(),
      'options': options.map((e) => e.toJson()).toList(),
      if (questionAudioUrl != null) 'question_audio_url': questionAudioUrl,
      if (questionImageUrl != null) 'question_image_url': questionImageUrl,
    };
  }
}

class TOPIKExample {
  final String title;
  final String questionText;
  final List<TOPIKOption> options;

  TOPIKExample({
    required this.title,
    required this.questionText,
    required this.options,
  });

  factory TOPIKExample.fromJson(Map<String, dynamic> json) {
    return TOPIKExample(
      title: json['title'] ?? '',
      questionText: json['question_text'] ?? '',
      options: (json['options'] as List?)
              ?.map((e) => TOPIKOption.fromJson(e))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'question_text': questionText,
      'options': options.map((e) => e.toJson()).toList(),
    };
  }
}

class TOPIKInstructionGroup {
  final String type;
  final String instruction;
  final TOPIKExample example;
  final List<TOPIKQuestion> questions;
  final TOPIKQuestionContent? sharedContent;
  final String? groupAudioUrl; // Audio shared for all questions in this group

  TOPIKInstructionGroup({
    required this.type,
    required this.instruction,
    required this.example,
    required this.questions,
    this.sharedContent,
    this.groupAudioUrl,
  });

  factory TOPIKInstructionGroup.fromJson(Map<String, dynamic> json) {
    return TOPIKInstructionGroup(
      type: json['type'] ?? 'instruction_group',
      instruction: json['instruction'] ?? '',
      example: TOPIKExample.fromJson(json['example'] ?? {}),
      questions: (json['questions'] as List?)
              ?.map((e) => TOPIKQuestion.fromJson(e))
              .toList() ??
          [],
      sharedContent: json['shared_content'] != null
          ? TOPIKQuestionContent.fromJson(json['shared_content'])
          : null,
      groupAudioUrl: json['group_audio_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'instruction': instruction,
      'example': example.toJson(),
      'questions': questions.map((e) => e.toJson()).toList(),
      if (sharedContent != null) 'shared_content': sharedContent!.toJson(),
      if (groupAudioUrl != null) 'group_audio_url': groupAudioUrl,
    };
  }
}

class TOPIKExam {
  final String id;
  final String yearDescription;
  final String examNumberDescription;
  final String source;
  final String level; // 'TOPIK Ⅰ' | 'TOPIK Ⅱ'
  final String skill; // '듣기' | '읽기' | '쓰기'
  final String? audioUrl;
  final List<TOPIKInstructionGroup> instructionGroups;

  TOPIKExam({
    required this.id,
    required this.yearDescription,
    required this.examNumberDescription,
    required this.source,
    required this.level,
    required this.skill,
    this.audioUrl,
    required this.instructionGroups,
  });

  factory TOPIKExam.fromJson(Map<String, dynamic> json) {
    return TOPIKExam(
      id: json['id'] ?? '',
      yearDescription: json['year_description'] ?? '',
      examNumberDescription: json['exam_number_description'] ?? '',
      source: json['source'] ?? '',
      level: json['level'] ?? '',
      skill: json['skill'] ?? '',
      audioUrl: json['audio_url'],
      instructionGroups: (json['instruction_groups'] as List?)
              ?.map((e) => TOPIKInstructionGroup.fromJson(e))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'year_description': yearDescription,
      'exam_number_description': examNumberDescription,
      'source': source,
      'level': level,
      'skill': skill,
      if (audioUrl != null) 'audio_url': audioUrl,
      'instruction_groups': instructionGroups.map((e) => e.toJson()).toList(),
    };
  }

  // Helper method to get total questions
  int get totalQuestions {
    return instructionGroups.fold(
      0,
      (sum, group) => sum + group.questions.length,
    );
  }
}
