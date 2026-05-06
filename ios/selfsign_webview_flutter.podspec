Pod::Spec.new do |s|
  s.name             = 'selfsign_webview_flutter'
  s.version          = '0.1.0'
  s.summary          = 'A hardened WebView for e-signature pages on iOS and Android.'
  s.description      = <<-DESC
A Flutter plugin that wraps WKWebView (iOS) / WebView (Android) with file
and camera upload, permission handling, SSL dialog, JS bridge callbacks
and back-press confirmation, suitable for hosting e-signature webpages.
                       DESC
  s.homepage         = 'https://example.com/selfsign_webview_flutter'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'selfsign_webview_flutter' => 'noreply@example.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '12.0'

  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386'
  }
  s.swift_version = '5.0'
end
