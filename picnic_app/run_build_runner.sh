#!/bin/bash

# Set Dart VM options
export DART_VM_OPTIONS="-j 12"

# Run build_runner
dart run build_runner watch --delete-conflicting-outputs