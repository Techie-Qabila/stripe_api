import 'package:flutter/material.dart';
import 'package:stripe_api/stripe_api.dart';

class CreditCardMaskedTextController extends TextEditingController {
  CreditCardMaskedTextController({String text}) : super(text: text) {
    this._translator = CreditCardMaskedTextController._getDefaultTranslator();

    this.addListener(() {
      this._updateText(this.text);
    });

    this._updateText(this.text);
  }

  static const CARD_MASKS = const {
    StripeCard.UNKNOWN: '0000 0000 0000 0000',
    StripeCard.AMERICAN_EXPRESS: '0000 000000 00000',
    StripeCard.DISCOVER: '0000 0000 0000 0000',
    StripeCard.JCB: '0000 0000 0000 0000',
    StripeCard.DINERS_CLUB: '0000 0000 0000 00',
    StripeCard.VISA: '0000 0000 0000 0000',
    StripeCard.MASTERCARD: '0000 0000 0000 0000',
    StripeCard.UNIONPAY: '0000 0000 0000 0000',
  };

  Map<String, RegExp> _translator;
  String _lastUpdatedText = '';

  void _updateText(String text) {
    if (text != null) {
      final cardType = getPossibleCardType(text, shouldNormalize: true);
      final mask = CARD_MASKS[cardType];
      this.text = this._applyMask(mask, text);
    } else {
      this.text = '';
    }
    this._lastUpdatedText = this.text;
  }

  void _moveCursorToEnd() {
    var text = this._lastUpdatedText;
    this.selection = TextSelection.fromPosition(
      TextPosition(offset: (text ?? '').length),
    );
  }

  @override
  set text(String newText) {
    if (super.text != newText) {
      super.text = newText;
      this._moveCursorToEnd();
    }
  }

  static Map<String, RegExp> _getDefaultTranslator() {
    return {
      'A': RegExp(r'[A-Za-z]'),
      '0': RegExp(r'[0-9]'),
      '@': RegExp(r'[A-Za-z0-9]'),
      '*': RegExp(r'.*')
    };
  }

  String _applyMask(String mask, String value) {
    String result = '';

    int maskCharIndex = 0;
    int valueCharIndex = 0;

    while (true) {
      // if mask is ended, break.
      if (maskCharIndex == mask.length) {
        break;
      }

      // if value is ended, break.
      if (valueCharIndex == value.length) {
        break;
      }

      var maskChar = mask[maskCharIndex];
      var valueChar = value[valueCharIndex];

      // value equals mask, just set
      if (maskChar == valueChar) {
        result += maskChar;
        valueCharIndex += 1;
        maskCharIndex += 1;
        continue;
      }

      // apply translator if match
      if (this._translator.containsKey(maskChar)) {
        if (this._translator[maskChar].hasMatch(valueChar)) {
          result += valueChar;
          maskCharIndex += 1;
        }

        valueCharIndex += 1;
        continue;
      }

      // not masked value, fixed char on mask
      result += maskChar;
      maskCharIndex += 1;
      continue;
    }

    return result;
  }
}
