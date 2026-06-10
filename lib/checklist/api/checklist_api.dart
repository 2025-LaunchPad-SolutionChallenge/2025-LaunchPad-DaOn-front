import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:project_daon/checklist/model/attachment_model.dart';
import 'package:project_daon/checklist/widget/checkItemWidget.dart';
import 'package:project_daon/core/service/auth_service.dart';

class UploadedChecklistAttachmentFile {
  final String fileUrl;
  final String storagePath;
  final String originalFileName;
  final String mimeType;
  final int fileSize;
  final String? thumbnailUrl;

  const UploadedChecklistAttachmentFile({
    required this.fileUrl,
    required this.storagePath,
    required this.originalFileName,
    required this.mimeType,
    required this.fileSize,
    this.thumbnailUrl,
  });

  Map<String, dynamic> toAttachmentBody(String attachmentType) {
    return {
      'attachmentType': attachmentType,
      'content': null,
      'fileUrl': fileUrl,
      'originalFileName': originalFileName,
      'mimeType': mimeType,
      'fileSize': fileSize,
      'thumbnailUrl': thumbnailUrl,
    };
  }
}

class ChecklistResult {
  final List<ChecklistItemModel> items;
  final double completionRate;
  ChecklistResult({required this.items, required this.completionRate});
}

class ChecklistApi {
  final Dio _dio = AuthService().dio;

