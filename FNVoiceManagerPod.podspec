#
# Be sure to run `pod lib lint FNVoiceManagerPod.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
s.name             = 'FNVoiceManagerPod'
s.version          = '0.1.0'
s.summary          = 'A short description of FNVoiceManagerPod.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

s.description      = <<-DESC
TODO: Add long description of the pod here.
DESC

s.homepage         = 'www.feiniu.com'
# s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
s.license          = { :type => 'MIT', :file => 'LICENSE' }
s.author           = { 'JR' => 'jiaruijj@163.com' }
s.source           = {:git => 'https://github.com/jiaruijj/VoiceManager.git'}
# s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

s.ios.deployment_target = '8.0'

s.source_files = 'FNVoiceManagerPod/Classes/**/*.{h,m,mm}'

s.resources = ["FNVoiceManagerPod/Classes/**/*.{a,arm64,armv7,armv7s,i386,x86_84,la,pc}"]

s.dependency 'FMDB'

#s.frameworks = 'AVFoundation'

s.libraries = 'opencore-amrnb','opencore-amrwb'

# s.resource_bundles = {
#   'FNVoiceManagerPod' => ['FNVoiceManagerPod/Assets/*.png']
# }

# s.public_header_files = 'Pod/Classes/**/*.h'
# s.frameworks = 'UIKit', 'MapKit'
# s.dependency 'AFNetworking', '~> 2.3'
end
