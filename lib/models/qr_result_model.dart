class QrResolveResult {
  final bool isValid;
  final String message;
  final int tableId;

  QrResolveResult({
    required this.isValid,
    required this.message,
    required this.tableId,
  });

  factory QrResolveResult.fromJson(Map<String, dynamic> json) {
    return QrResolveResult(
      isValid: json['isValid'] ?? false,
      message: json['message'] ?? '',
      tableId: json['tableId'] ?? 0,
    );
  }
}
