import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_format.dart';

class SimplifiedTransferTile extends StatelessWidget {
  final String debtorName;
  final String creditorName;
  final double amount;
  final bool isDebtor;
  final bool isCreditor;
  final VoidCallback? onSettleUp;

  const SimplifiedTransferTile({
    super.key,
    required this.debtorName,
    required this.creditorName,
    required this.amount,
    required this.isDebtor,
    required this.isCreditor,
    this.onSettleUp,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.swap_horiz, size: 18, color: AppColors.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  debtorName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  'pays $creditorName',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.2,
                      ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    TransferAmountBadge(amount: amount),
                    const Spacer(),
                    _buildAction(context),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAction(BuildContext context) {
    if (isDebtor) {
      return TextButton(
        onPressed: onSettleUp,
        style: TextButton.styleFrom(
          visualDensity: VisualDensity.compact,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: const Text('Settle Up'),
      );
    }

    if (isCreditor) {
      return ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 96),
        child: Text(
          'Awaiting payment',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.end,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}

class TransferAmountBadge extends StatelessWidget {
  final double amount;
  final Color color;

  const TransferAmountBadge({
    super.key,
    required this.amount,
    this.color = AppColors.owed,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(
        maxWidth: 84,
        maxHeight: 28,
        minWidth: 44,
      ),
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            formatCurrencyAmount(amount, compact: true),
            maxLines: 1,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 11,
              height: 1.1,
            ),
          ),
        ),
      ),
    );
  }
}
