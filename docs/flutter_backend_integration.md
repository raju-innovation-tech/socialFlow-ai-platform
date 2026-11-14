# SocialFlow AI – Flutter Frontend Integration Guide

This guide details how the Phase 1 Flutter UI connects to the Phase 2 FastAPI backend using the pre-installed `dio` package.

---

## 1. Environment-Specific Base URLs

Depending on the target platform being tested, configure the `baseUrl` in your Flutter environment:

| Target Platform | Base URL |
| :--- | :--- |
| **Windows Desktop** | `http://localhost:8001/api/v1` |
| **Flutter Web (Chrome)** | `http://localhost:8001/api/v1` |
| **Android Emulator** | `http://10.0.2.2:8001/api/v1` |
| **Physical Mobile Device (LAN)** | `http://192.168.x.x:8001/api/v1` |
| **iOS Simulator** | `http://localhost:8001/api/v1` |

---

## 2. Recommended Dio Client Service Pattern

Create a centralized API service inside `flutter_admin/lib/core/network/api_client.dart`:

```dart
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  late final Dio dio;

  factory ApiClient() => _instance;

  ApiClient._internal() {
    String baseUrl = 'http://localhost:8001/api/v1';

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      baseUrl = 'http://10.0.2.2:8001/api/v1';
    }

    dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
      ),
    );
  }
}
```

---

## 3. Sample API Requests from Flutter

### Fetching Workspaces:
```dart
final response = await ApiClient().dio.get('/workspaces');
final List workspaces = response.data;
```

### Creating a Post:
```dart
final response = await ApiClient().dio.post(
  '/posts',
  data: {
    'workspace_id': currentWorkspaceId,
    'title': 'AI Automation in 2026',
    'content': 'How AI transforms social operations.',
    'content_type': 'text',
    'target_account_ids': selectedAccountIds,
  },
);
```

### Uploading Media:
```dart
FormData formData = FormData.fromMap({
  'workspace_id': currentWorkspaceId,
  'file': await MultipartFile.fromFile(filePath, filename: 'hero.png'),
});

final response = await ApiClient().dio.post(
  '/media/upload',
  data: formData,
);
```

---

## 4. Error Handling Format

All backend errors follow a standardized JSON contract:

```json
{
  "error_code": "RESOURCE_NOT_FOUND",
  "message": "Workspace with identifier '123' was not found.",
  "extra": null,
  "request_id": "9b1deb4d-3b7d-4bad-9bdd-2b0d7b3dcb6d",
  "timestamp": "2026-11-14T10:15:00Z"
}
```
Catch `DioException` and inspect `e.response?.data['message']` for user-facing toasts and alerts.