  static String _fmtDate(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  Future<ChecklistResult> fetchChecklist(
    int userDisasterId,
    DateTime date,
  ) async {
    final dateStr = _fmtDate(date);
    if (kDebugMode) {
      debugPrint(
        '[체크리스트] GET /api/v1/disasters/$userDisasterId/checklist?date=$dateStr',
      );
    }
    final response = await _dio.get(
      '/api/v1/disasters/$userDisasterId/checklist',
      queryParameters: {'date': dateStr},
    );
    if (kDebugMode) {
      debugPrint(
        '[체크리스트] GET 응답 status=${response.statusCode} data=${response.data}',
      );
    }
    final data = response.data;
    List<dynamic> raw = [];
    double completionRate = 0.0;
    if (data is Map) {
      completionRate = (data['completionRate'] as num?)?.toDouble() ?? 0.0;
      final days = data['days'];
      if (days is List) {
        for (final day in days) {
          if (day is Map && day['checklistDate'] == dateStr) {
            raw = (day['items'] as List?) ?? [];
            break;
          }
        }
        if (raw.isEmpty && days.isNotEmpty && days.first is Map) {
          raw = ((days.first as Map)['items'] as List?) ?? [];
        }
      } else if (days is Map) {
        final dayData = days[dateStr];
        if (dayData is Map) {
          raw = (dayData['items'] as List?) ?? [];
        } else if (dayData is List) {
          raw = dayData;
        }
      }
    } else if (data is List) {
      raw = data;
    }
    final items = raw
        .map((e) => _itemFromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    return ChecklistResult(items: items, completionRate: completionRate);
  }

  Future<int> addChecklistItem({
    required int userDisasterId,
    required String title,
    required String checklistDate,
    int priority = 2,
  }) async {
    if (kDebugMode) {
      debugPrint(
        '[체크리스트] POST /api/v1/disasters/$userDisasterId/checklist '
        'body={title: $title, checklistDate: $checklistDate, priority: $priority}',
      );
    }
    final response = await _dio.post(
      '/api/v1/disasters/$userDisasterId/checklist',
      data: {
        'title': title,
        'checklistDate': checklistDate,
        'priority': priority,
      },
    );
    if (kDebugMode) {
      debugPrint('[체크리스트] POST 추가 응답: ${response.statusCode} ${response.data}');
    }
    final rawData = response.data;
    final id = rawData is Map
        ? ((rawData['checklistItemId']) as num?)?.toInt() ?? 0
        : 0;
    return id;
  }

  Future<void> editChecklistItem({
    required int userDisasterId,
    required int checklistItemId,
    required String title,
    required String checklistDate,
    required bool isCompleted,
    int priority = 2,
  }) async {
    if (kDebugMode) {
      debugPrint(
        '[체크리스트] PATCH /api/v1/disasters/$userDisasterId/checklist/$checklistItemId '
        'body={title: $title, checklistDate: $checklistDate, isCompleted: $isCompleted, priority: $priority}',
      );
    }
    final response = await _dio.patch(
      '/api/v1/disasters/$userDisasterId/checklist/$checklistItemId',
      data: {
        'title': title,
        'checklistDate': checklistDate,
        'isCompleted': isCompleted,
        'priority': priority,
      },
    );
    if (kDebugMode) {
      debugPrint(
        '[체크리스트] PATCH 편집 응답: ${response.statusCode} ${response.data}',
      );
    }
  }

  Future<void> updateChecklistStatus({
    required int userDisasterId,
    required int checklistItemId,
    required bool isCompleted,
  }) async {
    if (kDebugMode) {
      debugPrint(
        '[체크리스트] PATCH /api/v1/disasters/$userDisasterId/checklist/$checklistItemId/status '
        'body={isCompleted: $isCompleted}',
      );
    }
    final response = await _dio.patch(
      '/api/v1/disasters/$userDisasterId/checklist/$checklistItemId/status',
      data: {'isCompleted': isCompleted},
    );
    if (kDebugMode) {
      debugPrint(
        '[체크리스트] PATCH 상태 응답: ${response.statusCode} ${response.data}',
      );
    }
  }

  Future<void> deleteChecklistItem({
    required int userDisasterId,
    required int checklistItemId,
  }) async {
    if (kDebugMode) {
      debugPrint(
        '[체크리스트] DELETE /api/v1/disasters/$userDisasterId/checklist/$checklistItemId',
      );
    }
    final response = await _dio.delete(
      '/api/v1/disasters/$userDisasterId/checklist/$checklistItemId',
    );
    if (kDebugMode) {
      debugPrint('[체크리스트] DELETE 응답: ${response.statusCode} ${response.data}');
    }
  }

  Future<void> saveContext({
    required int userDisasterId,
    required bool canGoOut,
    required String availableTime,
    required String specialNotes,
  }) async {
    if (kDebugMode) debugPrint('[체크리스트] 컨텍스트 저장');
    await _dio.post(
      '/api/v1/checklists/context',
      data: {
        'userDisasterId': userDisasterId,
        'userCondition': {
          'canGoOut': canGoOut,
          'availableTime': availableTime,
          'specialNotes': specialNotes,
        },
      },
    );
  }

  Future<void> generateAiChecklist({
    required int userDisasterId,
    required DateTime date,
  }) async {
    final dateStr = _fmtDate(date);
    if (kDebugMode) {
      debugPrint('[체크리스트] AI 생성 요청: disasterId=$userDisasterId date=$dateStr');
    }
    try {
      await _dio.post(
        '/api/v1/checklists/ai-generate',
        data: {'userDisasterId': userDisasterId, 'targetDate': dateStr},
        options: Options(receiveTimeout: const Duration(seconds: 60)),
      );
    } on DioException catch (e) {
      if (e.type != DioExceptionType.receiveTimeout) rethrow;
      if (kDebugMode) debugPrint('[체크리스트] AI 생성 응답 대기 시간 초과 (정상)');
    }
  }

  static const int _maxAttachmentFileSize = 10 * 1024 * 1024;

  /// 체크리스트 첨부 파일/이미지를 Firebase Storage에 먼저 업로드합니다.
  ///
  /// Storage 경로는 Firebase Rules와 맞추기 위해 아래 형태를 사용합니다.
  /// users/{firebaseUid}/checklist_attachments/{userDisasterId}/{checklistItemId}/{fileName}
  ///
  /// 업로드 성공 후 반환된 fileUrl을 addAttachment()의 body에 넣어 백엔드에 저장해야 합니다.
  Future<UploadedChecklistAttachmentFile> uploadChecklistAttachmentFile({
    required int userDisasterId,
    required int checklistItemId,
    required File file,
    required String originalFileName,
    required String mimeType,
    String? thumbnailUrl,
  }) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception('Firebase 로그인 정보가 없습니다. 다시 로그인해 주세요.');
    }

    final fileSize = await file.length();

    if (fileSize > _maxAttachmentFileSize) {
      throw Exception('10MB 이하의 파일만 첨부할 수 있습니다.');
    }

    final normalizedMimeType = mimeType.trim().isEmpty
        ? _guessMimeType(originalFileName)
        : mimeType.trim();
    final safeFileName = _safeStorageFileName(originalFileName);
    final storageFileName =
        '${DateTime.now().millisecondsSinceEpoch}_$safeFileName';
    final storagePath =
        'users/${user.uid}/checklist_attachments/$userDisasterId/$checklistItemId/$storageFileName';
    final ref = FirebaseStorage.instance.ref().child(storagePath);

    if (kDebugMode) {
      debugPrint('[파일 업로드] uid=${user.uid}');
      debugPrint('[파일 업로드] path=$storagePath');
      debugPrint('[파일 업로드] userDisasterId=$userDisasterId');
      debugPrint('[파일 업로드] checklistItemId=$checklistItemId');
      debugPrint('[파일 업로드] originalFileName=$originalFileName');
      debugPrint('[파일 업로드] mimeType=$normalizedMimeType');
      debugPrint('[파일 업로드] fileSize=$fileSize');
      final idToken = await user.getIdToken(false);
      debugPrint(
        '[파일 업로드] hasFirebaseIdToken=${idToken != null && idToken.isNotEmpty}',
      );
    }

    try {
      await ref.putFile(
        file,
        SettableMetadata(
          contentType: normalizedMimeType,
          customMetadata: {
            'userDisasterId': userDisasterId.toString(),
            'checklistItemId': checklistItemId.toString(),
            'originalFileName': originalFileName,
          },
        ),
      );

      final fileUrl = await ref.getDownloadURL();

      if (kDebugMode) {
        debugPrint('[파일 업로드] 성공 url=$fileUrl');
      }

      return UploadedChecklistAttachmentFile(
        fileUrl: fileUrl,
        storagePath: storagePath,
        originalFileName: originalFileName,
        mimeType: normalizedMimeType,
        fileSize: fileSize,
        thumbnailUrl: thumbnailUrl,
      );
    } on FirebaseException catch (e) {
      if (kDebugMode) {
        debugPrint('[파일 업로드] Firebase 오류: ${e.code} ${e.message}');
      }

      if (e.code == 'unauthorized') {
        throw Exception(
          '파일 업로드 권한이 없습니다. Firebase Storage 경로와 Rules를 확인해 주세요.',
        );
      }

      throw Exception(e.message ?? '파일 업로드 중 오류가 발생했습니다.');
    }
  }

