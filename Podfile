source 'https://github.com/CocoaPods/Specs.git'
workspace 'RudderBranch.xcworkspace'
use_frameworks!
inhibit_all_warnings!
platform :ios, '13.0'

target 'RudderBranch' do
    project 'RudderBranch.xcodeproj'
    pod 'Rudder', '~> 2.0'
    pod 'BranchSDK', '~> 3.4.4'
   
end

target 'SampleAppObjC' do
    project 'Examples/SampleAppObjC/SampleAppObjC.xcodeproj'
    pod 'RudderBranch', :path => '.'
end

target 'SampleAppSwift' do
    project 'Examples/SampleAppSwift/SampleAppSwift.xcodeproj'
    pod 'RudderBranch', :path => '.'
end
