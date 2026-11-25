import 'dart:async';

import 'package:flutter/material.dart';
import 'package:picnic_lib/core/analytics/shortform_playback_consent.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';

/// Discoverable per-account, per-device opt-in. No ad or reward UI grants it.
class ShortformPlaybackConsentTile extends StatefulWidget {
  const ShortformPlaybackConsentTile({
    super.key,
    required this.ownerUserId,
    this.consent,
  });
  final String ownerUserId;
  final ShortformPlaybackConsent? consent;

  @override
  State<ShortformPlaybackConsentTile> createState() => _ConsentTileState();
}

class _ConsentTileState extends State<ShortformPlaybackConsentTile> {
  bool _ready = false;
  bool _saving = false;
  bool _allowed = false;
  bool _failed = false;
  int _generation = 0;
  Timer? _expiryTimer;
  ShortformPlaybackConsent get _consent =>
      widget.consent ?? ShortformPlaybackConsent.instance;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(ShortformPlaybackConsentTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.ownerUserId != widget.ownerUserId ||
        oldWidget.consent != widget.consent) {
      _generation++;
      _expiryTimer?.cancel();
      _ready = false;
      _saving = false;
      _allowed = false;
      _failed = false;
      _load();
    }
  }

  Future<void> _load() async {
    final owner = widget.ownerUserId;
    final generation = _generation;
    await _consent.load(owner);
    if (!mounted || generation != _generation) return;
    setState(() {
      _ready = true;
      _allowed = _consent.isAllowed(owner);
    });
    _scheduleExpiry(owner);
  }

  Future<void> _change(bool allowed) async {
    final owner = widget.ownerUserId;
    final generation = ++_generation;
    setState(() {
      _saving = true;
      _failed = false;
    });
    final saved = await _consent.setAllowed(owner, allowed);
    if (!mounted || generation != _generation) return;
    setState(() {
      _saving = false;
      _allowed = _consent.isAllowed(owner);
      _failed = !saved;
    });
    _scheduleExpiry(owner);
  }

  void _scheduleExpiry(String owner) {
    _expiryTimer?.cancel();
    if (_allowed) _expiryTimer = Timer(_consent.remaining(owner), _load);
  }

  @override
  void dispose() {
    _expiryTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SwitchListTile(
      key: const Key('shortform-playback-consent'),
      contentPadding: const EdgeInsets.symmetric(vertical: 12),
      title: Text(l10n.shortform_playback_consent_title),
      subtitle: Text(
        '${l10n.shortform_playback_consent_description}'
        '${_failed ? '\n${l10n.shortform_playback_consent_error}' : ''}',
      ),
      value: _allowed,
      onChanged: _ready && !_saving && widget.ownerUserId.isNotEmpty
          ? _change
          : null,
    );
  }
}
