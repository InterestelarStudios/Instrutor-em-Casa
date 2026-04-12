import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:instrutor_em_casa/widgets/theme.dart';

class SelectOptionTile<T> extends StatelessWidget {
  final T value;
  final T groupValue;
  final String label;
  final Function(T) onChanged;

  const SelectOptionTile({
    super.key,
    required this.value,
    required this.groupValue,
    required this.label,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = value == groupValue;

    const Color activeColor = AppColors.primary;
    const Color activeBgColor = Color(0xFFE3F2FD);
    const Color inactiveColor = AppColors.gray400;
    const Color inactiveBorderColor = AppColors.borderStrong;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Ink(
        decoration: BoxDecoration(
          color: isSelected ? activeBgColor : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? activeColor.withAlpha(130) : inactiveBorderColor,
            width: 1.5,
          ),
        ),
        child: InkWell(
          onTap: () => onChanged(value),
          borderRadius: BorderRadius.circular(12),
          splashColor: activeColor.withAlpha(20),
          highlightColor: activeColor.withAlpha(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            child: Row(
              children: [
                // Radio Indicador
                Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? activeColor : inactiveColor,
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? Center(
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: activeColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                // Texto
                Text(
                  label,
                  style: GoogleFonts.dmSans(
                    color: isSelected ? activeColor : inactiveColor.withAlpha(200),
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}