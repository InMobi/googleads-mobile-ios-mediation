// Copyright 2019 Google Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#import <Foundation/Foundation.h>
#import <GoogleMobileAds/GoogleMobileAds.h>
#import <IronSource/IronSource.h>
#import "GADMediationAdapterIronSource.h"

/// Adds |object| to |set| if |object| is not nil.
void GADMAdapterIronSourceMutableSetAddObject(NSMutableSet *_Nullable set,
                                              NSObject *_Nonnull object);

/// Sets |value| for |key| in |mapTable| if |value| is not nil.
void GADMAdapterIronSourceMapTableSetObjectForKey(NSMapTable *_Nullable mapTable,
                                                  id<NSCopying> _Nullable key, id _Nullable value);

/// Removes the object for |key| in mapTable if |key| is not nil.
void GADMAdapterIronSourceMapTableRemoveObjectForKey(NSMapTable *_Nullable mapTable,
                                                     id _Nullable key);

/// Returns an NSError with code |code| and with NSLocalizedDescriptionKey and
/// NSLocalizedFailureReasonErrorKey values set to |description|.
NSError *_Nonnull GADMAdapterIronSourceErrorWithCodeAndDescription(
    GADMAdapterIronSourceErrorCode code, NSString *_Nonnull description);

/// Holds Shared code for IronSource adapters.
@interface GADMAdapterIronSourceUtils : NSObject

// IronSource Util methods.
+ (BOOL)isEmpty:(nullable id)value;

+ (void)onLog:(nonnull NSString *)log;

+ (nonnull NSString *)getAdMobSDKVersion;

+ (nullable ISBannerSize *)ironSourceAdSizeFromRequestedSize:(GADAdSize)size;

+ (nonnull ISAAdSize *)iAdsSizeFromRequestedSize:(GADAdSize)size;

+ (NSArray<ISAAdFormat *> *_Nullable)adFormatsToInitializeForAdUnits:(nonnull NSSet *)adUnits;

+ (nonnull NSMutableDictionary<NSString *, NSString *> *)getExtraParamsWithWatermark:
    (nullable NSData *)watermarkData;

+ (nonnull NSString *)getMediationType;
@end
