import 'package:flutter/material.dart';

class CustomElevatedButton extends StatelessWidget {
  final String text; // Văn bản trên nút
  final VoidCallback onPressed; // Hành động khi nút được nhấn
  final Color? backgroundColor; // Màu nền của nút
  final Color? textColor; // Màu chữ
  final double borderRadius; // Độ bo góc
  final double? width; // Chiều rộng của nút
  final double? height; // Chiều cao của nút
  final TextStyle? textStyle; // Kiểu chữ tùy chỉnh
  final EdgeInsetsGeometry? padding; // Khoảng cách bên trong nút
  final Icon? icon; // Icon đi kèm (nếu có)
  final Color? borderColor; // Màu viền của nút
  final double borderWidth; // Độ dày viền
  final ButtonStyle? style; // Thêm style để tùy chỉnh các thuộc tính như padding, shape...

  const CustomElevatedButton({
    required this.text,
    required this.onPressed,
    this.backgroundColor,
    this.textColor,
    this.borderRadius = 100.0,
    this.width,
    this.height,
    this.textStyle,
    this.padding,
    this.icon,
    this.borderColor,
    this.borderWidth = 2.0,
    this.style, // Add the style parameter
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    // Màu nền
    final buttonBackgroundColor = brightness == Brightness.dark
        ? backgroundColor ?? const Color.fromARGB(255, 117, 63, 25)
        : backgroundColor ?? const Color.fromARGB(255, 210, 134, 79);

    // Màu chữ
    final buttonTextColor = brightness == Brightness.dark
        ? textColor ?? Colors.white // Màu chữ cho dark mode
        : textColor ?? Colors.black; // Màu chữ cho light mode

    // Màu viền
    final buttonBorderColor = brightness == Brightness.dark
        ? borderColor ?? const Color.fromARGB(255, 211, 155, 103).withOpacity(0.7)
        : borderColor ?? Colors.black; // Màu viền cho light mode

    return SizedBox(
      width: width,
      height: height,
      child: ElevatedButton(
        style: style ?? ElevatedButton.styleFrom(
          backgroundColor: buttonBackgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            side: BorderSide(
              color: buttonBorderColor, // Viền của nút
              width: borderWidth,
            ),
          ),
          padding: padding ?? const EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0),
        ),
        onPressed: onPressed,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              icon!,
              const SizedBox(width: 8), // Khoảng cách giữa icon và text
            ],
            Text(
              text,
              style: textStyle ??
                  TextStyle(
                    color: buttonTextColor,
                    fontSize: 16.0,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
