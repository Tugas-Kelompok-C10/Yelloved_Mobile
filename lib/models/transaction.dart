class Transaction {
  final int id;
  final String orderId;
  final String itemName;
  final int quantity;
  final double totalAmount;
  final String paymentMethod;
  final String paymentStatus;
  final String transactionStatus;

  Transaction({
    required this.id,
    required this.orderId,
    required this.itemName,
    required this.quantity,
    required this.totalAmount,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.transactionStatus,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'],
      orderId: json['order_id'] ?? '',
      itemName: json['item_name'] ?? '',
      quantity: json['quantity'] ?? 0,
      totalAmount: double.parse(json['total_amount'].toString()),
      paymentMethod: json['payment_method'] ?? '',
      paymentStatus: json['payment_status'] ?? '',
      transactionStatus: json['transaction_status'] ?? '',
    );
  }
}
