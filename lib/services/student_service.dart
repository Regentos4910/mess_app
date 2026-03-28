import '../models/student.dart';

class StudentService {
  const StudentService();

  List<Student> sortStudents(Iterable<Student> students) {
    final List<Student> items = students.toList()
      ..sort(
        (Student a, Student b) => a.name.toLowerCase().compareTo(
              b.name.toLowerCase(),
            ),
      );
    return items;
  }

  List<Student> search(Iterable<Student> students, String query) {
    final String needle = query.trim().toLowerCase();
    if (needle.isEmpty) {
      return sortStudents(students);
    }

    return sortStudents(
      students.where(
        (Student student) =>
            student.name.toLowerCase().contains(needle) ||
            student.prn.toLowerCase().contains(needle) ||
            student.courseName.toLowerCase().contains(needle) ||
            student.division.toLowerCase().contains(needle),
      ),
    );
  }
}
