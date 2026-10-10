void main(List<String> args) {
  print('====================================================');
  print('               AndroMac Monorepo Root               ');
  print('====================================================');
  print('');
  print('AndroMac is organized as a multi-package monorepo workspace:');
  print('  • macOS Desktop App: apps/desktop');
  print('  • Android Phone App: apps/phone');
  print('');
  print('To build or run applications:');
  print('  macOS:');
  print('    cd apps/desktop && flutter run -d macos');
  print('    cd apps/desktop && flutter build macos --release');
  print('    or: make build-mac');
  print('    or: ./scripts/build_macos.sh');
  print('');
  print('  Android:');
  print('    cd apps/phone && flutter run -d android');
  print('    cd apps/phone && flutter build apk --flavor direct --release');
  print('    or: make build-android');
  print('    or: ./scripts/build_android.sh');
  print('====================================================');
}
