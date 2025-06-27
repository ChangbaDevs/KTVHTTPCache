Pod::Spec.new do |s|
  s.name                = "KTVHTTPCache"
  s.version             = "3.1.0"
  s.summary             = "A powerful media cache framework."
  s.homepage            = "https://github.com/ChangbaDevs/KTVHTTPCache"
  s.license             = { :type => "MIT", :file => "LICENSE" }
  s.author              = { "Single" => "libobjc@gmail.com" }
  s.social_media_url    = "https://weibo.com/3118550737"
  s.platform            = :ios, "12.0"
  s.source              = { :git => "https://github.com/ChangbaDevs/KTVHTTPCache.git", :tag => "#{s.version}" }
  s.source_files        = "KTVHTTPCache", "KTVHTTPCache/**/*.{h,m}"
  s.public_header_files =
                          "KTVHTTPCache/KTVHTTPCache.h",
                          "KTVHTTPCache/Classes/KTVHCCommon/KTVHCError.h",
                          "KTVHTTPCache/Classes/KTVHCCommon/KTVHCRange.h",
                          "KTVHTTPCache/Classes/KTVHCDataStorage/KTVHCDataReader.h",
                          "KTVHTTPCache/Classes/KTVHCDataStorage/KTVHCDataLoader.h",
                          "KTVHTTPCache/Classes/KTVHCDataStorage/KTVHCDataHLSLoader.h",
                          "KTVHTTPCache/Classes/KTVHCDataStorage/KTVHCDataRequest.h",
                          "KTVHTTPCache/Classes/KTVHCDataStorage/KTVHCDataResponse.h",
                          "KTVHTTPCache/Classes/KTVHCDataStorage/KTVHCDataCacheItem.h",
                          "KTVHTTPCache/Classes/KTVHCDataStorage/KTVHCDataCacheItemZone.h"
  s.frameworks          = "UIKit", "Foundation"
  s.requires_arc        = true
  s.dependency 'CocoaAsyncSocket'
end
