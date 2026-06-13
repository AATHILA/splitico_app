import 'package:flutter_bloc/flutter_bloc.dart';
import 'base_event.dart';
import 'base_state.dart';

abstract class BaseBloc<Event extends BaseEvent, State extends BaseState> extends Bloc<Event, State> {
  BaseBloc(super.initialState);
}
