source 'https://github.com/CocoaPods/Specs.git'
workspace 'RudderBranch.xcworkspace'
use_frameworks!
inhibit_all_warnings!
platform :ios, '13.0'

def shared_pods
    pod 'Rudder', '~> 2.0.1'
end

target 'RudderBranch' do
    project 'RudderBranch.xcodeproj'
    shared_pods
    pod 'Branch', '~> 1.41.0'
end

target 'SampleAppObjC' do
    project 'Examples/SampleAppObjC/SampleAppObjC.xcodeproj'
    shared_pods
    pod 'RudderBranch', :path => '.'
end

target 'SampleAppSwift' do
    project 'Examples/SampleAppSwift/SampleAppSwift.xcodeproj'
    shared_pods
    pod 'RudderBranch', :path => '.'
end
