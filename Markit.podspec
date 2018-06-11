#
# Be sure to run `pod lib lint Markit.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'Markit'
  s.version          = '0.1.0'
  s.summary          = 'Build Objective-C objects (views, menus, etc.) with XML'

  s.homepage         = 'https://github.com/patr0nus/Markit'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'patr0nus' => 'dk4rest@gmail.com' }

  s.swift_version = "4.2"

  s.source           = { :git => 'https://github.com/patr0nus/Markit.git', :tag => s.version.to_s }

  s.osx.deployment_target = "10.11"

  s.source_files = 'Source/**/*'
  
  s.frameworks = 'Cocoa'
end
