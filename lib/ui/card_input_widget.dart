import 'package:flutter/material.dart';
import 'package:stripe_api/card_utils.dart';
import 'package:stripe_api/model/card.dart';
import 'package:stripe_api/model/model_utils.dart';
import 'package:stripe_api/stripe_text_utils.dart';
import 'package:stripe_api/ui/masked_text_controller.dart';

class CardInputWidget extends StatefulWidget {
  final EdgeInsetsGeometry margin;
  final double width;
  final StripeCard initialCard;
  final ValueChanged<StripeCard> onCardChanged;
  final Color expiryDateErrorTextColor;

  const CardInputWidget({
    Key key,
    this.margin = const EdgeInsets.symmetric(
      horizontal: 6.0,
    ),
    this.width,
    this.initialCard,
    @required this.onCardChanged,
    this.expiryDateErrorTextColor = Colors.red,
  }) : super(key: key);

  @override
  _CardInputWidgetState createState() => _CardInputWidgetState();
}

class _CardInputWidgetState extends State<CardInputWidget> {
  static const cardAssets = <String, String>{
    StripeCard.UNKNOWN: 'assets/images/stp_card_unknown.png',
    StripeCard.AMERICAN_EXPRESS: 'assets/images/stp_card_amex.png',
    StripeCard.DISCOVER: 'assets/images/stp_card_discover.png',
    StripeCard.JCB: 'assets/images/stp_card_jcb.png',
    StripeCard.DINERS_CLUB: 'assets/images/stp_card_diners.png',
    StripeCard.VISA: 'assets/images/stp_card_visa.png',
    StripeCard.MASTERCARD: 'assets/images/stp_card_mastercard.png',
    StripeCard.UNIONPAY: 'assets/images/stp_card_unionpay_en.png',
    'stp_card_error': 'assets/images/stp_card_error.png',
    'stp_card_error_amex': 'assets/images/stp_card_error_amex.png',
    'stp_card_cvc': 'assets/images/stp_card_cvc.png',
  };

  final String _package = 'stripe_api';

  //
  CreditCardMaskedTextController _cardNumberController;
  MaskedTextController _expiryDateController;
  MaskedTextController _cvcController;

  //
  FocusNode _cardNumberFocusNode;
  FocusNode _expiryDateFocusNode;
  FocusNode _cvcFocusNode;

  //
  String _cardBrandIcon;
  Color _expiryDateErrorTextColor;

  @override
  void initState() {
    if (widget.initialCard != null) {
      final c = widget.initialCard;
      _cardNumberController = CreditCardMaskedTextController(text: c.number);
      _expiryDateController = MaskedTextController(
          mask: '00/00', text: '${c.expMonth}/${c.expYear}');
      _cvcController = MaskedTextController(mask: '0000', text: c.cvc);
    } else {
      _cardNumberController = CreditCardMaskedTextController();
      _expiryDateController = MaskedTextController(mask: '00/00');
      _cvcController = MaskedTextController(mask: '0000');
    }

    //
    _cardNumberController.addListener(_cardNumberListener);
    _expiryDateController.addListener(_expiryDateListener);
    _cvcController.addListener(_cvcListener);

    //
    _cardNumberFocusNode = FocusNode();
    _expiryDateFocusNode = FocusNode();
    _cvcFocusNode = FocusNode();

    _cardNumberFocusNode.addListener(_cardNumberFocusListener);
    _expiryDateFocusNode.addListener(_expiryDateFocusListener);
    _cvcFocusNode.addListener(_cvcFocusListener);

    _cardBrandIcon = cardAssets[StripeCard.UNKNOWN];
    super.initState();
  }

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryDateController.dispose();
    _cvcController.dispose();

    //
    _cardNumberController.removeListener(_cardNumberListener);
    _expiryDateController.removeListener(_expiryDateListener);
    _cvcController.removeListener(_cvcListener);

