class TranslationRequest {
  final String text;
  final String source;
  final String target;

  TranslationRequest({
    required this.text,
    required this.source,
    required this.target,
  });

  Map<String, dynamic> toJson() => {
    'q': text,
    'source': source,
    'target': target,
    'format': 'text',
  };
}

class TranslationResponse {
  final String translatedText;
  final String detectedLanguage;
  final double confidence;

  TranslationResponse({
    required this.translatedText,
    this.detectedLanguage = '',
    this.confidence = 0.0,
  });

  factory TranslationResponse.fromJson(Map<String, dynamic> json) {
    return TranslationResponse(
      translatedText: json['translatedText'] ?? '',
      detectedLanguage: json['detectedLanguage']?['language'] ?? '',
      confidence: (json['detectedLanguage']?['confidence'] ?? 0.0).toDouble(),
    );
  }
}
