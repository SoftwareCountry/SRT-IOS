Pod::Spec.new do |spec|

  spec.name         = "SRT-IOS-XCFramework"
  spec.version      = "1.4.4"
  spec.summary      = "Compiled SRT library for mobile apps."
  spec.homepage     = "https://www.srtalliance.org"

  spec.license      = { :type => "MPL20", :file => "LICENSE" }

  spec.author             = { "Alexander Sokolov" => "alexander.sokolov@arcadia.spb.ru" }

  spec.platform     = :ios
  spec.ios.deployment_target = "13.0"

  spec.source       = { :git => "https://github.com/SoftwareCountry/SRT-IOS.git", :tag => "#{spec.version}" }

  spec.ios.vendored_frameworks = "SRT-IOS/XCFrameworks/libsrt.xcframework"
  spec.preserve_paths = "SRT-IOS/XCFrameworks/libsrt.xcframework"

  spec.requires_arc = true

  spec.pod_target_xcconfig = {
    "EXCLUDED_ARCHS[sdk=iphonesimulator*]" => "arm64 armv7 i386",
    "EXCLUDED_ARCHS[sdk=iphoneos*]" => "x86_64 armv7 i386"
  }
end
