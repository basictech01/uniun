part of 'brahma_create_bloc.dart';

enum BrahmaCreateStatus { idle, submitting, success, error }

class BrahmaCreateState {
  const BrahmaCreateState({
    this.status = BrahmaCreateStatus.idle,
    this.errorMessage,
  });

  final BrahmaCreateStatus status;
  final String? errorMessage;

  bool get isSubmitting => status == BrahmaCreateStatus.submitting;

  BrahmaCreateState copyWith({
    BrahmaCreateStatus? status,
    String? errorMessage,
  }) {
    return BrahmaCreateState(
      status: status ?? this.status,
      errorMessage: errorMessage,
    );
  }
}
