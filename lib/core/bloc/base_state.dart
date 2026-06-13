import 'package:equatable/equatable.dart';

abstract class BaseState extends Equatable {
  const BaseState();

  @override
  List<Object?> get props => [];
}

class BaseInitial extends BaseState {
  const BaseInitial();
}

class BaseLoading extends BaseState {
  const BaseLoading(); 
}

class BaseSuccess<T> extends BaseState {
  final T data;

  const BaseSuccess(this.data);

  @override
  List<Object?> get props => [data];
}

class BaseError extends BaseState {
  final String message;

  const BaseError(this.message);

  @override
  List<Object?> get props => [message];
}
