
import 'package:dio/dio.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

class StripeService {
  StripeService._();
  static final StripeService instance = StripeService._();

  Future<bool> makePayment(int amount) async {
    try {
      String? paymentIntentClientSecret = await _createPaymentIntent(amount, "vnd");
      if (paymentIntentClientSecret == null) return false;

      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: paymentIntentClientSecret,
          merchantDisplayName: "Food Delivery",
        ),
      );
      
      await Stripe.instance.presentPaymentSheet();
      await Stripe.instance.confirmPaymentSheetPayment();
      return true;
    } catch (e) {
      print(e);
      return false;
    }
  }

  Future<String?> _createPaymentIntent(int amount, String currency) async {
    try {
      final Dio dio = Dio();
      Map<String, dynamic> data = {
        "amount": amount.toString(),
        "currency": currency,
      };
      var response = await dio.post(
        "https://api.stripe.com/v1/payment_intents",
        data: data,
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          headers: {
            "Authorization": "Bearer sk_test_51QdkkKKaNRl3RZygHZ5KB0cpUJ5wg0usJgu2R5gt8xgCh4DfnUPiNVu9S4yl8xBUFkK3Q3Z3d9L5i9E0z0MYXlSj003qssRyCE", // Replace with your key
            "Content-Type": 'application/x-www-form-urlencoded'
          },
        ),
      );
      return response.data["client_secret"];
    } catch (e) {
      print(e);
      return null;
    }
  }
}