  /// 이미지/파일 업로드 후 백엔드 첨부 저장까지 한 번에 처리할 때 사용합니다.
  Future<int> uploadAndAddFileAttachment({
    required int userDisasterId,
    required int checklistItemId,
    required File file,
    required String originalFileName,
    required String mimeType,
    required String attachmentType,
    String? thumbnailUrl,
  }) async {
    if (attachmentType != 'IMAGE' && attachmentType != 'FILE') {
      throw Exception('attachmentType은 IMAGE 또는 FILE이어야 합니다.');
    }

    final uploaded = await uploadChecklistAttachmentFile(
      userDisasterId: userDisasterId,
      checklistItemId: checklistItemId,
      file: file,
      originalFileName: originalFileName,
      mimeType: mimeType,
      thumbnailUrl: thumbnailUrl,
    );

    return addAttachment(
      userDisasterId,
      checklistItemId,
      uploaded.toAttachmentBody(attachmentType),
    );
  }

  String _safeStorageFileName(String fileName) {
    final trimmed = fileName.trim().isEmpty ? 'attachment' : fileName.trim();
    return trimmed.replaceAll(RegExp(r'[\\/:*?"<>|#%{}\[\]`~]'), '_');
  }

  String _guessMimeType(String fileName) {
    final lower = fileName.toLowerCase();

    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) {
      return 'image/jpeg';
    }
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.pdf')) return 'application/pdf';
    if (lower.endsWith('.txt')) return 'text/plain';
    if (lower.endsWith('.doc')) return 'application/msword';
    if (lower.endsWith('.docx')) {
      return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
    }
    if (lower.endsWith('.xls')) return 'application/vnd.ms-excel';
    if (lower.endsWith('.xlsx')) {
      return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
    }
    if (lower.endsWith('.ppt')) return 'application/vnd.ms-powerpoint';
    if (lower.endsWith('.pptx')) {
      return 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
    }
    if (lower.endsWith('.zip')) return 'application/zip';

