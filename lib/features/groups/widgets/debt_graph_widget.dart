import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../core/algorithms/debt_simplification.dart';
import '../../../core/state/group_state.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/balance_chip.dart';

class _GraphEdge {
  final DebtTransfer transfer;
  final String expenseLabel;

  const _GraphEdge({
    required this.transfer,
    required this.expenseLabel,
  });
}

class _LayoutEdge {
  final _GraphEdge edge;
  final int laneIndex;
  final int laneCount;
  final bool reverseDirection;

  const _LayoutEdge({
    required this.edge,
    required this.laneIndex,
    required this.laneCount,
    required this.reverseDirection,
  });
}

class DebtGraphWidget extends StatefulWidget {
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
  State<DebtGraphWidget> createState() => _DebtGraphWidgetState();
}

class _DebtGraphWidgetState extends State<DebtGraphWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _magicController;

  @override
  void initState() {
    super.initState();
    _magicController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    if (widget.showSimplified) {
      _magicController.value = 1;
    }
  }

  @override
  void didUpdateWidget(covariant DebtGraphWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.showSimplified && widget.showSimplified) {
      _magicController.forward(from: 0);
    } else if (oldWidget.showSimplified && !widget.showSimplified) {
      _magicController.reverse();
    }
  }

  @override
  void dispose() {
    _magicController.dispose();
    super.dispose();
  }

  GroupState get groupState => widget.groupState;

  String _memberName(String userId) {
    for (final member in groupState.members) {
      if (member.id == userId) return member.name;
    }
    return 'Unknown';
  }

  @override
  Widget build(BuildContext context) {
    final rawEdges = _rawEdges();
    final simplifiedEdges = groupState.simplifiedDebts;
    final showSimplified = widget.showSimplified;
    final activeTransfers = showSimplified
        ? simplifiedEdges
        : rawEdges.map((edge) => edge.transfer).toList();

    final graphHeight = showSimplified
        ? 300.0
        : math.min(360.0, math.max(260.0, 220.0 + rawEdges.length * 6.0));

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Debt graph',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      showSimplified
                          ? '${simplifiedEdges.length} clean ${simplifiedEdges.length == 1 ? 'payment' : 'payments'}'
                          : '${rawEdges.length} individual ${rawEdges.length == 1 ? 'debt' : 'debts'}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _ModeToggle(
            showSimplified: showSimplified,
            onSelectRaw: showSimplified ? widget.onToggleSimplify : null,
            onSelectSimplified: showSimplified ? null : widget.onToggleSimplify,
          ),
          const SizedBox(height: 16),
          AnimatedBuilder(
            animation: _magicController,
            builder: (context, child) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOutCubic,
                height: graphHeight,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: showSimplified
                      ? LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.primary.withValues(alpha: 0.08 + _magicController.value * 0.06),
                            AppColors.success.withValues(alpha: 0.06 + _magicController.value * 0.08),
                          ],
                        )
                      : null,
                  color: showSimplified ? null : AppColors.background,
                  border: Border.all(
                    color: showSimplified
                        ? AppColors.success.withValues(alpha: 0.25 + _magicController.value * 0.2)
                        : AppColors.divider,
                  ),
                ),
                child: child,
              );
            },
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (groupState.members.isEmpty || activeTransfers.isEmpty) {
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
                final nodeMap = <String, Offset>{
                  for (var i = 0; i < groupState.members.length; i++)
                    groupState.members[i].id: positions[i],
                };

                final layoutEdges = showSimplified
                    ? _layoutEdges(
                        simplifiedEdges
                            .map((transfer) => _GraphEdge(transfer: transfer, expenseLabel: ''))
                            .toList(),
                        simplified: true,
                      )
                    : _layoutEdges(rawEdges, simplified: false);

                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    if (showSimplified)
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _GlowPainter(progress: _magicController.value),
                        ),
                      ),
                    CustomPaint(
                      size: size,
                      painter: _DebtGraphPainter(
                        layoutEdges: layoutEdges,
                        nodePositions: nodeMap,
                        simplified: showSimplified,
                        magicProgress: _magicController.value,
                        memberNames: {
                          for (final member in groupState.members) member.id: member.name,
                        },
                      ),
                    ),
                    for (var i = 0; i < groupState.members.length; i++)
                      Positioned(
                        left: positions[i].dx - 36,
                        top: positions[i].dy - 36,
                        child: _GraphNode(
                          label: _initials(groupState.members[i].name),
                          name: groupState.members[i].name,
                          balance: groupState.netBalances[groupState.members[i].id] ?? 0,
                          color: i.isEven ? AppColors.primary : AppColors.secondary,
                          highlighted: showSimplified,
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
          if (!showSimplified && rawEdges.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'All transactions',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: math.min(240.0, 56.0 * rawEdges.length),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: rawEdges.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final edge = rawEdges[index];
                  return _TransactionRow(
                    debtorName: _memberName(edge.transfer.fromUserId),
                    creditorName: _memberName(edge.transfer.toUserId),
                    amount: edge.transfer.amount,
                    expenseLabel: edge.expenseLabel,
                  );
                },
              ),
            ),
          ],
          if (showSimplified && simplifiedEdges.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.auto_awesome,
                    size: 16,
                    color: AppColors.success.withValues(alpha: 0.8 + _magicController.value * 0.2),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Reduced ${rawEdges.length} debts to ${simplifiedEdges.length}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  List<_GraphEdge> _rawEdges() {
    final memberIds = groupState.members.map((member) => member.id).toSet();
    final edges = <_GraphEdge>[];

    for (final expense in groupState.expenses) {
      for (final split in groupState.splits.where((split) => split.expenseId == expense.id)) {
        if (split.userId == expense.payerId) continue;
        if (!memberIds.contains(split.userId) || !memberIds.contains(expense.payerId)) {
          continue;
        }
        if (split.amountOwed < 0.01) continue;

        edges.add(
          _GraphEdge(
            transfer: DebtTransfer(
              fromUserId: split.userId,
              toUserId: expense.payerId,
              amount: _round(split.amountOwed),
            ),
            expenseLabel: expense.description,
          ),
        );
      }
    }

    return edges;
  }

  List<_LayoutEdge> _layoutEdges(List<_GraphEdge> edges, {required bool simplified}) {
    final grouped = <String, List<_GraphEdge>>{};
    for (final edge in edges) {
      final key = '${edge.transfer.fromUserId}->${edge.transfer.toUserId}';
      grouped.putIfAbsent(key, () => []).add(edge);
    }

    final layout = <_LayoutEdge>[];
    for (final entry in grouped.entries) {
      final parts = entry.key.split('->');
      final reverseKey = '${parts[1]}->${parts[0]}';
      final hasReverse = grouped.containsKey(reverseKey) && reverseKey != entry.key;

      for (var i = 0; i < entry.value.length; i++) {
        layout.add(
          _LayoutEdge(
            edge: entry.value[i],
            laneIndex: i,
            laneCount: entry.value.length,
            reverseDirection: hasReverse,
          ),
        );
      }
    }

    if (simplified) {
      return layout;
    }

    return layout;
  }

  List<Offset> _nodePositions(Size size, int count) {
    if (count == 1) {
      return [Offset(size.width / 2, size.height / 2)];
    }

    final radius = math.min(size.width, size.height) / 2 - 52;
    final center = Offset(size.width / 2, size.height / 2);

    return List.generate(count, (index) {
      final angle = (math.pi * 2 * index / count) - math.pi / 2;
      return Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
    });
  }

  double _round(double value) => (value * 100).round() / 100.0;

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((part) => part.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'.toUpperCase();
  }
}

