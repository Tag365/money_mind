import 'package:flutter/material.dart';

/// One row of the details sheet: icon, small [label], and [value] below it.
/// With [onTap] it shows a chevron and can be tapped.
class InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget value;
  final VoidCallback? onTap;

  const InfoTile(this.icon, this.label, this.value, {super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      onTap: onTap,
      trailing: onTap == null ? null : const Icon(Icons.chevron_right),
      leading: Icon(icon),
      title: Text(label, style: textTheme.labelMedium),
      subtitle: DefaultTextStyle.merge(
        style: textTheme.bodyLarge,
        child: value,
      ),
    );
  }
}
