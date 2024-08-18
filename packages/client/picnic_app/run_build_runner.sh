#!/bin/bash

# Set Dart VM options
export DART_VM_OPTIONS="-j 12"

# Run build_runner
flutter pub run build_runner watch --delete-conflicting-outputs