import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class LoadingBox extends StatelessWidget {
  const LoadingBox({super.key, this.height, this.width});
  final double? height;
  final double? width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: width,
      child: Shimmer.fromColors(
        baseColor: Colors.grey[100]!,
        highlightColor: Colors.grey[300]!,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20)
          ),
        ),
      ),
    );
  }
}