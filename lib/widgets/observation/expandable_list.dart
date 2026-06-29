import 'package:flutter/material.dart';

class ExpandableList extends StatefulWidget {
  final List<String> items;
  final int previewCount;
  final Color accentColor;
  final TextStyle? textStyle;

  const ExpandableList({
    super.key,
    required this.items,
    required this.accentColor,
    this.previewCount = 3,
    this.textStyle,
  });

  @override
  State<ExpandableList> createState() => _ExpandableListState();
}

class _ExpandableListState extends State<ExpandableList> {
  bool expanded = false;

  @override
  Widget build(BuildContext context) {
    final hiddenCount = widget.items.length - widget.previewCount;

    final visibleItems = expanded
        ? widget.items
        : widget.items.take(widget.previewCount).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: visibleItems
                .map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      item,
                      style:
                          widget.textStyle ??
                          TextStyle(
                            color: Colors.white.withOpacity(0.78),
                            fontSize: 12.4,
                            fontWeight: FontWeight.w700,
                            height: 1.30,
                          ),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        if (hiddenCount > 0) ...[
          const SizedBox(height: 6),
          GestureDetector(
            onTap: () {
              setState(() {
                expanded = !expanded;
              });
            },
            child: Text(
              expanded ? 'Nascondi' : '+$hiddenCount altre',
              style: TextStyle(
                color: widget.accentColor,
                fontSize: 12.4,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
