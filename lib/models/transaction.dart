
class Transaction {
  final int id;
  final String orderId;
  final String itemName;
  final int quantity;
  final double totalAmount;
  final String paymentMethod;
  final String paymentStatus;
  final String transactionStatus;

  // Detail transaksi
  final String shippingAddress;
  final String codMeetingLocation;
  final DateTime? codMeetingTime;
  final String qrCodeUrl;
  final String virtualAccountBank;
  final String virtualAccountNumber;
  final String virtualAccountBillKey;
  final String virtualAccountBillerCode;
  final DateTime? expiryTime;
  final DateTime? createdAt;

  Transaction({
    this.id = 0,
    required this.orderId,
    required this.itemName,
    required this.quantity,
    required this.totalAmount,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.transactionStatus,
    this.shippingAddress = '',
    this.codMeetingLocation = '',
    this.codMeetingTime,
    this.qrCodeUrl = '',
    this.virtualAccountBank = '',
    this.virtualAccountNumber = '',
    this.virtualAccountBillKey = '',
    this.virtualAccountBillerCode = '',
    this.expiryTime,
    this.createdAt,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] ?? 0,
      orderId: json['order_id'] ?? '',
      itemName: json['item_name'] ?? '',
      quantity: json['quantity'] ?? 0,
      totalAmount: double.tryParse(
            json['total_amount'].toString(),
          ) ??
          0.0,
      paymentMethod: json['payment_method'] ?? '',
      paymentStatus: json['payment_status'] ?? '',
      transactionStatus: json['transaction_status'] ?? '',
      shippingAddress: json['shipping_address'] ?? '',
      codMeetingLocation: json['cod_meeting_location'] ?? '',
      codMeetingTime: json['cod_meeting_time'] != null
          ? DateTime.tryParse(json['cod_meeting_time'].toString())
          : null,
      qrCodeUrl: json['qr_code_url'] ?? '',
      virtualAccountBank: json['virtual_account_bank'] ?? '',
      virtualAccountNumber: json['virtual_account_number'] ?? '',
      virtualAccountBillKey: json['virtual_account_bill_key'] ?? '',
      virtualAccountBillerCode: json['virtual_account_biller_code'] ?? '',
      expiryTime: json['expiry_time'] != null
          ? DateTime.tryParse(json['expiry_time'].toString())
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }
}
