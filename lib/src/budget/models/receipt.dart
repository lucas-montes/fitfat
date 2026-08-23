import 'package:uuid/uuid.dart';

/// Receipt upload / parse lifecycle.
/// 0 local | 1 uploading | 2 uploaded | 3 error
enum ReceiptStatus {
  local,
  uploading,
  uploaded,
  error;

  static ReceiptStatus fromCode(int code) => switch (code) {
    1 => ReceiptStatus.uploading,
    2 => ReceiptStatus.uploaded,
    3 => ReceiptStatus.error,
    _ => ReceiptStatus.local,
  };

  int get code => switch (this) {
    ReceiptStatus.local => 0,
    ReceiptStatus.uploading => 1,
    ReceiptStatus.uploaded => 2,
    ReceiptStatus.error => 3,
  };
}

final class Receipt {
  final String id;
  final String localPath;
  final String? remotePath;
  final ReceiptStatus status;
  final bool parsed;
  final String? parsedJson;
  final String? transactionId;
  final DateTime createdAt;

  const Receipt({
    required this.id,
    required this.localPath,
    this.remotePath,
    required this.status,
    required this.parsed,
    this.parsedJson,
    this.transactionId,
    required this.createdAt,
  });

  Receipt copyWith({
    String? localPath,
    String? remotePath,
    bool clearRemotePath = false,
    ReceiptStatus? status,
    bool? parsed,
    String? parsedJson,
    bool clearParsedJson = false,
    String? transactionId,
    bool clearTransactionId = false,
  }) => Receipt(
    id: id,
    localPath: localPath ?? this.localPath,
    remotePath: clearRemotePath ? null : (remotePath ?? this.remotePath),
    status: status ?? this.status,
    parsed: parsed ?? this.parsed,
    parsedJson: clearParsedJson ? null : (parsedJson ?? this.parsedJson),
    transactionId: clearTransactionId
        ? null
        : (transactionId ?? this.transactionId),
    createdAt: createdAt,
  );
}

Receipt newReceipt({required String localPath}) => Receipt(
  id: const Uuid().v7(),
  localPath: localPath,
  status: ReceiptStatus.local,
  parsed: false,
  createdAt: DateTime.now(),
);
