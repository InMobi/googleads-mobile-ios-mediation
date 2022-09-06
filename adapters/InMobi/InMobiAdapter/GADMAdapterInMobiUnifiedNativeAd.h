//
//  GADMAdapterInMobiUnifiedNativeAd.h
//  InMobiAdapter
//
//  Created by Bavirisetti.Dinesh on 02/09/22.
//
//

#import <Foundation/Foundation.h>
#import <InMobiSDK/IMNative.h>
#import <GoogleMobileAds/GoogleMobileAds.h>

@class GADMAdapterInMobiUnifiedNativeAd;

@interface GADMAdapterInMobiUnifiedNativeAd : NSObject <GADMediationNativeAd>

/// Initializes a new instance with |Configuration| and |adapter|.
- (nonnull instancetype)initWithPlacementIdentifier:(nonnull NSNumber *)placementIdentifier;

- (void)loadNativeAdForAdConfiguration:(nonnull GADMediationNativeAdConfiguration *)adConfiguration completionHandler:(nonnull GADMediationNativeLoadCompletionHandler)completionHandler;
@end
