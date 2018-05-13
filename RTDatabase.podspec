Pod::Spec.new do |s|

  s.name         = "RTDatabase"
  s.version      = "0.0.1"
  s.summary      = "A Library for iOS to use for sqlite"
  s.homepage     = "https://github.com/FuihuiC"
  s.author             = { "ENUUI" => "ENUUI_C@163.com" }

  s.source       = { :git => "https://github.com/FuihuiC/RTDB.git", :tag => "#{s.version}" }

  s.requires_arc = true
  s.platform     = :ios
  s.ios.deployment_target = '8.2'
  
  s.license = "MIT"

  s.source_files        = 'RTDatabase/RTDatabase.h', 'RTDatabase/core/*.{h,m}'
  s.public_header_files = 'RTDatabase/RTDatabase.h', 'RTDatabase/core/*.{h}'
end
