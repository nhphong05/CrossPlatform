import '../models/lecturer.dart';

abstract interface class LecturerRepository {
  Future<List<Lecturer>> getAll();

  Future<void> create(LecturerDraft lecturer);

  Future<void> update(Lecturer lecturer);

  Future<void> delete(String id);
}
