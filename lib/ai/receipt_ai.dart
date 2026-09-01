import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'gemini_service.dart';

class ReceiptScanResult {
  final String merchant;
  final double amount;
  final DateTime? date;
  final String category;
  final String paymentHint;
  final String note;
  final double confidence;

  const ReceiptScanResult({
    required this.merchant,
    required this.amount,
    required this.date,
    required this.category,
    required this.paymentHint,
    required this.note,
    required this.confidence,
  });
}

class ReceiptAiService {
  static const _secretName = 'finora_gemini_api_key';
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  const ReceiptAiService();

  Future<ReceiptScanResult> analyze({
    required Uint8List bytes,
    required String mimeType,
    required List<String> categories,
  }) async {
    if (bytes.isEmpty) {
      throw const GeminiApiException('O arquivo selecionado está vazio.');
    }
    if (bytes.length > 10 * 1024 * 1024) {
      throw const GeminiApiException(
        'A imagem é muito grande. Use um comprovante de até 10 MB.',
      );
    }

    final apiKey = (await _storage.read(key: _secretName))?.trim();
    if (apiKey == null || apiKey.isEmpty) {
      throw const GeminiApiException(
        'Conecte sua chave do Gemini na aba IA para ler comprovantes.',
      );
    }

    final prompt = '''
Analise este comprovante, recibo, nota, PIX ou print bancário para o Finora.
Extraia apenas dados que estejam realmente visíveis. Não invente conta, cartão, data ou estabelecimento.
Se não houver data legível, use null. Se houver mais de um valor, escolha o total efetivamente pago.
A categoria deve ser uma destas: ${jsonEncode(categories)}.
paymentHint deve conter apenas um nome de banco/cartão/meio de pagamento se estiver explícito; caso contrário, string vazia.
note deve ser curta e útil. Responda somente no JSON solicitado.
''';

    final schema = {
      'type': 'object',
      'properties': {
        'merchant': {'type': 'string'},
        'amount': {'type': 'number'},
        'date': {'type': ['string', 'null']},
        'category': {'type': 'string'},
        'paymentHint': {'type': 'string'},
        'note': {'type': 'string'},
        'confidence': {'type': 'number', 'minimum': 0, 'maximum': 1},
      },
      'required': [
        'merchant',
        'amount',
        'date',
        'category',
        'paymentHint',
        'note',
        'confidence',
      ],
    };

    final body = <String, dynamic>{
      'model': GeminiService.model,
      'input': [
        {'type': 'text', 'text': prompt},
        {
          'type': 'image',
          'mime_type': mimeType,
          'data': base64Encode(bytes),
        },
      ],
      'store': false,
      'generation_config': {
        'max_output_tokens': 500,
        'thinking_level': 'minimal',
      },
      'response_format': {
        'type': 'text',
        'mime_type': 'application/json',
        'schema': schema,
      },
    };

    final client = HttpClient()..connectionTimeout = const Duration(seconds: 15);
    try {
      final request = await client
          .postUrl(
            Uri.parse(
              'https://generativelanguage.googleapis.com/v1beta/interactions',
            ),
          )
          .timeout(const Duration(seconds: 18));
      request.headers.contentType = ContentType.json;
      request.headers.set('x-goog-api-key', apiKey);
      request.headers.set('Api-Revision', '2026-05-20');
      request.write(jsonEncode(body));

      final response = await request.close().timeout(const Duration(seconds: 45));
      final raw = await utf8.decoder.bind(response).join();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        if (response.statusCode == 429) {
          throw const GeminiApiException(
            'O limite do Gemini foi atingido. Tente novamente mais tarde.',
          );
        }
        if (response.statusCode == 401 || response.statusCode == 403) {
          throw const GeminiApiException(
            'Sua chave do Gemini não tem permissão para analisar esta imagem.',
          );
        }
        throw GeminiApiException(
          'Não consegui analisar o comprovante (erro ${response.statusCode}).',
        );
      }

      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        throw const GeminiApiException('Resposta inválida ao ler o comprovante.');
      }
      final text = _extractText(Map<String, dynamic>.from(decoded));
      final parsed = jsonDecode(_unwrapJson(text));
      if (parsed is! Map) {
        throw const GeminiApiException('Não consegui estruturar o comprovante.');
      }
      final map = Map<String, dynamic>.from(parsed);
      final amount = (map['amount'] as num? ?? 0).toDouble();
      if (!amount.isFinite || amount <= 0) {
        throw const GeminiApiException(
          'Não consegui identificar com segurança o valor pago.',
        );
      }
      var category = map['category']?.toString().trim() ?? 'Outros';
      if (!categories.contains(category)) category = 'Outros';
      final dateText = map['date']?.toString();
      return ReceiptScanResult(
        merchant: (map['merchant']?.toString().trim().isNotEmpty ?? false)
            ? map['merchant'].toString().trim()
            : 'Compra',
        amount: amount,
        date: dateText == null ? null : DateTime.tryParse(dateText),
        category: category,
        paymentHint: map['paymentHint']?.toString().trim() ?? '',
        note: map['note']?.toString().trim() ?? '',
        confidence: ((map['confidence'] as num? ?? .5).toDouble())
            .clamp(0.0, 1.0)
            .toDouble(),
      );
    } on GeminiApiException {
      rethrow;
    } on TimeoutException {
      throw const GeminiApiException(
        'A leitura do comprovante demorou demais. Tente novamente.',
      );
    } on SocketException {
      throw const GeminiApiException(
        'Não consegui conectar ao Gemini. Confira sua internet.',
      );
    } catch (_) {
      throw const GeminiApiException(
        'Não consegui interpretar este comprovante. Tente uma imagem mais nítida.',
      );
    } finally {
      client.close(force: true);
    }
  }

  String _extractText(Map<String, dynamic> response) {
    final steps = response['steps'];
    if (steps is! List) return '';
    for (final rawStep in steps.reversed) {
      if (rawStep is! Map || rawStep['type'] != 'model_output') continue;
      final content = rawStep['content'];
      if (content is! List) continue;
      final pieces = <String>[];
      for (final rawContent in content) {
        if (rawContent is Map && rawContent['type'] == 'text') {
          final text = rawContent['text']?.toString();
          if (text != null && text.isNotEmpty) pieces.add(text);
        }
      }
      if (pieces.isNotEmpty) return pieces.join('\n');
    }
    return '';
  }

  String _unwrapJson(String input) {
    var text = input.trim();
    text = text.replaceFirst(
      RegExp(r'^```(?:json)?\s*', caseSensitive: false),
      '',
    );
    text = text.replaceFirst(RegExp(r'\s*```$'), '');
    final first = text.indexOf('{');
    final last = text.lastIndexOf('}');
    if (first >= 0 && last > first) text = text.substring(first, last + 1);
    return text;
  }
}