// Yangilanish UI: to'liq ekran ogohlantirish (MaterialApp.builder) va
// sozlamalar panelidagi «Yangilanish» bo'limi.
//
// ⚠️ `_kiosk_update_kit` dan nusxalanadi — 5 kiosk repoda bir xil.
import 'package:flutter/material.dart';

import 'kiosk_updater.dart';

/// `MaterialApp(builder: (context, child) => KioskUpdateOverlay(child: child!))`
///
/// - har teginishni faoliyat deb belgilaydi (bo'shlik hisobi);
/// - ogohlantirish va «Yangilanmoqda…» ekranini hamma narsaning ustida
///   ko'rsatadi (dialoglar ham ostida qoladi).
class KioskUpdateOverlay extends StatelessWidget {
  const KioskUpdateOverlay({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final u = KioskUpdater.instance;
    if (u == null) return child;
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => u.markActivity(),
      child: Stack(
        fit: StackFit.expand,
        children: [
          child,
          ListenableBuilder(
            listenable: u,
            builder: (context, _) {
              if (u.phase != UpdatePhase.warning &&
                  u.phase != UpdatePhase.installing) {
                return const SizedBox.shrink();
              }
              return _UpdateScreen(u: u);
            },
          ),
        ],
      ),
    );
  }
}

class _UpdateScreen extends StatelessWidget {
  const _UpdateScreen({required this.u});

  final KioskUpdater u;

