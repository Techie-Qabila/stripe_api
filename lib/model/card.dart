import '../card_utils.dart';
import '../stripe_network_utils.dart';
import '../stripe_text_utils.dart';
import 'model_utils.dart';
import 'stripe_json_model.dart';
import 'stripe_json_utils.dart';
import 'stripe_payment_source.dart';

class StripeCard extends StripeJsonModel implements StripePaymentSource {
  static const String AMERICAN_EXPRESS = "American Express";
  static const String DISCOVER = "Discover";
  static const String JCB = "JCB";
  static const String DINERS_CLUB = "Diners Club";
  static const String VISA = "Visa";
  static const String MASTERCARD = "MasterCard";
  static const String UNIONPAY = "UnionPay";
  static const String UNKNOWN = "Unknown";

  static const int CVC_LENGTH_AMERICAN_EXPRESS = 4;
  static const int CVC_LENGTH_COMMON = 3;

  static const String FUNDING_CREDIT = "credit";
  static const String FUNDING_DEBIT = "debit";
  static const String FUNDING_PREPAID = "prepaid";
  static const String FUNDING_UNKNOWN = "unknown";

  ///
  // Based on http://en.wikipedia.org/wiki/Bank_card_number#Issuer_identification_number_.28IIN.29
  static const List<String> PREFIXES_AMERICAN_EXPRESS = ["34", "37"];
  static const List<String> PREFIXES_DISCOVER = ["60", "64", "65"];
  static const List<String> PREFIXES_JCB = ["35"];
  static const List<String> PREFIXES_DINERS_CLUB = [
    "300",
    "301",
    "302",
    "303",
    "304",
    "305",
    "309",
    "36",
    "38",
    "39"
  ];
  static const List<String> PREFIXES_VISA = ["4"];
  static const List<String> PREFIXES_MASTERCARD = [
    "2221",
    "2222",
    "2223",
    "2224",
    "2225",
    "2226",
    "2227",
    "2228",
    "2229",
    "223",
    "224",
    "225",
    "226",
    "227",
    "228",
    "229",
    "23",
    "24",
    "25",
    "26",
    "270",
    "271",
    "2720",
    "50",
    "51",
    "52",
    "53",
    "54",
    "55",
    "67"
  ];
  static const List<String> PREFIXES_UNIONPAY = ["62"];

  ///

  static const int MAX_LENGTH_STANDARD = 16;
  static const int MAX_LENGTH_AMERICAN_EXPRESS = 15;
  static const int MAX_LENGTH_DINERS_CLUB = 14;

  static const String VALUE_CARD = "card";

  static const String FIELD_OBJECT = "object";
  static const String FIELD_NUMBER = "number";
  static const String FIELD_CVC = "cvc";
  static const String FIELD_ADDRESS_CITY = "address_city";
  static const String FIELD_ADDRESS_COUNTRY = "address_country";
  static const String FIELD_ADDRESS_LINE1 = "address_line1";
  static const String FIELD_ADDRESS_LINE1_CHECK = "address_line1_check";
  static const String FIELD_ADDRESS_LINE2 = "address_line2";
  static const String FIELD_ADDRESS_STATE = "address_state";
  static const String FIELD_ADDRESS_ZIP = "address_zip";
  static const String FIELD_ADDRESS_ZIP_CHECK = "address_zip_check";
  static const String FIELD_BRAND = "brand";
  static const String FIELD_COUNTRY = "country";
  static const String FIELD_CURRENCY = "currency";
  static const String FIELD_CUSTOMER = "customer";
  static const String FIELD_CVC_CHECK = "cvc_check";
  static const String FIELD_EXP_MONTH = "exp_month";
  static const String FIELD_EXP_YEAR = "exp_year";
  static const String FIELD_FINGERPRINT = "fingerprint";
  static const String FIELD_FUNDING = "funding";
  static const String FIELD_NAME = "name";
  static const String FIELD_LAST4 = "last4";
  static const String FIELD_ID = "id";
  static const String FIELD_TOKENIZATION_METHOD = "tokenization_method";

  late String number;
  late String cvc;
  late int expMonth;
  late int expYear;
  String? name;
  String? addressLine1;
  String? addressLine1Check;
  String? addressLine2;
  String? addressCity;
  String? addressState;
  String? addressZip;
  String? addressZipCheck;
  String? addressCountry;
  String? last4;
  late String _brand;
  String? funding;
  String? fingerprint;
  String? country;
  String? currency;
  String? customerId;
  String? cvcCheck;
  late String id;
  late List<String> loggingTokens;
  String? tokenizationMethod;

