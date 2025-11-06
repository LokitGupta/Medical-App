import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medical_app/models/payment_model.dart';
import 'package:medical_app/services/supabase_service.dart';

class PaymentState {
  final List<PaymentModel> payments;
  final List<PaymentMethodModel> paymentMethods;
  final List<InsuranceModel> insurances;
  final bool isLoading;
  final String? error;

  PaymentState({
    this.payments = const [],
    this.paymentMethods = const [],
    this.insurances = const [],
    this.isLoading = false,
    this.error,
  });

  PaymentState copyWith({
    List<PaymentModel>? payments,
    List<PaymentMethodModel>? paymentMethods,
    List<InsuranceModel>? insurances,
    bool? isLoading,
    String? error,
  }) {
    return PaymentState(
      payments: payments ?? this.payments,
      paymentMethods: paymentMethods ?? this.paymentMethods,
      insurances: insurances ?? this.insurances,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class PaymentNotifier extends StateNotifier<PaymentState> {
  final SupabaseService _supabaseService;

  PaymentNotifier(this._supabaseService) : super(PaymentState());

  Future<void> getUserPayments() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final currentUser = await _supabaseService.getCurrentUser();
      if (currentUser == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'User not authenticated',
        );
        return;
      }
      final payments = await _supabaseService.getUserPayments(currentUser.id);
      state = state.copyWith(payments: payments, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load payments: ${e.toString()}',
      );
    }
  }

  Future<void> getUserPaymentMethods() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final currentUser = await _supabaseService.getCurrentUser();
      if (currentUser == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'User not authenticated',
        );
        return;
      }
      final methods = await _supabaseService.getUserPaymentMethods(currentUser.id);
      state = state.copyWith(paymentMethods: methods, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load payment methods: ${e.toString()}',
      );
    }
  }

  Future<void> getUserInsurances() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      // No backend method defined; keep current state or load from another source if available
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load insurances: ${e.toString()}',
      );
    }
  }

  Future<void> addPaymentMethod(PaymentMethodModel method) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final newMethod = await _supabaseService.addPaymentMethod(method);
      final updatedMethods = [...state.paymentMethods, newMethod];
      state = state.copyWith(paymentMethods: updatedMethods, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to add payment method: ${e.toString()}',
      );
    }
  }

  Future<void> removePaymentMethod(String methodId) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      await _supabaseService.removePaymentMethod(methodId);
      final updatedMethods = state.paymentMethods
          .where((method) => method.id != methodId)
          .toList();
      state = state.copyWith(paymentMethods: updatedMethods, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to remove payment method: ${e.toString()}',
      );
    }
  }

  Future<void> setDefaultPaymentMethod(String methodId) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final currentUser = await _supabaseService.getCurrentUser();
      if (currentUser == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'User not authenticated',
        );
        return;
      }
      await _supabaseService.setDefaultPaymentMethod(currentUser.id, methodId);

      final updatedMethods = state.paymentMethods.map((method) {
        return method.id == methodId
            ? PaymentMethodModel(
                id: method.id,
                userId: method.userId,
                type: method.type,
                name: method.name,
                last4: method.last4,
                expiryMonth: method.expiryMonth,
                expiryYear: method.expiryYear,
                isDefault: true,
                details: method.details,
              )
            : PaymentMethodModel(
                id: method.id,
                userId: method.userId,
                type: method.type,
                name: method.name,
                last4: method.last4,
                expiryMonth: method.expiryMonth,
                expiryYear: method.expiryYear,
                isDefault: false,
                details: method.details,
              );
      }).toList();

      state = state.copyWith(paymentMethods: updatedMethods, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to set default payment method: ${e.toString()}',
      );
    }
  }

  Future<void> addInsurance(InsuranceModel insurance) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      // No backend method defined; update local state
      final updatedInsurances = [...state.insurances, insurance];
      state = state.copyWith(insurances: updatedInsurances, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to add insurance: ${e.toString()}',
      );
    }
  }

  Future<void> removeInsurance(String insuranceId) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      // No backend method defined; update local state
      final updatedInsurances = state.insurances
          .where((insurance) => insurance.id != insuranceId)
          .toList();
      state = state.copyWith(insurances: updatedInsurances, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to remove insurance: ${e.toString()}',
      );
    }
  }

  Future<PaymentModel?> processPayment({
    required String paymentType,
    required String referenceId,
    required double amount,
    required String paymentMethod,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final currentUser = await _supabaseService.getCurrentUser();
      if (currentUser == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'User not authenticated',
        );
        return null;
      }
      final payment = await _supabaseService.processPayment(
        userId: currentUser.id,
        paymentType: paymentType,
        referenceId: referenceId,
        amount: amount,
        paymentMethod: paymentMethod,
      );

      final updatedPayments = [...state.payments, payment];
      state = state.copyWith(payments: updatedPayments, isLoading: false);

      return payment;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Payment failed: ${e.toString()}',
      );
      return null;
    }
  }
}

// Provider for Supabase service
final supabaseServiceProvider = Provider<SupabaseService>((ref) {
  return SupabaseService();
});

final paymentProvider =
    StateNotifierProvider<PaymentNotifier, PaymentState>((ref) {
  final supabaseService = ref.watch(supabaseServiceProvider);
  return PaymentNotifier(supabaseService);
});
