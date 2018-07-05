Pod::Spec.new do |s|

  s.name         = "RTDatabase"
  s.version      = "0.1.0"
  s.summary      = "A Library for iOS to use for sqlite"
  s.homepage     = "https://github.com/FuihuiC"
  s.author       = { "ENUUI" => "ENUUI_C@163.com" }

  s.source       = { :git => "https://github.com/FuihuiC/RTDB.git", :tag => "#{s.version}" }

  s.requires_arc = true

  s.ios.deployment_target = '8.2'
  s.osx.deployment_target = '10.10'
  s.tvos.deployment_target = '9.0'
  
  s.license = "MIT"

  s.public_header_files = 'RTDatabase/RTDatabase.h'
  s.source_files = 'RTDatabase/RTDatabase.h'

  s.subspec 'RTDB' do |ss|
    ss.ios.deployment_target = '8.2'
    ss.source_files        = 'RTDatabase/core/RTD*.{h,m}', 'RTDatabase/core/RTPreset.{h}', 'RTDatabase/core/RTTools.{m}', 'RTDatabase/core/RTNext.{h,m}', 'RTDatabase/core/RTInfo.{h,m}'
    ss.public_header_files = 'RTDatabase/core/RTD*.{h}', 'RTDatabase/core/RTPreset.{h}', 'RTDatabase/core/RTNext.{h}', 'RTDatabase/core/RTInfo.{h}'
  end

  s.subspec 'RTSDB' do |ss|
    ss.dependency 'RTDatabase/RTDB'
    ss.source_files        = 'RTDatabase/core/RTS*.{h,m}'
    ss.public_header_files = 'RTDatabase/core/RTS*.{h}'
  end

  s.subspec 'PPSQL' do |ss| 
    ss.source_files         = 'RTDatabase/core/PP*.{h,m}'
    ss.public_header_files  = 'RTDatabase/core/PP*.{h}'
  end
end
