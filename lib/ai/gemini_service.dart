import 'dart:convert';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class GeminiApiException implements Exception {
  final String message;
  final int? statusCode;

  const GeminiApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

/// Cliente mínimo da API Gemini.
///
/// A chave nunca é embutida no aplicativo ou gravada no repositório. Em modo
/// pessoal, o próprio usuário informa uma chave no aparelho e ela fica no
/// armazenamento seguro do sistema operacional.
class GeminiService {
  static const model = 'gemini-3.5-flash-lite';
  static const _secretName = 'finora_gemini_api_key';
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  const GeminiService();

  Future<bool> hasApiKey() async {
    final value = await _storage.read(key: _secretName);
    return value != null && value.trim().isNotEmpty;
  }

  Future<void> saveApiKey(String value) async {
    final clean = value.trim();
    if (clean.length < 12) {
      throw const GeminiApiException('A chave informada parece inválida.');
    }
    await _storage.write(key: _secretName, value: clean);
  }

  Future<void> deleteApiKey() => _storage.delete(key: _secretName);

  Future<String?> _readApiKey() async {
    final value = await _storage.read(key: _secretName);
    final clean = value?.trim();
    return clean == null || clean.isEmpty ? null : clean;
  }

  Future<void> validateApiKey(String key) async {
    final text = await _interaction(
      input: 'Responda apenas com OK.',
      apiKeyOverride: key.trim(),
      maxOutputTokens: 16,
    );
    if (!text.toUpperCase().contains('OK')) {
      throw const GeminiApiException('A API respondeu, mas o teste não foi reconhecido.');
    }
  }

  Future<String> generateText({
    required String input,
    int maxOutputTokens = 900,
  }) =>
      _interaction(input: input, maxOutputTokens: maxOutputTokens);

  Future<Map<String, dynamic>> generateStructured({
    required String input,
    required Map<String, dynamic> schema,
    int maxOutputTokens = 800,
  }) async {
    final text = await _interaction(
      input: input,
      schema: schema,
      maxOutputTokens: maxOutputTokens,
    );
    try {
      final decoded = jsonDecode(text);
      if (decoded is! Map) {
        throw const FormatException('Resposta não é um objeto.');
      }
      return Map<String, dynamic>.from(decoded);
    } catch (_) {
      throw const GeminiApiException(
        'O Gemini respondeu em um formato inesperado. Tente novamente.',
      );
    }
  }

  Future<String> _interaction({
    required String input,
    Map<String, dynamic>? schema,
    String? apiKeyOverride,
    int maxOutputTokens = 900,
  }) async {
    final apiKey = apiKeyOverride ?? await _readApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      throw const GeminiApiException(
        'Configure sua chave do Gemini em Configurações > Finora IA.',
      );
    }

    final body = <String, dynamic>{
      'model': model,
      'input': input,
      // Não precisamos recuperar esta interação depois; evita criar histórico
      // de sessão no endpoint de Interactions.
      'store': false,
      'generation_config': {
        'max_output_tokens': maxOutputTokens,
        'thinking_level': 'minimal',
      },
      if (schema != null)
        'response_format': {
          'type': 'text',
          'mime_type': 'application/json',
          'schema': schema,
        },
    };

    final client = HttpClient()..connectionTimeout = const Duration(seconds: 12);
    try {
      final request = await client
          .postUrl(Uri.parse('https://generativelanguage.googleapis.com/v1beta/interactions'))
          .timeout(const Duration(seconds: 15));
      request.headers.contentType = ContentType.json;
      request.headers.set('x-goog-api-key', apiKey);
      request.write(jsonEncode(body));

      final response = await request.close().timeout(const Duration(seconds: 35));
      final raw = await utf8.decoder.bind(response).join();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw GeminiApiException(
          _friendlyError(response.statusCode, raw),
          statusCode: response.statusCode,
        );
      }

      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        throw const GeminiApiException('Resposta inválida recebida do Gemini.');
      }
      final map = Map<String, dynamic>.from(decoded);
      if (map['status'] == 'failed') {
        throw const GeminiApiException('O Gemini não conseguiu concluir a solicitação.');
      }
      final text = _extractModelText(map);
      if (text.trim().isEmpty) {
        throw const GeminiApiException('O Gemini retornou uma resposta vazia.');
      }
      return text.trim();
    } on GeminiApiException {
      rethrow;
    } on SocketException {
      throw const GeminiApiException('Sem conexão com a internet para acessar o Gemini.');
    } on HandshakeException {
      throw const GeminiApiException('Falha ao estabelecer conexão segura com o Gemini.');
    } on HttpException {
      throw const GeminiApiException('Falha de comunicação com o Gemini.');
    } on FormatException {
      throw const GeminiApiException('Resposta inválida recebida do Gemini.');
    } catch (error) {
      if (error is GeminiApiException) rethrow;
      throw const GeminiApiException('Não foi possível concluir a solicitação de IA.');
    } finally {
      client.close(force: true);
    }
  }

  String _extractModelText(Map<String, dynamic> response) {
    final steps = response['steps'];
    if (steps is! List) return '';
    final pieces = <String>[];
    for (final rawStep in steps.reversed) {
      if (rawStep is! Map || rawStep['type'] != 'model_output') continue;
      final content = rawStep['content'];
      if (content is! List) continue;
      for (final rawContent in content) {
        if (rawContent is Map && rawContent['type'] == 'text') {
          final text = rawContent['text']?.toString();
          if (text != null && text.isNotEmpty) pieces.add(text);
        }
      }
      if (pieces.isNotEmpty) break;
    }
    return pieces.join('\n');
  }

  String _friendlyError(int statusCode, String raw) {
    String? serverMessage;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        final error = decoded['error'];
        if (error is Map) serverMessage = error['message']?.toString();
      }
    } catch (_) {}

    switch (statusCode) {
      case 400:
        return serverMessage ?? 'A solicitação enviada ao Gemini foi rejeitada.';
      case 401:
      case 403:
        return 'Chave do Gemini inválida, sem permissão ou bloqueada.';
      case 429:
        return 'Limite gratuito do Gemini atingido. Tente novamente mais tarde.';
      case 500:
      case 502:
      case 503:
      case 504:
        return 'O Gemini está temporariamente indisponível. Tente novamente.';
      default:
        return serverMessage ?? 'Erro $statusCode ao acessar o Gemini.';
    }
  }
}