class _ModeToggle extends StatelessWidget {
  final bool showSimplified;
  final VoidCallback? onSelectRaw;
  final VoidCallback? onSelectSimplified;

  const _ModeToggle({
    required this.showSimplified,
    this.onSelectRaw,
    this.onSelectSimplified,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ModeChip(
              label: 'All transactions',
              icon: Icons.list_alt,
              selected: !showSimplified,
              onTap: onSelectRaw,
            ),
          ),
          Expanded(
            child: _ModeChip(
              label: 'Simplify',
              icon: Icons.auto_awesome,
              selected: showSimplified,
              onTap: onSelectSimplified,
              accent: AppColors.success,
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback? onTap;
  final Color accent;

  const _ModeChip({
    required this.label,
    required this.icon,
    required this.selected,
    this.onTap,
    this.accent = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? accent.withValues(alpha: 0.14) : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: selected ? accent : AppColors.textSecondary),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontSize: 13,
                        color: selected ? accent : AppColors.textSecondary,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TransactionRow extends StatelessWidget {
  final String debtorName;
  final String creditorName;
  final double amount;
  final String expenseLabel;

  const _TransactionRow({
    required this.debtorName,
    required this.creditorName,
    required this.amount,
    required this.expenseLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          const Icon(Icons.arrow_forward, size: 16, color: AppColors.owed),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$debtorName → $creditorName',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                Text(
                  expenseLabel,
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Text(
            '₹${amount.toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppColors.owed,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class _GraphNode extends StatelessWidget {
  final String label;
  final String name;
  final double balance;
  final Color color;
  final bool highlighted;

  const _GraphNode({
    required this.label,
    required this.name,
    required this.balance,
    required this.color,
    required this.highlighted,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            decoration: highlighted
                ? BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.35),
                        blurRadius: 12,
                        spreadRadius: 1,
                      ),
                    ],
                  )
                : null,
            child: CircleAvatar(
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
          ),
          const SizedBox(height: 4),
          Text(
            name,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 2),
          BalanceChip(balance: balance),
        ],
      ),
    );
  }
}

class _GlowPainter extends CustomPainter {
  final double progress;

  _GlowPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final paint = Paint()
      ..shader = ui.Gradient.radial(
        Offset(size.width / 2, size.height / 2),
        size.shortestSide * 0.45,
        [
          AppColors.success.withValues(alpha: 0.14 * progress),
          Colors.transparent,
        ],
      );
    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(covariant _GlowPainter oldDelegate) => oldDelegate.progress != progress;
}

class _DebtGraphPainter extends CustomPainter {
  final List<_LayoutEdge> layoutEdges;
  final Map<String, Offset> nodePositions;
  final bool simplified;
  final double magicProgress;
  final Map<String, String> memberNames;

  _DebtGraphPainter({
    required this.layoutEdges,
    required this.nodePositions,
    required this.simplified,
    required this.magicProgress,
    required this.memberNames,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final layout in layoutEdges) {
      _paintEdge(canvas, layout);
    }
  }

  void _paintEdge(Canvas canvas, _LayoutEdge layout) {
    final edge = layout.edge.transfer;
    final from = nodePositions[edge.fromUserId];
    final to = nodePositions[edge.toUserId];
    if (from == null || to == null) return;

    final angle = math.atan2(to.dy - from.dy, to.dx - from.dx);
    const nodeRadius = 30.0;
    final unit = Offset(math.cos(angle), math.sin(angle));
    var perpendicular = Offset(-unit.dy, unit.dx);

    if (layout.reverseDirection) {
      perpendicular = Offset(-perpendicular.dx, -perpendicular.dy);
    }

    final laneSpacing = simplified ? 24.0 : 14.0;
    final laneOffset = (layout.laneIndex - (layout.laneCount - 1) / 2) * laneSpacing;
    final curveStrength = simplified ? 0.55 : 0.35;

    final start = from + unit * nodeRadius + perpendicular * laneOffset;
    final end = to - unit * nodeRadius + perpendicular * laneOffset;

    final path = Path()..moveTo(start.dx, start.dy);
    final control = Offset(
      (start.dx + end.dx) / 2 + perpendicular.dx * laneOffset * curveStrength,
      (start.dy + end.dy) / 2 + perpendicular.dy * laneOffset * curveStrength,
    );
    path.quadraticBezierTo(control.dx, control.dy, end.dx, end.dy);

    final baseColor = simplified ? AppColors.success : AppColors.owed;
    final strokeWidth = simplified ? 3.2 : 1.6;
    final opacity = simplified ? 0.55 + magicProgress * 0.4 : 0.35;

    if (simplified && magicProgress > 0) {
      final glowPaint = Paint()
        ..color = baseColor.withValues(alpha: 0.18 * magicProgress)
        ..strokeWidth = strokeWidth + 6
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawPath(path, glowPaint);
    }

    final linePaint = Paint()
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    if (simplified) {
      linePaint.shader = ui.Gradient.linear(
        start,
        end,
        [
          AppColors.owed.withValues(alpha: opacity),
          baseColor.withValues(alpha: opacity),
        ],
      );
    } else {
      linePaint.color = baseColor.withValues(alpha: opacity);
    }

    canvas.drawPath(path, linePaint);
    _drawArrowHead(canvas, end, control, linePaint.color.withValues(alpha: opacity));

    if (simplified) {
      final badgePoint = _quadraticPoint(start, control, end, 0.5);
      _drawAmountBadge(canvas, badgePoint, edge.amount, baseColor);
    }
  }

  Offset _quadraticPoint(Offset start, Offset control, Offset end, double t) {
    final x = (1 - t) * (1 - t) * start.dx + 2 * (1 - t) * t * control.dx + t * t * end.dx;
    final y = (1 - t) * (1 - t) * start.dy + 2 * (1 - t) * t * control.dy + t * t * end.dy;
    return Offset(x, y);
  }

  void _drawArrowHead(Canvas canvas, Offset end, Offset from, Color color) {
    final angle = math.atan2(end.dy - from.dy, end.dx - from.dx);
    const arrowSize = 9.0;
    final path = Path()
      ..moveTo(end.dx, end.dy)
      ..lineTo(
        end.dx - arrowSize * math.cos(angle - math.pi / 6),
        end.dy - arrowSize * math.sin(angle - math.pi / 6),
      )
      ..lineTo(
        end.dx - arrowSize * math.cos(angle + math.pi / 6),
        end.dy - arrowSize * math.sin(angle + math.pi / 6),
      )
      ..close();

    canvas.drawPath(path, Paint()..color = color);
  }

  void _drawAmountBadge(Canvas canvas, Offset center, double amount, Color color) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: '₹${amount.toStringAsFixed(amount % 1 == 0 ? 0 : 2)}',
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final rect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: center,
        width: textPainter.width + 18,
        height: textPainter.height + 10,
      ),
      const Radius.circular(12),
    );

    canvas.drawRRect(rect, Paint()..color = Colors.white);
    canvas.drawRRect(
      rect,
      Paint()
        ..color = color.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    textPainter.paint(
      canvas,
      Offset(center.dx - textPainter.width / 2, center.dy - textPainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant _DebtGraphPainter oldDelegate) {
    return oldDelegate.layoutEdges != layoutEdges ||
        oldDelegate.nodePositions != nodePositions ||
        oldDelegate.simplified != simplified ||
        oldDelegate.magicProgress != magicProgress;
  }
}
