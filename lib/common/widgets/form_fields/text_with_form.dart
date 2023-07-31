import 'package:flutter/material.dart';

class TextWithForm extends StatelessWidget {
  const TextWithForm({
    this.visible = true,
    required this.title,
    this.initialValue = '',
    this.onChanged,
    this.onSaved,
    this.validator,
    super.key,
  });

  final bool visible;

  final String title;
  final String initialValue;
  final void Function(String? text)? onChanged;
  final void Function(String? text)? onSaved;
  final String? Function(String? text)? validator;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        TextFormField(
          initialValue: initialValue,
          onChanged: onChanged,
          onSaved: onSaved,
          validator: validator,
          style: Theme.of(context).textTheme.bodyMedium,
          minLines: 1,
          maxLines: 10,
        ),
      ],
    );
  }
}