import 'package:dio/dio.dart';

import '../models/project.dart';
import 'api_client.dart';
import 'api_exception.dart';

class ProjectRepository {
  final ApiClient _client;
  const ProjectRepository(this._client);

  Future<List<Project>> fetchAll() async {
    try {
      final response = await _client.dio.get('/projects');
      final data = response.data as List;
      return data.map((json) => Project.fromJson(json)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<Project> fetchOne(String id) async {
    try {
      final response = await _client.dio.get('/projects/$id');
      return Project.fromJson(response.data);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<List<Project>> fetchMine() async {
    try {
      final response = await _client.dio.get('/my/projects');
      final data = response.data as List;
      return data.map((json) => Project.fromJson(json)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<Project> create(Map<String, dynamic> data) async {
    try {
      final response = await _client.dio.post('/my/projects', data: data);
      return Project.fromJson(response.data);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<Project> update(String id, Map<String, dynamic> data) async {
    try {
      final response = await _client.dio.put('/my/projects/$id', data: data);
      return Project.fromJson(response.data);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> delete(String id) async {
    try {
      await _client.dio.delete('/my/projects/$id');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<UnitType> addUnitType(String projectId, Map<String, dynamic> data) async {
    try {
      final response = await _client.dio.post('/my/projects/$projectId/unit-types', data: data);
      return UnitType.fromJson(response.data);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> deleteUnitType(String unitTypeId) async {
    try {
      await _client.dio.delete('/my/unit-types/$unitTypeId');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
