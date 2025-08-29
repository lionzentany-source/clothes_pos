// BotControlCubit: Controls bot start/stop state
import 'package:flutter_bloc/flutter_bloc.dart';
import '../services/bot_orchestrator_service.dart';

enum BotControlState { stopped, running, error }

class BotControlCubit extends Cubit<BotControlState> {
  final BotOrchestratorService orchestrator;

  BotControlCubit(this.orchestrator) : super(BotControlState.stopped);

  void startBot() {
    orchestrator.start();
    emit(BotControlState.running);
  }

    void stopBot() {
    orchestrator.stop();
    emit(BotControlState.stopped);
  }

  void reportError() {
    emit(BotControlState.error);
  }
}
