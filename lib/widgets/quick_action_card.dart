import 'package:flutter/material.dart';

class QuickActionCard extends StatefulWidget {
  const QuickActionCard({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  @override
  State<QuickActionCard> createState() => _QuickActionCardState();
}

class _QuickActionCardState extends State<QuickActionCard> {
  bool _hovered = false;
  @override
  Widget build(BuildContext context) => MouseRegion(
    onEnter: (_) => setState(() => _hovered = true),
    onExit: (_) => setState(() => _hovered = false),
    cursor: SystemMouseCursors.click,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      transform: Matrix4.translationValues(0, _hovered ? -3 : 0, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _hovered ? const Color(0xFF8DB6F5) : const Color(0xFFE3EAF2),
        ),
        boxShadow: [
          BoxShadow(
            color: _hovered ? const Color(0x240D5BE1) : const Color(0x0F172033),
            blurRadius: _hovered ? 16 : 8,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: widget.onTap,
          splashColor: const Color(0x220D5BE1),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 210;
              return Padding(
                padding: EdgeInsets.all(compact ? 11 : 16),
                child: Row(
                  children: [
                    Container(
                      width: compact ? 40 : 46,
                      height: compact ? 40 : 46,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE9F1FF),
                        borderRadius: BorderRadius.circular(compact ? 10 : 12),
                      ),
                      child: Icon(
                        widget.icon,
                        color: const Color(0xFF0D5BE1),
                        size: compact ? 22 : 25,
                      ),
                    ),
                    SizedBox(width: compact ? 9 : 14),
                    Expanded(
                      child: Text(
                        widget.label,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        softWrap: true,
                        style: TextStyle(
                          color: const Color(0xFF172033),
                          fontSize: compact ? 12.5 : 14,
                          fontWeight: FontWeight.w700,
                          height: 1.15,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: const Color(0xFF9AAABD),
                      size: compact ? 19 : 24,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    ),
  );
}
