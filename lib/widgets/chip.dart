import 'package:flutter/material.dart';
import 'package:instrutor_em_casa/widgets/theme.dart';

enum AppChipType {none, done, waiting, inactive}

class AppChip extends StatelessWidget {
  const AppChip({super.key, required this.title, this.type = AppChipType.none, this.circle = true});
  final String title;
  final AppChipType type;
  final bool circle;

  @override
  Widget build(BuildContext context) {

    Color color(){
      switch (type) {
        case AppChipType.none:
          return AppColors.primary;
        case AppChipType.done:
          return AppColors.success;
        case AppChipType.waiting:
          return AppColors.warning;
        case AppChipType.inactive:
          return AppColors.textSecondary;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color().withAlpha(50),
        borderRadius: BorderRadius.circular(100)
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          circle ? Padding(
            padding: const EdgeInsets.only(right: 5),
            child: CircleAvatar(radius: 3, backgroundColor: color(),),
          ) : SizedBox(),
          Text(
            title,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: color(), letterSpacing: 0.04 * 0.5),
          )
        ],
      ),
    );
  }
}