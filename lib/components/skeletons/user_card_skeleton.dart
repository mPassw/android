import 'package:flutter/material.dart';
import 'package:mpass/components/skeletons/skeleton.dart';

class UserCardSkeleton extends StatelessWidget {
  const UserCardSkeleton({super.key});

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
              // Circular icon placeholder
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 16),
              // Column for email and badges
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Email text placeholder
                  Container(
                    width: 150,
                    height: 14,
                    color: Colors.white,
                  ),
                  SizedBox(height: 16),
                  // Row for badges
                  Row(
                    children: [
                      // First badge placeholder
                      Container(
                        width: 35,
                        height: 16,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      SizedBox(width: 8),
                      // Second badge placeholder
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
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    ));
  }
}
