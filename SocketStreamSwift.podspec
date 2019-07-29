#
# Be sure to run `pod lib lint SocketStreamSwift.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
        s.name             = 'SocketStreamSwift'
        s.version          = '0.3.3'
        s.summary          = 'It is a library to conduct chat.'
        s.description      = <<-DESC
        TODO: Add long description of the pod here.
        DESC
        s.homepage         = 'https://github.com/daisukenagata/SocketStreamSwift'
        s.license          = { :type => 'MIT', :file => 'LICENSE' }
        s.author           = { 'daisukenagata' => 'dbank0208@gmail.com' }
        s.source           = { :git => 'https://github.com/daisukenagata/SocketStreamSwift.git', :tag => s.version.to_s }
        s.ios.deployment_target = '11.0'
        s.swift_version = '5.0'
        s.source_files = 'SocketStreamSwift/Classes/**/*'
    end
