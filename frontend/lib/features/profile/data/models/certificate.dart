class Certificate {
  final String id;
  final String certificateNumber;
  final String courseName;
  final String pdfUrl;
  final DateTime issuedAt;
  final String studentName;

  Certificate({
    required this.id,
    required this.certificateNumber,
    required this.courseName,
    required this.pdfUrl,
    required this.issuedAt,
    required this.studentName,
  });

  factory Certificate.fromJson(Map<String, dynamic> json) {
    return Certificate(
      id: json['id'],
      certificateNumber: json['certificate_number'],
      courseName: json['course_name'],
      pdfUrl: json['pdf_url'] ?? '',
      issuedAt: DateTime.parse(json['issued_at']),
      studentName: json['student_name'],
    );
  }
}