  @override
  Widget build(BuildContext context) {
    final installing = u.phase == UpdatePhase.installing;
    final v = u.remote?.version ?? '';
    const white = Colors.white;
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Material(
        color: const Color(0xF20B1A2E),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              // kichik ekranda ham sig'sin (masalan 1024×600 monitor)
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (installing)
                      const SizedBox(
                        width: 64,
                        height: 64,
                        child: CircularProgressIndicator(
                            strokeWidth: 5, color: white),
                      )
                    else
                      Text(
                        '${u.warningSecondsLeft}',
                        style: const TextStyle(
                            fontSize: 96,
                            fontWeight: FontWeight.w700,
                            color: white,
                            height: 1),
                      ),
                    const SizedBox(height: 28),
                    Text(
                      installing
                          ? 'Yangilanmoqda…'
                          : 'Ilova yangilanadi${v.isEmpty ? '' : ' — v$v'}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w700,
                          color: white),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Yangilanish tugaguncha ekran bir necha daqiqa qora '
                      'bo\'lishi mumkin — kompyuterni o\'chirmang.\n'
                      'Agar 5 daqiqadan keyin ham ilova ochilmasa, qurilmani '
                      'o\'chirib yoqing — yangilanish joriy bo\'ladi.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 20, color: white, height: 1.4),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Идёт обновление. Экран может быть чёрным несколько '
                      'минут — не выключайте компьютер. Если через 5 минут '
                      'приложение не откроется, перезагрузите устройство.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 16, color: Colors.white70, height: 1.4),
                    ),
                    if (!installing) ...[
                      const SizedBox(height: 28),
                      if (u.warningManual)
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: white,
                            side: const BorderSide(color: Colors.white54),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 28, vertical: 16),
                          ),
                          onPressed: u.cancelWarning,
                          child: const Text('Bekor qilish',
                              style: TextStyle(fontSize: 18)),
                        )
                      else
                        const Text(
                          'Ekranga teginsangiz, yangilanish keyinroqqa '
                          'qoldiriladi.',
                          style:
                              TextStyle(fontSize: 16, color: Colors.white60),
                        ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Sozlamalar / admin panelidagi «Yangilanish» bo'limi (parolsiz).
class KioskUpdatePanel extends StatelessWidget {
  const KioskUpdatePanel({super.key});

  @override
  Widget build(BuildContext context) {
    final u = KioskUpdater.instance;
    if (u == null) return const SizedBox.shrink();
    return ListenableBuilder(
      listenable: u,
      builder: (context, _) => _panel(context, u),
    );
  }

  Widget _panel(BuildContext context, KioskUpdater u) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final remote = u.remote;
    final canInstall = KioskUpdater.supported &&
        !u.busy &&
        (u.phase == UpdatePhase.ready ||
            u.phase == UpdatePhase.available ||
            (u.phase == UpdatePhase.failed && u.hasUpdate));

    Widget row(String k, String v, {Color? color}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 170,
                child: Text(k,
                    style: TextStyle(color: cs.onSurfaceVariant, fontSize: 15)),
              ),
              Expanded(
                child: Text(v,
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: color ?? cs.onSurface)),
              ),
            ],
          ),
        );

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.system_update_alt, color: cs.primary),
              const SizedBox(width: 10),
              Text('Yangilanish',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 12),
          row('Joriy versiya', u.currentVersion.isEmpty ? '—' : u.currentVersion),
          row('Serverdagi versiya',
              remote == null ? '—' : remote.version + (u.mandatory ? ' (majburiy)' : '')),
          row('Holat', _phaseText(u),
              color: u.phase == UpdatePhase.failed ? cs.error : null),
          row('Oxirgi tekshiruv', _fmt(u.lastCheck)),
          if (u.lastError != null)
            row('Xato', u.lastError!, color: cs.error),
          if (u.phase == UpdatePhase.downloading) ...[
            const SizedBox(height: 8),
            LinearProgressIndicator(value: u.progress > 0 ? u.progress : null),
          ],
          if (remote != null &&
              u.hasUpdate &&
              remote.changelog.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(remote.changelog,
                style: TextStyle(color: cs.onSurfaceVariant, fontSize: 14)),
          ],
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton.tonalIcon(
                onPressed: KioskUpdater.supported && !u.busy
                    ? () => u.checkNow(manual: true)
                    : null,
                icon: const Icon(Icons.refresh),
                label: const Text('Hozir tekshirish'),
              ),
              FilledButton.icon(
                onPressed: canInstall ? u.installNow : null,
                icon: const Icon(Icons.download_done),
                label: const Text('Hozir o\'rnatish'),
              ),
              TextButton.icon(
                onPressed: () => _showLog(context, u),
                icon: const Icon(Icons.article_outlined),
                label: const Text('Log'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _phaseText(KioskUpdater u) {
    switch (u.phase) {
      case UpdatePhase.idle:
        return 'Hali tekshirilmagan';
      case UpdatePhase.checking:
        return 'Tekshirilmoqda…';
      case UpdatePhase.upToDate:
        return 'Eng so\'nggi versiya';
      case UpdatePhase.available:
        return 'Yangi versiya bor';
      case UpdatePhase.downloading:
        return 'Yuklanmoqda… ${(u.progress * 100).toStringAsFixed(0)}%';
      case UpdatePhase.ready:
        return 'Yuklandi — ilova bo\'sh turganda o\'rnatiladi';
      case UpdatePhase.warning:
        return 'O\'rnatishga ${u.warningSecondsLeft} s';
      case UpdatePhase.installing:
        return 'O\'rnatilmoqda…';
      case UpdatePhase.failed:
        return 'Xato';
      case UpdatePhase.unsupported:
        return 'Faqat Windows release build\'da ishlaydi';
    }
  }

  static String _fmt(DateTime? t) {
    if (t == null) return '—';
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(t.day)}.${two(t.month)}.${t.year} ${two(t.hour)}:${two(t.minute)}';
  }

  static Future<void> _showLog(BuildContext context, KioskUpdater u) {
    final lines = u.readLog();
    return showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Yangilanish logi'),
        content: SizedBox(
          width: 720,
          height: 420,
          child: lines.isEmpty
              ? const Center(child: Text('Log bo\'sh'))
              : SingleChildScrollView(
                  reverse: true,
                  child: SelectableText(lines.join('\n'),
                      style: const TextStyle(
                          fontFamily: 'Consolas', fontSize: 12)),
                ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Yopish')),
        ],
      ),
    );
  }
}
