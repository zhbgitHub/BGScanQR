
Pod::Spec.new do |s|
  s.name             = 'BGScanQR'
  s.version          = '0.1.0'
  s.summary          = 'A short description of BGScanQR.'
  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC

  s.homepage         = 'https://github.com/zhbgitHub/BGScanQR'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'zhb_mymail@163.com' => 'zhb_mymail@163.com' }
  s.source           = { :git => 'https://github.com/zhbgitHub/BGScanQR.git', :tag => s.version.to_s }

  s.ios.deployment_target = '8.0'

  s.source_files = 'BGScanQR/Classes/**/*'
  
  # s.resource_bundles = {
  #   'BGScanQR' => ['BGScanQR/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
end
