Pod::Spec.new do |s|

  s.name         = "RTDatabase"
  s.version      = "0.1.0"
  s.summary      = "A Library for iOS to use for sqlite"
  s.homepage     = "https://github.com/FuihuiC"
  s.author       = { "ENUUI" => "ENUUI_C@163.com" }

  s.source       = { :git => "https://github.com/FuihuiC/RTDB.git", :tag => "#{s.version}" }

  s.requires_arc = true
  s.platform     = :ios
  s.ios.deployment_target = '8.2'
  
  s.license = "MIT"

  s.public_header_files = 'RTDatabase/RTDatabase.h'
  s.source_files = 'RTDatabase/RTDatabase.h'

  s.subspec 'RTDB' do |ss|
    ss.ios.deployment_target = '8.2'
    ss.source_files        = 'RTDatabase/core/RT*.{h,m}'
    ss.public_header_files = 'RTDatabase/core/RT*.{h}'
  end 

  s.subspec 'PPSQL' do |ss| 
    ss.source_files         = 'RTDatabase/core/PP*.{h,m}'
    ss.public_header_files  = 'RTDatabase/core/PP*.{h}'
  end
end
