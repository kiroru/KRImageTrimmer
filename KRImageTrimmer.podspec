#
# Be sure to run `pod lib lint KRImageTrimmer.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'KRImageTrimmer'
  s.version          = '1.0.0'
  s.summary          = 'Simple screen to crop the image to a square.'

  s.description      = <<-DESC
Simple screen to crop the image to a square. You can enlarge, reduce and move.
                       DESC

  s.homepage         = 'https://github.com/kiroru/KRImageTrimmer'
  # s.screenshots     = 'www.example.com/screenshots_1'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'takeguchi' => 'takeguchi@kiroru-inc.jp' }
  s.source           = { :git => 'https://github.com/kiroru/KRImageTrimmer.git', :tag => s.version.to_s }
  s.swift_version    = '4.2'

  s.ios.deployment_target = '9.0'

  s.source_files = 'KRImageTrimmer/Classes/**/*.swift'
  
  s.resource_bundles = {
    'KRImageTrimmer' => ['KRImageTrimmer/Assets/**/*.xib']
  }

  s.frameworks = 'UIKit', 'CoreGraphics'
end
