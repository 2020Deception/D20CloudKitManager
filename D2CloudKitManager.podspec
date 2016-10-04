Pod::Spec.new do |s|
  s.name             = 'D2CloudKitManager'
  s.version          = '0.1.0'
  s.summary          = 'A wrapper on top of CloudKit to make your life a little easier when integrated with the greatest cloud system in the world.'

  s.description      = <<-DESC
This pop is essentially a wrapper to use on top of CloudKit for your service call needs. If you are familiar with CloudKit, using this should be straight forward.
                       DESC

  s.homepage         = 'https://github.com/2020Deception/D2CloudKitManager'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { '2020Deception' => '2020Deception@gmail.com' }
  s.source           = { :git => 'https://github.com/2020Deception/D2CloudKitManager.git', :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/Decepticon2020'

  s.ios.deployment_target = '10.0'

  s.source_files = 'D2CloudKitManager/Classes/**/*'

  s.public_header_files = 'D2CloudKitManager/Classes/**/*.h'
  s.frameworks = 'UIKit', 'Foundation', 'CloudKit'
end
