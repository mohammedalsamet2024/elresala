import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:elresala/core/errors/failures.dart';
import 'package:elresala/core/helpers/get_failure_from_exception.dart';
import 'package:elresala/core/services/api_service.dart';
import 'package:elresala/core/services/shared_preferences_service.dart';
import 'package:elresala/features/main/domain/entities/info_file_entity.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:get/get.dart';
import 'package:logger/logger.dart';

class FirebaseStorageService extends GetxService {
  final ApiService apiService;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  FirebaseStorageService({required this.apiService});

  Future<List<String>> getLanguages() async {
    try {
      Get.find<Logger>().i("Start `getLanguages` in |FileService|");
      ListResult result = await _storage.ref().listAll();
      List<String> languages = result.items.map((item) => item.name.split('.').first).toList();
      Get.find<Logger>().w("End `getLanguages` in |FileService|");
      return languages;
    } catch (e) {
      Get.find<Logger>().e(
        "End `getLanguages` in |FileService| Exception: ${e.runtimeType}",
      );
      rethrow;
    }
  }

  Future<List<InfoFile>> getInfoFilesOfLanguage({required String language}) async {
    try {
      Get.find<Logger>().i("Start `getInfoFilesOfLanguage` in |FileService|");
      ListResult result = await _storage.ref(language).listAll();

      List<String> downloadURLs = await Future.wait(
        result.items.map((item) => item.getDownloadURL()),
      );
      List<String> names = result.items.map((item) => item.name).toList();
      List<InfoFile> infoFiles = [];
      for (int i = 0; i < names.length; i++) {
        infoFiles.add(InfoFile(
          name: "$language/${names[i]}",
          downloadUrl: downloadURLs[i],
        ));
      }
      Get.find<Logger>().w("End `getInfoFilesOfLanguage` in |FileService|");
      return infoFiles;
    } catch (e) {
      Get.find<Logger>().e(
        "End `getInfoFilesOfLanguage` in |FileService| Exception: ${e.runtimeType}",
      );
      rethrow;
    }
  }

  Future<InfoFile> getInfoFile({
    required String language,
    required String name,
  }) async {
    try {
      Get.find<Logger>().i("Start `getInfoFile` in |FileService|");
      String downloadURL = await _storage.ref("$language/$name").getDownloadURL();
      Get.find<Logger>().w("End `getInfoFile` in |FileService|");
      return InfoFile(name: "$language/$name", downloadUrl: downloadURL);
    } catch (e) {
      Get.find<Logger>().e(
        "End `getInfoFile` in |FileService| Exception: ${e.runtimeType}",
      );
      rethrow;
    }
  }

  Future<String> downloadFile({
    required InfoFile infoFile,
    required Function(double progress) onProgress,
  }) async {
    try {
      Get.find<Logger>().i("Start `getInfoFiles` in |FileService|");
      String path = await apiService.downloadFile(
        url: infoFile.downloadUrl,
        subPath: infoFile.name,
        onProgress: onProgress,
      );
      Get.find<Logger>().w("End `getInfoFiles` in |FileService|");
      await Get.find<SharedPreferencesService>().setData(key: infoFile.name, value: path);
      return path;
    } catch (e) {
      Get.find<Logger>().e(
        "End `getInfoFiles` in |FileService| Exception: ${e.runtimeType}",
      );
      rethrow;
    }
  }

  Future<Either<Failure, Unit>> downloadFiles({
    required String language,
    required Function(int totalFiles, int downloadedFiles) onProgressFiles,
    required Function(double progress) onProgressFile,
  }) async {
    try {
      Get.find<Logger>().i("Start `downloadFiles` in |FileService|");
      bool? isAlreadyDownload = Get.find<SharedPreferencesService>().getData<bool>(
        key: "$language is Downloaded",
      );
      if (isAlreadyDownload != null && isAlreadyDownload) {
        return const Right(unit);
      }
      List<InfoFile> infoFiles = await getInfoFilesOfLanguage(language: language);
      for (int i = 0; i < infoFiles.length; i++) {
        onProgressFiles(infoFiles.length, i + 1);
        await downloadFile(
          infoFile: infoFiles[i],
          onProgress: onProgressFile,
        );
      }
      await Get.find<SharedPreferencesService>().setData(key: "$language is Downloaded", value: true);
      Get.find<Logger>().w("End `downloadFiles` in |FileService|");
      return const Right(unit);
    } catch (e) {
      Get.find<Logger>().e("End `downloadFiles` in |FileService| Exception: ${e.runtimeType}");
      return Left(getFailureFromException(e));
    }
  }

  Future<String?> readFile({
    required String language,
    required String name,
    Function()? onFileNotFound,
  }) async {
    try {
      Get.find<Logger>().i("Start `readFile` in |FileService|");
      String? path = Get.find<SharedPreferencesService>().getData<String>(key: "$language/$name");
      if (path != null) {
        final file = File(path);
        if (await file.exists()) {
          String fileContent = await file.readAsString();
          Get.find<Logger>().w("End `readFile` in |FileService|");
          return fileContent;
        } else {
          Get.find<SharedPreferencesService>().setData(key: "$language/$name", value: null);
          onFileNotFound?.call();
          return null;
        }
      }
      onFileNotFound?.call();
      return null;
    } catch (e) {
      Get.find<Logger>().e("End `readFile` in |FileService| Exception: ${e.runtimeType}");
      rethrow;
    }
  }
}