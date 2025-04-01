//
//  GADMAdapterInMobiInterstitialRewardedAd.h
//  InterstitialExample
//
//  Created by Vikas Jangir on 13/03/25.
//  Copyright © 2025 Google. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GoogleMobileAds/GoogleMobileAds.h>
#import <InMobiSDK/InMobiSDK-Swift.h>
NS_ASSUME_NONNULL_BEGIN

@interface GADMAdapterInMobiInterstitialRewardedAd : NSObject <GADMediationRewardedAd, IMInterstitialDelegate>

- (void)loadInterstitialAdForAdConfiguration:
            (nonnull GADMediationRewardedAdConfiguration *)adConfiguration
                           completionHandler:(nonnull GADMediationRewardedLoadCompletionHandler)
                                                 completionHandler;
@end
NS_ASSUME_NONNULL_END