  StripeCard({
    required this.number,
    required this.cvc,
    required this.expMonth,
    required this.expYear,
    this.name,
    this.addressLine1,
    this.addressLine1Check,
    this.addressLine2,
    this.addressCity,
    this.addressState,
    this.addressZip,
    this.addressZipCheck,
    this.addressCountry,
    this.last4,
    String? brand,
    this.funding,
    this.fingerprint,
    this.country,
    this.currency,
    this.customerId,
    this.cvcCheck,
    this.id = '',
    List<String>? loggingTokens,
    this.tokenizationMethod,
  })  : _brand = brand ??= '',
        loggingTokens = loggingTokens ?? [];

  StripeCard.fromJson(Map<String, dynamic> json) {
    // Note that we'll never get the CVC or card number in JSON, so those values are null
    number = optString(json, FIELD_NUMBER) ?? '';
    cvc = optString(json, FIELD_CVC) ?? '';
    expMonth = optInteger(json, FIELD_EXP_MONTH) ?? -1;
    expYear = optInteger(json, FIELD_EXP_YEAR) ?? -1;
    addressCity = optString(json, FIELD_ADDRESS_CITY);
    addressLine1 = optString(json, FIELD_ADDRESS_LINE1);
    addressLine1Check = optString(json, FIELD_ADDRESS_LINE1_CHECK);

    addressLine2 = optString(json, FIELD_ADDRESS_LINE2);
    addressCountry = optString(json, FIELD_ADDRESS_COUNTRY);
    addressState = optString(json, FIELD_ADDRESS_STATE);
    addressZip = optString(json, FIELD_ADDRESS_ZIP);
    addressZipCheck = optString(json, FIELD_ADDRESS_ZIP_CHECK);
    _brand = asCardBrand(optString(json, FIELD_BRAND) ?? '');
    country = optCountryCode(json, FIELD_COUNTRY);
    customerId = optString(json, FIELD_CUSTOMER);
    currency = optCurrency(json, FIELD_CURRENCY);
    cvcCheck = optString(json, FIELD_CVC_CHECK);
    funding = asFundingType(optString(json, FIELD_FUNDING) ?? '');
    fingerprint = optString(json, FIELD_FINGERPRINT);
    id = optString(json, FIELD_ID) ?? '';
    last4 = optString(json, FIELD_LAST4);
    name = optString(json, FIELD_NAME);
    tokenizationMethod = optString(json, FIELD_TOKENIZATION_METHOD);
  }

  String get brand {
    if (isBlank(_brand) && !isBlank(number)) {
      _brand = getPossibleCardType(number);
    }

    return _brand;
  }

  /// Checks whether {@code this} represents a valid card.
  ///
  /// @return {@code true} if valid, {@code false} otherwise.
  bool validateCard() {
    return _validateCard(DateTime.now());
  }

  /// Checks whether or not the {@link #number} field is valid.
  ///
  /// @return {@code true} if valid, {@code false} otherwise.
  bool validateNumber() {
    return isValidCardNumber(number);
  }

  /// Checks whether or not the {@link #expMonth} and {@link #expYear} fields represent a valid
  /// expiry date.
  ///
  /// @return {@code true} if valid, {@code false} otherwise
  bool validateExpiryDate() {
    return _validateExpiryDate(DateTime.now());
  }

  /// Checks whether or not the {@link #cvc} field is valid.
  ///
  /// @return {@code true} if valid, {@code false} otherwise
  bool validateCVC() {
    if (isBlank(cvc)) {
      return false;
    }
    String cvcValue = cvc.trim();
    String updatedType = brand;
    bool validLength =
        (updatedType == null && cvcValue.length >= 3 && cvcValue.length <= 4) ||
            (AMERICAN_EXPRESS == updatedType && cvcValue.length == 4) ||
            cvcValue.length == 3;

    return ModelUtils.isWholePositiveNumber(cvcValue) && validLength;
  }

  /// Checks whether or not the {@link #expMonth} field is valid.
  ///
  /// @return {@code true} if valid, {@code false} otherwise.
  bool validateExpMonth() {
    return expMonth >= 1 && expMonth <= 12;
  }

