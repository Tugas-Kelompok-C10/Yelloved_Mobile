/// Data models for the account profile endpoints under /account/api/mobile/.
library;

String _str(Object? value) => value?.toString() ?? '';

class Address {
  const Address({
    this.id,
    this.label = 'Home',
    required this.recipientName,
    required this.phoneNumber,
    required this.streetAddress,
    required this.city,
    required this.province,
    required this.postalCode,
    this.isDefault = false,
  });

  factory Address.fromJson(Map<String, dynamic> json) => Address(
    id: json['id'] as int?,
    label: _str(json['label']),
    recipientName: _str(json['recipient_name']),
    phoneNumber: _str(json['phone_number']),
    streetAddress: _str(json['street_address']),
    city: _str(json['city']),
    province: _str(json['province']),
    postalCode: _str(json['postal_code']),
    isDefault: json['is_default'] == true,
  );

  final int? id;
  final String label;
  final String recipientName;
  final String phoneNumber;
  final String streetAddress;
  final String city;
  final String province;
  final String postalCode;
  final bool isDefault;

  Map<String, dynamic> toJson() => {
    'label': label,
    'recipient_name': recipientName,
    'phone_number': phoneNumber,
    'street_address': streetAddress,
    'city': city,
    'province': province,
    'postal_code': postalCode,
    'is_default': isDefault,
  };

  String get summary => [
    streetAddress,
    city,
    province,
    postalCode,
  ].where((part) => part.trim().isNotEmpty).join(', ');
}

class PaymentMethod {
  const PaymentMethod({
    this.id,
    required this.methodType,
    required this.provider,
    required this.accountName,
    required this.accountIdentifier,
    this.isDefault = false,
  });

  factory PaymentMethod.fromJson(Map<String, dynamic> json) => PaymentMethod(
    id: json['id'] as int?,
    methodType: _str(json['method_type']),
    provider: _str(json['provider']),
    accountName: _str(json['account_name']),
    accountIdentifier: _str(json['account_identifier']),
    isDefault: json['is_default'] == true,
  );

  static const types = {'bank': 'Bank transfer', 'e_wallet': 'E-wallet'};

  final int? id;
  final String methodType;
  final String provider;
  final String accountName;

  /// Masked by the server when read (e.g. "•••• 7890"); raw when sent.
  final String accountIdentifier;
  final bool isDefault;

  String get typeLabel => types[methodType] ?? methodType;

  Map<String, dynamic> toJson() => {
    'method_type': methodType,
    'provider': provider,
    'account_name': accountName,
    'account_identifier': accountIdentifier,
    'is_default': isDefault,
  };
}
