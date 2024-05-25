import 'package:flutter/material.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:picnic_app/constants.dart';

OverlaySupportEntry? blackScreenOverlaySupport;
OverlaySupportEntry? lockScreenOverlaySupport;
OverlaySupportEntry? onlyAdultOverlay;
Color blackScreenColor = voteMainColor;
DateTime? lastAuthenticationTime;

void clearLockScreenOverlay() {
  lockScreenOverlaySupport?.dismiss(animate: false);
  lockScreenOverlaySupport = null;
}

void clearBlackScreenOverlay() {
  blackScreenOverlaySupport?.dismiss(animate: false);
  blackScreenOverlaySupport = null;
}

void clearOnlyAdultOverlay() {
  onlyAdultOverlay?.dismiss(animate: false);
  onlyAdultOverlay = null;
}

void clearAllOverlay() {
  clearLockScreenOverlay();
  clearBlackScreenOverlay();
  clearOnlyAdultOverlay();
}
