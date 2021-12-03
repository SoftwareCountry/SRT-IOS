Pod::Spec.new do |spec|

  spec.name         = "SRT-IOS"
  spec.version      = "0.0.1"
  spec.summary      = "Compiled SRT library for mobile apps."
  spec.homepage     = "https://www.srtalliance.org"

  spec.license      = { :type => "MPL20", :file => "LICENSE" }

  spec.author             = { "Alexander Sokolov" => "alexander.sokolov@arcadia.spb.ru" }

  spec.platform     = :ios
  spec.ios.deployment_target = "13.0"

  spec.source       = { :git => "https://github.com/SoftwareCountry/SRT-IOS.git", :tag => "#{spec.version}" }

  spec.ios.vendored_frameworks = "SRT-IOS/Frameworks/libsrt.xcframework"

  spec.xcconfig = { "EXCLUDED_ARCHS[sdk=iphonesimulator*]" => "arm64" }
end
