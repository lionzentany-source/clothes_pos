import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:clothes_pos/presentation/settings/bloc/settings_cubit.dart';
import 'package:clothes_pos/core/format/currency_formatter.dart';

String money(BuildContext context, double amount) {
  final st = context.read<SettingsCubit>().state;
  return CurrencyFormatter.format(
    amount,
    currency: st.currency,
    // Arabic-only locale fixed.
    locale: 'ar',
  );
}
