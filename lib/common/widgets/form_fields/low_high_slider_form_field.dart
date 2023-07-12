import 'dart:math';

import 'package:flutter/material.dart';

class LowHighSliderFormField extends FormField<double> {
  LowHighSliderFormField({
    super.key,
    double initialValue = 3,
    this.fixed = false,
    int decimal = 0,
    super.onSaved,
    this.min = 1,
    this.max = 5,
    this.lowLabel = 'Faible',
    this.highLabel = 'Élevé',
  })  : factor = pow(10, decimal).toDouble(),
        super(builder: _builder, enabled: true, initialValue: initialValue);

  final double factor;
  final String lowLabel;
  final String highLabel;
  final int min;
  final int max;
  final bool fixed; // We use true for enables so we have the active colors

  static Widget _builder(FormFieldState<double> state) {
    final fixed = (state.widget as LowHighSliderFormField).fixed;
    final factor = (state.widget as LowHighSliderFormField).factor;
    final lowLabel = (state.widget as LowHighSliderFormField).lowLabel;
    final highLabel = (state.widget as LowHighSliderFormField).highLabel;
    final min = (state.widget as LowHighSliderFormField).min;
    final max = (state.widget as LowHighSliderFormField).max;

    if (state.value! < min || state.value! > max) {
      return const Text('Aucune donnée pour l\'instant.');
    }

    return SizedBox(
      width: Size.infinite.width,
      child: Row(
        children: [
          Text(lowLabel, textAlign: TextAlign.center),
          Expanded(
            child: Slider(
              value: state.value! * factor,
              onChanged: (value) {
                fixed ? null : state.didChange(value / factor);
              },
              min: (min * factor).toDouble(),
              max: (max * factor).toDouble(),
              divisions: (max - min) * factor.toInt(),
              label: '${factor == 1 ? state.value!.toInt() : state.value!}',
            ),
          ),
          Text(highLabel, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
