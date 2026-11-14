#!/usr/bin/env bash
# Ejecutar dentro de app/ después de `flutter create . --platforms=android,ios`
set -e
M=android/app/src/main/AndroidManifest.xml
PERMS='<uses-permission android:name="android.permission.INTERNET"/>\n<uses-permission android:name="android.permission.RECORD_AUDIO"/>\n<uses-permission android:name="android.permission.CAMERA"/>\n<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>\n<uses-permission android:name="android.permission.BLUETOOTH_SCAN"/>\n<uses-permission android:name="android.permission.BLUETOOTH_ADVERTISE"/>\n<uses-permission android:name="android.permission.BLUETOOTH_CONNECT"/>'
grep -q RECORD_AUDIO "$M" || sed -i "s#<application#$PERMS\n<application#" "$M"
# `record` exige minSdk 23
sed -i 's/minSdk = flutter.minSdkVersion/minSdk = 23/; s/minSdkVersion flutter.minSdkVersion/minSdkVersion 23/' android/app/build.gradle* || true
