class Question {
  final int id;
  final String grade;
  final String subject;
  final int topicId;
  final String question;
  final String? imageUrl;
  final Map<String, dynamic> options;
  final String correctAnswer;

  Question({
    required this.id,
    required this.grade,
    required this.subject,
    required this.topicId,
    required this.question,
    this.imageUrl,
    required this.options,
    required this.correctAnswer,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'],
      grade: json['grade'],
      subject: json['subject'],
      topicId: json['topic_id'],
      question: json['question'],
      imageUrl: json['image_url'],
      options: json['options'],
      correctAnswer: json['correct_answer'],
    );
  }
}