  /// Checks whether or not the {@link #expYear} field is valid.
  ///
  /// @return {@code true} if valid, {@code false} otherwise.
  bool validateExpYear(DateTime now) {
    return !ModelUtils.hasYearPassed(expYear, now);
  }

  bool _validateCard(DateTime now) {
    if (cvc.isEmpty) {
      return validateNumber() && _validateExpiryDate(now);
    } else {
      return validateNumber() && _validateExpiryDate(now) && validateCVC();
    }
  }

  bool _validateExpiryDate(DateTime now) {
    if (!validateExpMonth()) {
      return false;
    }
    if (!validateExpYear(now)) {
      return false;
    }
    return !ModelUtils.hasMonthPassed(expYear, expMonth, now);
  }

  @override
  Map<String, dynamic> toMap() {
    Map<String, dynamic> map = {
      FIELD_NUMBER: number,
      FIELD_CVC: cvc,
      FIELD_NAME: name,
      FIELD_ADDRESS_CITY: addressCity,
      FIELD_ADDRESS_COUNTRY: addressCountry,
      FIELD_ADDRESS_LINE1: addressLine1,
      FIELD_ADDRESS_LINE1_CHECK: addressLine1Check,
      FIELD_ADDRESS_LINE2: addressLine2,
      FIELD_ADDRESS_STATE: addressState,
      FIELD_ADDRESS_ZIP: addressZip,
      FIELD_ADDRESS_ZIP_CHECK: addressZipCheck,
      FIELD_CURRENCY: currency,
      FIELD_COUNTRY: country,
      FIELD_CUSTOMER: customerId,
      FIELD_EXP_MONTH: expMonth,
      FIELD_EXP_YEAR: expYear,
      FIELD_FINGERPRINT: fingerprint,
      FIELD_FUNDING: funding,
      FIELD_ID: id,
      FIELD_LAST4: last4,
      FIELD_TOKENIZATION_METHOD: tokenizationMethod,
      FIELD_OBJECT: VALUE_CARD
    };

    removeNullAndEmptyParams(map);
    return map;
  }

  /// Converts an unchecked String value to a {@link CardBrand} or {@code null}.
  ///
  /// @param possibleCardType a String that might match a {@link CardBrand} or be empty.
  /// @return {@code null} if the input is blank, else the appropriate {@link CardBrand}.
  static String asCardBrand(String possibleCardType) {
    if (possibleCardType.isEmpty || possibleCardType.trim().isEmpty) {
      return StripeCard.UNKNOWN;
    }

    if (StripeCard.AMERICAN_EXPRESS == possibleCardType) {
      return StripeCard.AMERICAN_EXPRESS;
    } else if (StripeCard.MASTERCARD == possibleCardType) {
      return StripeCard.MASTERCARD;
    } else if (StripeCard.DINERS_CLUB == possibleCardType) {
      return StripeCard.DINERS_CLUB;
    } else if (StripeCard.DISCOVER == possibleCardType) {
      return StripeCard.DISCOVER;
    } else if (StripeCard.JCB == possibleCardType) {
      return StripeCard.JCB;
    } else if (StripeCard.VISA == possibleCardType) {
      return StripeCard.VISA;
    } else if (StripeCard.UNIONPAY == possibleCardType) {
      return StripeCard.UNIONPAY;
    } else {
      return StripeCard.UNKNOWN;
    }
  }

  /// Converts an unchecked String value to a {@link FundingType} or {@code null}.
  ///
  /// @param possibleFundingType a String that might match a {@link FundingType} or be empty
  /// @return {@code null} if the input is blank, else the appropriate {@link FundingType}
  static String asFundingType(String possibleFundingType) {
    if (possibleFundingType.isEmpty || possibleFundingType.trim().isEmpty) {
      return StripeCard.FUNDING_UNKNOWN;
    }

    if (StripeCard.FUNDING_CREDIT == possibleFundingType) {
      return StripeCard.FUNDING_CREDIT;
    } else if (StripeCard.FUNDING_DEBIT == possibleFundingType) {
      return StripeCard.FUNDING_DEBIT;
    } else if (StripeCard.FUNDING_PREPAID == possibleFundingType) {
      return StripeCard.FUNDING_PREPAID;
    } else {
      return StripeCard.FUNDING_UNKNOWN;
    }
  }
}
