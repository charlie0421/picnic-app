import 'package:flutter/material.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:prame_app/constants.dart';

OverlaySupportEntry? blackScreenOverlaySupport;
OverlaySupportEntry? lockScreenOverlaySupport;
OverlaySupportEntry? onlyAdultOverlay;
Color blackScreenColor = Constants.fanMainColor;
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
