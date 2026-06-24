import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/algorithms/debt_simplification.dart';
import '../../../core/state/group_state.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_card.dart';

class DebtGraphWidget extends StatelessWidget {
  final GroupState groupState;
  final bool showSimplified;
  final VoidCallback onToggleSimplify;

  const DebtGraphWidget({
    super.key,
    required this.groupState,
    required this.showSimplified,
    required this.onToggleSimplify,
  });

  @override
  Widget build(BuildContext context) {
    final rawEdges = _rawEdges();
    final simplifiedEdges = groupState.simplifiedDebts;
    final activeEdges = showSimplified ? simplifiedEdges : rawEdges;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Debt graph',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              TextButton(
                onPressed: onToggleSimplify,
                child: Text(showSimplified ? 'Show raw' : 'Simplify'),
              ),
            ],
          ),
          Text(
            '${rawEdges.length} debts → ${simplifiedEdges.length} settlements',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 280,
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (groupState.members.isEmpty || activeEdges.isEmpty) {
                  return Center(
                    child: Text(
                      'Add expenses to visualize the debt graph.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  );
                }

                final size = Size(constraints.maxWidth, constraints.maxHeight);
                final positions = _nodePositions(size, groupState.members.length);
                final nodeMap = <String, Offset>{};
                for (var i = 0; i < groupState.members.length; i++) {
                  nodeMap[groupState.members[i].id] = positions[i];
                }

                return Stack(
                  children: [
                    CustomPaint(
                      size: size,
                      painter: _DebtGraphPainter(
                        edges: activeEdges,
                        nodePositions: nodeMap,
                        color: showSimplified ? AppColors.owedToYou : AppColors.owed,
                      ),
                    ),
                    for (var i = 0; i < groupState.members.length; i++)
                      Positioned(
                        left: positions[i].dx - 24,
                        top: positions[i].dy - 24,
                        child: _GraphNode(
                          label: _initials(groupState.members[i].name),
                          name: groupState.members[i].name,
                          color: i.isEven ? AppColors.primary : AppColors.secondary,
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<DebtTransfer> _rawEdges() {
    final memberIds = groupState.members.map((member) => member.id).toSet();
    final edges = <DebtTransfer>[];

    for (final expense in groupState.expenses) {
      for (final split in groupState.splits.where((s) => s.expenseId == expense.id)) {
        if (split.userId == expense.payerId) continue;
        if (!memberIds.contains(split.userId) || !memberIds.contains(expense.payerId)) {
          continue;
        }
        edges.add(
          DebtTransfer(
            fromUserId: split.userId,
            toUserId: expense.payerId,
            amount: split.amountOwed,
          ),
        );
      }
    }

    return edges;
  }

  List<Offset> _nodePositions(Size size, int count) {
    if (count == 1) {
      return [Offset(size.width / 2, size.height / 2)];
    }

    final radius = math.min(size.width, size.height) / 2 - 34;
    final center = Offset(size.width / 2, size.height / 2);

    return List.generate(count, (index) {
      final angle = (math.pi * 2 * index / count) - math.pi / 2;
      return Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
    });
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((part) => part.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'.toUpperCase();
  }
}

class _GraphNode extends StatelessWidget {
  final String label;
  final String name;
  final Color color;

  const _GraphNode({
    required this.label,
    required this.name,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: color.withValues(alpha: 0.15),
          child: Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          width: 64,
          child: Text(
            name,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    );
  }
}

class _DebtGraphPainter extends CustomPainter {
  final List<DebtTransfer> edges;
  final Map<String, Offset> nodePositions;
  final Color color;

  _DebtGraphPainter({
    required this.edges,
    required this.nodePositions,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.8)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (final edge in edges) {
      final from = nodePositions[edge.fromUserId];
      final to = nodePositions[edge.toUserId];
      if (from == null || to == null) continue;

      final path = Path();
      final angle = math.atan2(to.dy - from.dy, to.dx - from.dx);
      final offset = const Offset(24, 24);
      final start = from + Offset(math.cos(angle) * offset.dx, math.sin(angle) * offset.dy);
      final end = to - Offset(math.cos(angle) * offset.dx, math.sin(angle) * offset.dy);

      path.moveTo(start.dx, start.dy);
      path.lineTo(end.dx, end.dy);
      canvas.drawPath(path, paint);

      _drawArrowHead(canvas, end, angle, paint);
      _drawAmountBadge(canvas, start, end, edge.amount);
    }
  }

  void _drawArrowHead(Canvas canvas, Offset end, double angle, Paint paint) {
    final arrowPaint = Paint()
      ..color = paint.color
      ..style = PaintingStyle.fill;

    final path = Path();
    const arrowSize = 8.0;
    final left = Offset(
      end.dx - arrowSize * math.cos(angle - math.pi / 6),
      end.dy - arrowSize * math.sin(angle - math.pi / 6),
    );
    final right = Offset(
      end.dx - arrowSize * math.cos(angle + math.pi / 6),
      end.dy - arrowSize * math.sin(angle + math.pi / 6),
    );
    path.moveTo(end.dx, end.dy);
    path.lineTo(left.dx, left.dy);
    path.lineTo(right.dx, right.dy);
    path.close();
    canvas.drawPath(path, arrowPaint);
  }

  void _drawAmountBadge(Canvas canvas, Offset start, Offset end, double amount) {
    final midpoint = Offset(
      (start.dx + end.dx) / 2,
      (start.dy + end.dy) / 2,
    );
    final textPainter = TextPainter(
      text: TextSpan(
        text: '₹${amount.toStringAsFixed(0)}',
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final rect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: midpoint,
        width: textPainter.width + 14,
        height: textPainter.height + 8,
      ),
      const Radius.circular(10),
    );
    canvas.drawRRect(
      rect,
      Paint()..color = Colors.white.withValues(alpha: 0.9),
    );
    textPainter.paint(
      canvas,
      Offset(
        midpoint.dx - textPainter.width / 2,
        midpoint.dy - textPainter.height / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant _DebtGraphPainter oldDelegate) {
    return oldDelegate.edges != edges ||
        oldDelegate.nodePositions != nodePositions ||
        oldDelegate.color != color;
  }
}
