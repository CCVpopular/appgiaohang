import 'package:flutter/material.dart';

class CustomCard extends StatelessWidget {
  final Widget child; // Nội dung của thẻ
  final Color? lightBackgroundColor; // Màu nền cho chế độ sáng
  final Color? darkBackgroundColor; // Màu nền cho chế độ tối
  final Color? lightBorderColor; // Màu viền cho chế độ sáng
  final Color? darkBorderColor; // Màu viền cho chế độ tối
  final EdgeInsets? borderWidth; // Độ dày viền từng mặt (trên, dưới, trái, phải)
  final BorderRadius? borderRadius; // Bo góc
  final EdgeInsetsGeometry? padding; // Padding bên trong thẻ
  final EdgeInsetsGeometry? margin; // Margin bên ngoài thẻ
  final BoxShadow? lightShadow; // Bóng của thẻ cho chế độ sáng
  final BoxShadow? darkShadow; // Bóng của thẻ cho chế độ tối

  const CustomCard({
    required this.child,
    this.lightBackgroundColor,
    this.darkBackgroundColor,
    this.lightBorderColor,
    this.darkBorderColor,
    this.borderWidth,
    this.borderRadius,
    this.padding,
    this.margin,
    this.lightShadow,
    this.darkShadow,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    // Màu nền
    final backgroundColor = brightness == Brightness.dark
        ? darkBackgroundColor ?? const Color.fromARGB(255, 80, 44, 10)
        : lightBackgroundColor ?? const Color.fromARGB(255, 255, 229, 210);

    // Màu viền
    final borderColor = brightness == Brightness.dark
        ? darkBorderColor ?? const Color.fromARGB(255, 0, 0, 0)
        : lightBorderColor ?? const Color.fromARGB(255, 0, 0, 0);

    // Bóng của thẻ
    final boxShadow = brightness == Brightness.dark
        ? darkShadow ?? const BoxShadow(color: Colors.black38, blurRadius: 6.0)
        : lightShadow ?? const BoxShadow(color: Colors.grey, blurRadius: 6.0);

    // Viền với độ dày tùy chỉnh từng mặt
    final border = Border(
      top: BorderSide(
        color: borderColor,
        width: borderWidth?.top ?? 2.0,
      ),
      bottom: BorderSide(
        color: borderColor,
        width: borderWidth?.bottom ?? 4.0,
      ),
      left: BorderSide(
        color: borderColor,
        width: borderWidth?.left ?? 2.0,
      ),
      right: BorderSide(
        color: borderColor,
        width: borderWidth?.right ?? 2.0,
      ),
    );

    return Container(
      margin: margin ?? const EdgeInsets.all(0),
      padding: padding ?? const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: borderRadius ?? BorderRadius.circular(12.0),
        border: border,
        boxShadow: null,
      ),
      child: child,
    );
  }
}
