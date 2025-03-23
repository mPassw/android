import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mpass/dashboard/navigation/passwords/state/autofill_state.dart';
import 'package:mpass/dashboard/navigation/passwords/state/passwords_state.dart';
import 'package:provider/provider.dart';

class PasswordsSearchBar extends StatefulWidget {
  const PasswordsSearchBar({super.key, required this.isTrash});

  final bool isTrash;

  @override
  State<PasswordsSearchBar> createState() => _PasswordsSearchBarState();
}

class _PasswordsSearchBarState extends State<PasswordsSearchBar> {
  final TextEditingController _controller = TextEditingController();
  MethodChannel _channel = const MethodChannel("");

  @override
  void initState() {
    super.initState();
    final autofillState = Provider.of<AutofillState>(context, listen: false);
    final passwordState = Provider.of<PasswordsState>(context, listen: false);
    final isAutofill =
        Provider.of<AutofillState>(context, listen: false).isAutofill;

    if (isAutofill) {
      _channel = MethodChannel(autofillState.flutterEngineId ?? "");
    }
    _controller.text =
        widget.isTrash ? passwordState.trashFilter : passwordState.searchFilter;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isTrash = widget.isTrash;
    final passwordState = Provider.of<PasswordsState>(context);
    final isAutofill = Provider.of<AutofillState>(context).isAutofill;

    final searchFilter =
        isTrash ? passwordState.trashFilter : passwordState.searchFilter;

    if (_controller.text != searchFilter) {
      _controller.text = searchFilter;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: Row(children: [
        if (isAutofill)
          Row(children: [
            IconButton.filledTonal(
                onPressed: () {
                  _channel.invokeMethod('authenticationFailed');
                },
                icon: const Icon(Icons.arrow_back_outlined)),
            const SizedBox(width: 8)
          ]),
        Expanded(
          child: TextField(
            controller: _controller,
            decoration: const InputDecoration(
              labelText: 'Search Passwords',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              if (isTrash) {
                passwordState.setTrashFilter(value);
              } else {
                passwordState.setSearchFilter(value);
              }
            },
          ),
        )
      ]),
    );
  }
}
