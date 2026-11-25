import 'package:flutter/material.dart';
import 'package:picnic_lib/core/analytics/shortform_playback_consent.dart';

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
    if (oldWidget.ownerUserId != widget.ownerUserId) {
      _ready = false;
      _allowed = false;
      _failed = false;
      _load();
    }
  }

  Future<void> _load() async {
    final owner = widget.ownerUserId;
    await _consent.load(owner);
    if (!mounted || owner != widget.ownerUserId) return;
    setState(() {
      _ready = true;
      _allowed = _consent.isAllowed(owner);
    });
  }

  Future<void> _change(bool allowed) async {
    final owner = widget.ownerUserId;
    setState(() {
      _saving = true;
      _failed = false;
    });
    final saved = await _consent.setAllowed(owner, allowed);
    if (!mounted || owner != widget.ownerUserId) return;
    setState(() {
      _saving = false;
      _allowed = _consent.isAllowed(owner);
      _failed = !saved;
    });
  }

  @override
  Widget build(BuildContext context) {
    final ko = Localizations.localeOf(context).languageCode == 'ko';
    return SwitchListTile(
      key: const Key('shortform-playback-consent'),
      contentPadding: const EdgeInsets.symmetric(vertical: 12),
      title: Text(
        ko ? '숏폼 시청 분석 (선택)' : 'Shortform viewing analysis (optional)',
      ),
      subtitle: Text(
        '${ko ? 'PICNIC 내부 숏폼 광고의 노출 정보와 실제 재생 시간을 계정에 연결하여 아티스트·팬덤·지역별 시청 통계에 사용합니다. 이 기기의 현재 계정에만 적용합니다. 끄면 이후 수집을 중단합니다. 광고 보상에는 영향을 주지 않습니다.' : 'PICNIC links internal shortform ad impressions and actual playback time to your account for artist, fandom and regional viewing statistics. This choice applies to this account on this device. Turning it off stops future collection. Ad rewards are unaffected.'}'
        '${_failed ? (ko ? '\n설정을 저장하지 못했습니다. 분석을 사용하지 않습니다.' : '\nCould not save the setting. Analysis stays off.') : ''}',
      ),
      value: _allowed,
      onChanged: _ready && !_saving && widget.ownerUserId.isNotEmpty
          ? _change
          : null,
    );
  }
}
