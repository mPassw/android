import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mpass/auth/login_page.dart';
import 'package:mpass/auth/service/authorization_service.dart';
import 'package:mpass/components/sonner.dart';

class HttpService {
  static Future<http.Response> sendRequest(String url, String method,
      Map<String, String>? headers, Map<String, dynamic>? body) async {
    if (method == "GET") {
      final response = await http.get(Uri.parse(url), headers: headers);
      parseResponseCode(response);

      return response;
    } else if (method == "POST") {
      dynamic requestBody = body;
      if (headers != null &&
          headers['Content-Type'] != null &&
          headers['Content-Type']!.contains("application/json")) {
        requestBody = jsonEncode(body);
      }
      final response =
          await http.post(Uri.parse(url), headers: headers, body: requestBody);
      parseResponseCode(response);

      return response;
    } else if (method == "PUT") {
      dynamic requestBody = body;
      if (headers != null &&
          headers['Content-Type'] != null &&
          headers['Content-Type']!.contains("application/json")) {
        requestBody = jsonEncode(body);
      }
      final response =
          await http.put(Uri.parse(url), headers: headers, body: requestBody);
      parseResponseCode(response);

      return response;
    } else if (method == "PATCH") {
      dynamic requestBody = body;
      if (headers != null &&
          headers['Content-Type'] != null &&
          headers['Content-Type']!.contains("application/json")) {
        requestBody = jsonEncode(body);
      }
      final response =
          await http.patch(Uri.parse(url), headers: headers, body: requestBody);
      parseResponseCode(response);

      return response;
    } else if (method == "DELETE") {
      final response = await http.delete(Uri.parse(url), headers: headers);
      parseResponseCode(response);

      return response;
    } else {
      throw Exception("Unsupported HTTP method: $method");
    }
  }

  static parseResponseCode(http.Response response) {
    if (response.statusCode >= 400 && response.statusCode < 500) {
      String? message;
      try {
        final dynamic jsonResponse = jsonDecode(response.body);
        message = jsonResponse['title'];
      } catch (e) {
        log(e.toString());
      }
      switch (response.statusCode) {
        case 400:
          throw BadRequestException(message ?? "Bad request");
        case 401:
          throw UnauthorizedException(message ?? "Unauthorized");
        case 404:
          throw NotFoundException(message ?? "Not found");
        case 409:
          throw ConflictException(message ?? "Already exists");
        case 498:
          throw SessionExpiredException(message ?? "Session expired");
        default:
          if (response.statusCode >= 400 && response.statusCode < 500) {
            throw CustomException(message ?? "Something went wrong");
          }
      }
    }
  }

  static parseSessionExpiredException(BuildContext context) {
    if (context.mounted) {
      AuthorizationService.logout(context, "Session expired");
      Navigator.push(context, MaterialPageRoute(builder: (_) {
        return const Login();
      }));
    }
  }

  static parseException(BuildContext context, Exception error) {
    if (error is CustomException) {
      if (error is SessionExpiredException) {
        HttpService.parseSessionExpiredException(context);
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(Sonner(message: error.message));
      }
    }
  }
}

class UnauthorizedException extends CustomException {
  UnauthorizedException(super.message);

  @override
  String toString() => 'UnauthorizedException: $message';
}

class NotFoundException extends CustomException {
  NotFoundException(super.message);

  @override
  String toString() => 'NotFoundException: $message';
}

class ConflictException extends CustomException {
  ConflictException(super.message);

  @override
  String toString() => 'ConflictException: $message';
}

class BadRequestException extends CustomException {
  BadRequestException(super.message);

  @override
  String toString() => 'BadRequestException: $message';
}

class SessionExpiredException extends CustomException {
  SessionExpiredException(super.message);

  @override
  String toString() => 'SessionExpiredException: $message';
}

class CustomException implements Exception {
  final String message;

  CustomException(this.message);

  @override
  String toString() => 'CustomException: $message';
}
