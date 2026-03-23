class TableModel {
  final int tableId;
  final String tableName;
  final int numberOfSeats;
  final String tableStatus;
  final String? qrCodePath;
  final String? ownerTable;

  TableModel({
    required this.tableId,
    required this.tableName,
    required this.numberOfSeats,
    required this.tableStatus,
    this.qrCodePath,
    this.ownerTable,
  });

  factory TableModel.fromJson(Map<String, dynamic> json) {
    return TableModel(
      tableId: json['tableId'],
      tableName: json['tableName'],
      numberOfSeats: json['numberOfSeats'],
      tableStatus: json['tableStatus'],
      qrCodePath: json['qrCodePath'],
      ownerTable: json['ownerTable'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tableId': tableId,
      'tableName': tableName,
      'numberOfSeats': numberOfSeats,
      'tableStatus': tableStatus,
      'qrCodePath': qrCodePath,
      'ownerTable': ownerTable,
    };
  }

  TableModel copyWith({
    int? tableId,
    String? tableName,
    int? numberOfSeats,
    String? tableStatus,
    String? qrCodePath,
    String? ownerTable,
  }) {
    return TableModel(
      tableId: tableId ?? this.tableId,
      tableName: tableName ?? this.tableName,
      numberOfSeats: numberOfSeats ?? this.numberOfSeats,
      tableStatus: tableStatus ?? this.tableStatus,
      qrCodePath: qrCodePath ?? this.qrCodePath,
      ownerTable: ownerTable ?? this.ownerTable,
    );
  }
}
