import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final Color? lightBackgroundColor;
  final Color? darkBackgroundColor;
  final Color? lightTextColor;
  final Color? darkTextColor;
  final Color? lightIconColor;
  final Color? darkIconColor;
  final BorderRadius? borderRadius;
  final Color? lightBorderColor;
  final Color? darkBorderColor;
  final double topBorderThickness;
  final double leftBorderThickness;
  final double rightBorderThickness;
  final double bottomBorderThickness;

  const CustomAppBar({
    required this.title,
    this.actions,
    this.leading,
    this.lightBackgroundColor,
    this.darkBackgroundColor,
    this.lightTextColor,
    this.darkTextColor,
    this.lightIconColor,
    this.darkIconColor,
    this.borderRadius,
    this.lightBorderColor,
    this.darkBorderColor,
    this.topBorderThickness = 2.0, // Độ dày viền trên
    this.leftBorderThickness = 2.0, // Độ dày viền trái
    this.rightBorderThickness = 2.0, // Độ dày viền phải
    this.bottomBorderThickness = 4.0, // Độ dày viền dưới
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    // Màu nền
    final backgroundColor = brightness == Brightness.dark
        ? darkBackgroundColor ?? const Color.fromARGB(255, 117, 63, 25)
        : lightBackgroundColor ?? const Color.fromARGB(255, 210, 134, 79);

    // Màu chữ
    final textColor = brightness == Brightness.dark
        ? darkTextColor ?? Colors.white
        : lightTextColor ?? Colors.black;

    // Màu icon
    final iconColor = brightness == Brightness.dark
        ? darkIconColor ?? Colors.white
        : lightIconColor ?? Colors.black;

    // Màu viền
    final borderColor = brightness == Brightness.dark
        ? darkBorderColor ?? const Color.fromARGB(255, 211, 155, 103).withOpacity(0.7)
        : lightBorderColor ?? Colors.black.withOpacity(0.7);

    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight + 0),
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: borderRadius ??
              const BorderRadius.only(
                topLeft: Radius.circular(38.0), // Bo tròn góc trên trái
                topRight: Radius.circular(38.0), // Bo tròn góc trên phải
                bottomLeft: Radius.circular(20.0), // Bo tròn góc duoi phải
                bottomRight: Radius.circular(20.0), // Bo tròn góc duoi phải
              ),
          border: Border(
            top: BorderSide(
              color: borderColor,
              width: topBorderThickness,
            ),
            left: BorderSide(
              color: borderColor,
              width: leftBorderThickness,
            ),
            right: BorderSide(
              color: borderColor,
              width: rightBorderThickness,
            ),
            bottom: BorderSide(
              color: borderColor,
              width: bottomBorderThickness,
            ),
          ),
        ),
        child: AppBar(
          title: Text(
            title,
            style: TextStyle(color: textColor),
          ),
          actions: actions?.map((action) {
            // Tự động áp dụng màu icon
            if (action is IconButton) {
              return IconButton(
                icon: Icon(
                  (action.icon as Icon).icon,
                  color: iconColor,
                ),
                onPressed: action.onPressed,
              );
            }
            return action;
          }).toList(),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 0);
}
