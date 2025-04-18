// Copyright 2022 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
#import <UIKit/UIKit.h>
#import "GADMediationAdapterMintegral.h"

#define GADMediationAdapterMintegralLog(format, args...) \
  NSLog(@"GADMediationAdapterMintegral: " format, ##args)
@interface GADMAdapterMintegralUtils : NSObject

UIWindow *_Nullable GADMAdapterMintegralKeyWindow(void);

NSError *_Nonnull GADMAdapterMintegralErrorWithCodeAndDescription(GADMintegralErrorCode code,
                                                                  NSString *_Nonnull description);

void GADMAdapterMintegralMutableSetAddObject(NSMutableSet *_Nullable set,
                                             NSObject *_Nonnull object);

+ (CGSize)bannerSizeFromAdConfiguration:(nonnull GADMediationBannerAdConfiguration *)adConfiguration
                                  error:(NSError *_Nullable *_Nullable)errorPtr;

+ (void)downLoadNativeAdImageWithURLString:(NSString *_Nonnull)URLString
                         completionHandler:
                             (void (^_Nullable)(GADNativeAdImage *_Nullable nativeAdImage))
                                 completionHandler;

/// Set MTGSDK's COPPA setting using
/// GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment.
///
/// If tagForChildDirectedTreatment is nil, then set it to MTGBoolUnknown.
/// If tagForChildDirectedTreatment is YES, then set it to MTGBoolYes.
/// If tagForChildDirectedTreatment is NO, then set it to MTGBoolNo.
+ (void)setCoppaUsingRequestConfiguration;

@end
