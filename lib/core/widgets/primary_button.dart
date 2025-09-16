import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PrimaryButton extends StatefulWidget {
  final double width;
  final String text;
  final VoidCallback? onPressed;
  final Color? inActiveBackgroundColor;
  final bool isActive;
  final double iconSize;
  final bool isLoading;

  const PrimaryButton({
    super.key,
    this.width = double.infinity,
    required this.text,
    this.onPressed,
    this.inActiveBackgroundColor,
    this.isActive = true,
    this.iconSize = 24.0,
    this.isLoading = false,
  });

  @override
  State<PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<PrimaryButton> {
  @override
  Widget build(BuildContext context) {
    // Use ShapeDecoration type — not BoxDecoration
    ShapeDecoration backgroundDecoration;

    if (!widget.isActive) {
      backgroundDecoration = ShapeDecoration(
        color: widget.inActiveBackgroundColor ?? const Color(0xFFB0B0B0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
      );
    } else {
      backgroundDecoration = ShapeDecoration(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
        gradient: LinearGradient(
          begin: Alignment(0.50, -0.00),
          end: Alignment(0.50, 1.00),
          colors: [const Color(0xFF50D4FB), const Color(0xFF3AA5E3)],
        ),
      );
    }

    bool isEnabled =
        widget.isActive && !widget.isLoading && widget.onPressed != null;

    return Container(
      width: widget.width,
      height: 48,
      clipBehavior: Clip.antiAlias,
      decoration: backgroundDecoration,
      // ← ShapeDecoration is valid here
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isEnabled ? widget.onPressed : null,
          borderRadius: BorderRadius.circular(99),
          child: Center(
            child: widget.isLoading
                ? SizedBox(
                    width: widget.iconSize,
                    height: widget.iconSize,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.0,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    widget.text,
                    style: GoogleFonts.publicSans(
                      color: const Color(0xFFFEFEFE),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      height: 1.50,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