    return 'application/octet-stream';
  }

  ChecklistItemModel _itemFromJson(Map<String, dynamic> json) {
    final checklistItemId =
        ((json['checklistItemId'] ?? json['id']) as num?)?.toInt() ?? 0;
    final rawSummary = json['attachmentSummary'];
    Map<String, int>? attachmentSummary;
    if (rawSummary is Map) {
      attachmentSummary = {};
      rawSummary.forEach((k, v) {
        attachmentSummary![k.toString()] = (v as num?)?.toInt() ?? 0;
      });
    }
    return ChecklistItemModel(
      checklistItemId: checklistItemId,
      title: json['title']?.toString() ?? '',
      isAiGenerated: json['isAiGenerated'] as bool? ?? false,
      isChecked: json['isCompleted'] as bool? ?? false,
      memo: json['memo']?.toString(),
      priority: (json['priority'] as num?)?.toInt() ?? 2,
      checklistDate: json['checklistDate']?.toString(),
      attachmentSummary: attachmentSummary,
    );
  }

  Future<List<AttachmentModel>> fetchChecklistDetail(
    int userDisasterId,
    int checklistItemId,
  ) async {
    if (kDebugMode) {
      debugPrint(
        '[체크리스트] GET /api/v1/disasters/$userDisasterId/checklist/$checklistItemId',
      );
    }
    final response = await _dio.get(
      '/api/v1/disasters/$userDisasterId/checklist/$checklistItemId',
    );
    if (kDebugMode) {
      debugPrint('[체크리스트] 상세 응답: ${response.statusCode} ${response.data}');
    }
    final data = response.data;
    List<dynamic> rawAttachments = [];
    if (data is Map) {
      rawAttachments = (data['attachments'] as List?) ?? [];
    }
    return rawAttachments.map((e) {
      final map = Map<String, dynamic>.from(e as Map);
      map['checklistItemId'] = checklistItemId;
      return AttachmentModel.fromJson(map);
    }).toList();
  }

  Future<int> addAttachment(
    int userDisasterId,
    int checklistItemId,
    Map<String, dynamic> body,
  ) async {
    if (kDebugMode) {
      debugPrint(
        '[체크리스트] POST /api/v1/disasters/$userDisasterId/checklist/$checklistItemId/attachments '
        'body=$body',
      );
    }
    final response = await _dio.post(
      '/api/v1/disasters/$userDisasterId/checklist/$checklistItemId/attachments',
      data: body,
    );
    if (kDebugMode) {
      debugPrint('[체크리스트] 첨부 추가 응답: ${response.statusCode} ${response.data}');
    }
    final raw = response.data;
    return raw is Map ? ((raw['attachmentId']) as num?)?.toInt() ?? 0 : 0;
  }

  Future<void> editAttachment(
    int userDisasterId,
    int checklistItemId,
    int attachmentId,
    Map<String, dynamic> body,
  ) async {
    if (kDebugMode) {
      debugPrint(
        '[체크리스트] PATCH /api/v1/disasters/$userDisasterId/checklist/$checklistItemId/attachments/$attachmentId '
        'body=$body',
      );
    }
    final response = await _dio.patch(
      '/api/v1/disasters/$userDisasterId/checklist/$checklistItemId/attachments/$attachmentId',
      data: body,
    );
    if (kDebugMode) {
      debugPrint('[체크리스트] 첨부 수정 응답: ${response.statusCode} ${response.data}');
    }
  }

  Future<void> deleteAttachment(
    int userDisasterId,
    int checklistItemId,
    int attachmentId,
  ) async {
    if (kDebugMode) {
      debugPrint(
        '[체크리스트] DELETE /api/v1/disasters/$userDisasterId/checklist/$checklistItemId/attachments/$attachmentId',
      );
    }
    final response = await _dio.delete(
      '/api/v1/disasters/$userDisasterId/checklist/$checklistItemId/attachments/$attachmentId',
    );
    if (kDebugMode) {
      debugPrint('[체크리스트] 첨부 삭제 응답: ${response.statusCode} ${response.data}');
    }
  }

  Future<List<AttachmentModel>> fetchArchive(
    int userDisasterId, {
    String type = 'ALL',
    String? date,
    String? cursor,
    int limit = 20,
  }) async {
    final params = <String, dynamic>{'type': type, 'limit': limit};
    if (date != null) params['date'] = date;
    if (cursor != null) params['cursor'] = cursor;
    if (kDebugMode) {
      debugPrint(
        '[체크리스트] GET /api/v1/disasters/$userDisasterId/archives params=$params',
      );
    }
    final response = await _dio.get(
      '/api/v1/disasters/$userDisasterId/archives',
      queryParameters: params,
    );
    if (kDebugMode) {
      debugPrint('[체크리스트] 아카이브 응답: ${response.statusCode} ${response.data}');
    }
    final data = response.data;
    List<dynamic> rawItems = [];
    if (data is Map) {
      rawItems = (data['items'] as List?) ?? [];
    }
    return rawItems
        .map(
          (e) => AttachmentModel.fromJson(Map<String, dynamic>.from(e as Map)),
        )
        .toList();
  }
}
