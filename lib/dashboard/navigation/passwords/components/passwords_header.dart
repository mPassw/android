import 'package:flutter/material.dart';

class PasswordsHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget? button;

  const PasswordsHeader(
      {super.key, required this.title, required this.icon, this.button});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Material(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(8.0),
            topRight: Radius.circular(8.0),
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: Colors.grey[800]!, width: 1.0),
              left: BorderSide(color: Colors.grey[800]!, width: 1.0),
              right: BorderSide(color: Colors.grey[800]!, width: 1.0),
            ),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(8.0),
              topRight: Radius.circular(8.0),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(icon),
                    SizedBox(width: 8),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (button != null)
                Padding(padding: EdgeInsets.all(6), child: button!),
            ],
          ),
        ),
      ),
    );
  }
}
