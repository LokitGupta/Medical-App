import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

class ApiService {
  // Symptom checker API
  Future<Map<String, dynamic>> checkSymptoms(List<String> symptoms) async {
    final response = await http.post(
      Uri.parse('https://api.example.com/api/symptom-check'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'symptoms': symptoms}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to check symptoms: ${response.statusCode}');
    }
  }

  // Lab report analysis API
  Future<Map<String, dynamic>> analyzeLaboratoryReport(String reportUrl) async {
    final response = await http.post(
      Uri.parse('https://api.example.com/api/analyze-report'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'report_url': reportUrl}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to analyze report: ${response.statusCode}');
    }
  }

  // Stripe payment integration
  Future<Map<String, dynamic>> createPaymentIntent(double amount, String currency) async {
    final String? stripeSecretKey = dotenv.env['STRIPE_SECRET_KEY'];
    
    if (stripeSecretKey == null) {
      throw Exception('Stripe secret key not found in environment variables');
    }

    final Map<String, dynamic> body = {
      'amount': (amount * 100).toInt().toString(), // Convert to cents
      'currency': currency,
      'payment_method_types[]': 'card',
    };

    final response = await http.post(
      Uri.parse('https://api.stripe.com/v1/payment_intents'),
      headers: {
        'Authorization': 'Bearer $stripeSecretKey',
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: body,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to create payment intent: ${response.body}');
    }
  }

  Future<void> initializeStripePayment(String paymentIntentClientSecret) async {
    await Stripe.instance.initPaymentSheet(
      paymentSheetParameters: SetupPaymentSheetParameters(
        paymentIntentClientSecret: paymentIntentClientSecret,
        merchantDisplayName: 'Medical App',
        style: ThemeMode.system,
      ),
    );
  }

  Future<void> displayPaymentSheet() async {
    try {
      await Stripe.instance.presentPaymentSheet();
    } catch (e) {
      throw Exception('Error presenting payment sheet: $e');
    }
  }

  // FCM push notification
  Future<void> sendPushNotification({
    required String token,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    final String? serverKey = dotenv.env['FCM_SERVER_KEY'];
    
    if (serverKey == null) {
      throw Exception('FCM server key not found in environment variables');
    }

    final response = await http.post(
      Uri.parse('https://fcm.googleapis.com/fcm/send'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'key=$serverKey',
      },
      body: jsonEncode({
        'notification': {
          'title': title,
          'body': body,
        },
        'data': data ?? {},
        'to': token,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to send push notification: ${response.body}');
    }
  }
}