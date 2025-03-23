import 'package:flutter/material.dart';
import 'package:mpass/components/skeletons/skeleton.dart';

class PasswordCardSkeleton extends StatelessWidget {
  const PasswordCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Skeleton(
        element: Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 12, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 150,
                    height: 14,
                    color: Colors.white,
                  ),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        width: 65,
                        height: 16,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      SizedBox(width: 8),
                      Container(
                        width: 65,
                        height: 16,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ));
  }
}
