import 'package:flutter/material.dart';
import 'package:mpass/components/skeletons/password_card_skeleton.dart';
import 'package:mpass/dashboard/navigation/passwords/components/passwords_cards.dart';
import 'package:mpass/dashboard/navigation/passwords/state/autofill_state.dart';
import 'package:mpass/dashboard/navigation/passwords/state/passwords_state.dart';
import 'package:mpass/service/http_service.dart';
import 'package:mpass/state/network_state.dart';
import 'package:provider/provider.dart';

class PasswordListWidget extends StatelessWidget {
  final bool isTrash;

  const PasswordListWidget({
    super.key,
    required this.isTrash,
  });

  Future<void> _refreshPasswords(BuildContext context) async {
    final networkState = Provider.of<NetworkState>(context, listen: false);
    final passwordsState = Provider.of<PasswordsState>(context, listen: false);
    final autofillState = Provider.of<AutofillState>(context, listen: false);
    try {
      bool isAutofill = autofillState.isAutofill;
      bool isConnected = networkState.isConnected;
      if (isAutofill || !isConnected) {
        await passwordsState.fetchLocalPasswords();
      } else {
        await passwordsState.fetchPasswords();
      }
    } catch (error) {
      if (error is Exception && context.mounted) {
        HttpService.parseException(context, error);
      }
    } finally {
      passwordsState.setIsLoading(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final passwordsState = Provider.of<PasswordsState>(context);
    final isLoading = passwordsState.isLoading;

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: Material(
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(8.0),
              bottomRight: Radius.circular(8.0),
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(color: Colors.grey[800]!, width: 1.0),
                right: BorderSide(color: Colors.grey[800]!, width: 1.0),
                bottom: BorderSide(color: Colors.grey[800]!, width: 1.0),
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(8.0),
                bottomRight: Radius.circular(8.0),
              ),
            ),
            child: RefreshIndicator(
              onRefresh: () async {
                _refreshPasswords(context);
              },
              child: CustomScrollView(
                slivers: <Widget>[
                  SliverList(
                    delegate: SliverChildListDelegate([
                      if (isLoading)
                        ...List.generate(
                            6, (index) => const PasswordCardSkeleton())
                      else
                        PasswordCards(isTrash: isTrash),
                    ]),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
