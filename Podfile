# Uncomment the next line to define a global platform for your project
 platform :ios, '17.0'

target 'VinylApp' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

pod 'Firebase/Core'
pod 'Firebase/Storage'
pod 'Firebase/Analytics'
pod 'SDWebImage'
pod 'Firebase/Firestore'
pod 'Firebase/Auth'
pod 'TOCropViewController'

post_install do |installer|
     installer.generated_projects.each do |project|
           project.targets.each do |target|
               target.build_configurations.each do |config|
                   config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '17.0'
                end
           end
    end
 end

end