    //
    _cardNumberFocusNode.removeListener(_cardNumberFocusListener);
    _expiryDateFocusNode.removeListener(_expiryDateFocusListener);
    _cvcFocusNode.removeListener(_cvcFocusListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width,
      margin: widget.margin,
      child: SingleChildScrollView(
        child: Row(
          children: <Widget>[
            Image.asset(
              _cardBrandIcon,
              width: 32.0,
              height: 21.0,
              package: _package,
            ),
            SizedBox(width: 6.0),
            Expanded(
              flex: 120,
              child: TextField(
                focusNode: _cardNumberFocusNode,
                controller: _cardNumberController,
                keyboardType: TextInputType.numberWithOptions(
                  signed: false,
                  decimal: false,
                ),
                decoration: InputDecoration(hintText: 'Card number'),
              ),
            ),
            SizedBox(width: 12.0),
            Expanded(
              flex: 50,
              child: TextField(
                focusNode: _expiryDateFocusNode,
                controller: _expiryDateController,
                keyboardType: TextInputType.numberWithOptions(
                  signed: false,
                  decimal: false,
                ),
                style: TextStyle(color: _expiryDateErrorTextColor),
                decoration: InputDecoration(hintText: 'MM/YY'),
              ),
            ),
            SizedBox(width: 12.0),
            Expanded(
              flex: 40,
              child: TextField(
                focusNode: _cvcFocusNode,
                controller: _cvcController,
                keyboardType: TextInputType.numberWithOptions(
                  signed: false,
                  decimal: false,
                ),
                decoration: InputDecoration(hintText: 'CVC'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  ///
  ///
  ///
  void _cardNumberListener() {
    setState(() {
      final cardBrand = getPossibleCardType(_cardNumberController.text);
      final isValidLen = isValidCardLength(
        removeSpacesAndHyphens(_cardNumberController.text),
        cardBrand: cardBrand,
      );

      if (!isValidLen) {
        final cardType = getPossibleCardType(_cardNumberController.text);
        _cardBrandIcon = cardAssets[cardType];
      } else {
        if (isValidCardNumber(_cardNumberController.text)) {
          _cardBrandIcon = cardAssets[cardBrand];
        } else {
          if (cardBrand == StripeCard.AMERICAN_EXPRESS) {
            _cardBrandIcon = cardAssets['stp_card_error'];
          } else {
            _cardBrandIcon = cardAssets['stp_card_error_amex'];
          }
        }
      }
      _notifyCardChanged();
    });
  }

  ///
  ///
  ///
  void _expiryDateListener() {
    setState(() {
      if (_expiryDateController.text.length > 4) {
        final expiry = _getExpiryMonthYear();
        if (_validateExpiryDate(expiry[0], expiry[1])) {
          _expiryDateErrorTextColor = null;
        } else {
          _expiryDateErrorTextColor = widget.expiryDateErrorTextColor;
        }
      } else {
        _expiryDateErrorTextColor = null;
      }

      _notifyCardChanged();
    });
  }

  ///
  ///
  ///
  void _cvcListener() {
    setState(() {
      _notifyCardChanged();
    });
  }

  ///
  ///
  ///
  void _cardNumberFocusListener() {
    //
  }

  ///
  ///
  ///
  void _expiryDateFocusListener() {
    //
  }

  ///
  ///
  ///
  void _cvcFocusListener() {
    if (_cvcFocusNode.hasFocus) {
      setState(() {
        _cardBrandIcon = cardAssets['stp_card_cvc'];
      });
    } else {
      setState(() {
        final cardType = getPossibleCardType(_cardNumberController.text);
        _cardBrandIcon = cardAssets[cardType];
      });
    }
  }

  void _notifyCardChanged() {
    if (widget.onCardChanged != null) {
      final expiry = _getExpiryMonthYear();
      final card = StripeCard(
        number: _cardNumberController.text,
        cvc: _cvcController.text,
        expMonth: expiry[0],
        expYear: expiry[1],
      );
      widget.onCardChanged(card);
    }
  }

  ///
  List<int> _getExpiryMonthYear() {
    int month = 0, year = 0;
    final expiry = _expiryDateController.text;
    if (expiry != null && expiry.isNotEmpty) {
      final parts = expiry.split('/');
      if (parts.length == 1) {
        month = int.tryParse(parts[0]);
      } else {
        month = int.tryParse(parts[0]);
        year = int.tryParse(parts[1]);
      }
    }
    return [month, year];
  }

  ///
  bool _validateExpiryDate(int expMonth, int expYear) {
    return !(expMonth == null ||
        expYear == null ||
        ModelUtils.hasMonthPassed(
          expYear,
          expMonth,
          DateTime.now(),
        ));
  }
}
