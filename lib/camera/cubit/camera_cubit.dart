import 'package:bloc/bloc.dart';

class CameraCubit extends Cubit<int> {
  CameraCubit() : super(0);

  void increment() => emit(state + 1);
  void decrement() => emit(state - 1);
}
