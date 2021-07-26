#
# Be sure to run `pod lib lint ASNetworkImageNode-Extension.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'ASNetworkImageNode-Extension'
  s.version          = '0.1.0'
  s.summary          = 'A short description of ASNetworkImageNode-Extension.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC

  s.homepage         = 'https://github.com/arcangelw/ASNetworkImageNode-Extension'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'arcangelw' => 'wuzhezmc@gmail.com' }
  s.source           = { :git => 'https://github.com/arcangelw/ASNetworkImageNode-Extension.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '9.0'
  s.requires_arc = true

  s.dependency 'Texture/Core'

  # Subspecs
  s.subspec 'SDWebImage' do |pin|
      pin.source_files = "Source/SDWebImage/**"
      pin.public_header_files = "Source/SDWebImage/**/*.h"
      pin.dependency 'SDWebImage/Core'
  end

  s.subspec 'YYWebImage' do |pin|
      pin.source_files = "Source/YYWebImage/**"
      pin.public_header_files = "Source/YYWebImage/**/*.h"
      pin.dependency 'YYWebImage'
  end
end
