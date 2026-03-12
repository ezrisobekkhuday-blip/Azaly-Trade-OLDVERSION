String normalizeWechatValue(String value) {
  return value.trim();
}

String deriveWechatLink(String value) {
  final trimmed = normalizeWechatValue(value);
  if (trimmed.isEmpty) {
    return '';
  }

  final uri = Uri.tryParse(trimmed);
  if (uri != null && uri.hasScheme) {
    return trimmed;
  }

  return '';
}

String resolveWechatDisplayValue(String value, String link) {
  final normalizedValue = normalizeWechatValue(value);
  if (normalizedValue.isNotEmpty) {
    return normalizedValue;
  }

  return normalizeWechatValue(link);
}
