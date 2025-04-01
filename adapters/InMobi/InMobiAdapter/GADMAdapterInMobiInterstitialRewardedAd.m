//
//  GADMAdapterInMobiInterstitialRewardedAd.m
//  InterstitialExample
//
//  Created by Vikas Jangir on 13/03/25.
//  Copyright © 2025 Google. All rights reserved.
//

#import "GADMAdapterInMobiInterstitialRewardedAd.h"
#import <InMobiSDK/InMobiSDK-Swift.h>
#include <stdatomic.h>
#import "GADInMobiExtras.h"
#import "GADMAdapterInMobiConstants.h"
#import "GADMAdapterInMobiDelegateManager.h"
#import "GADMAdapterInMobiInitializer.h"
#import "GADMAdapterInMobiUtils.h"
#import "GADMInMobiConsent.h"
#import "GADMediationAdapterInMobi.h"

@implementation GADMAdapterInMobiInterstitialRewardedAd {
  /// An ad event delegate to invoke when ad rendering events occur.
  __weak id<GADMediationRewardedAdEventDelegate> _interstitalAdEventDelegate;

  /// Ad Configuration for the interstitialRewarded ad to be rendered.
    GADMediationRewardedAdConfiguration *_interstitialAdConfig;

  /// The completion handler to call when the ad loading succeeds or fails.
    GADMediationRewardedLoadCompletionHandler _interstitialRenderCompletionHandler;

  /// InMobi interstitialRewarded ad.
  IMInterstitial *_interstitialRewardedAd;
}

- (void)loadInterstitialAdForAdConfiguration:
            (nonnull GADMediationRewardedAdConfiguration *)adConfiguration
                           completionHandler:(nonnull GADMediationRewardedLoadCompletionHandler)
                                                 completionHandler {
  _interstitialAdConfig = adConfiguration;
  __block atomic_flag completionHandlerCalled = ATOMIC_FLAG_INIT;
  __block GADMediationRewardedLoadCompletionHandler originalCompletionHandler =
      [completionHandler copy];
    _interstitialRenderCompletionHandler = ^id<GADMediationRewardedAdEventDelegate>(
                                                                                    id<GADMediationRewardedAd> rewardedAd, NSError *error) {
                                                                                        if (atomic_flag_test_and_set(&completionHandlerCalled)) {
                                                                                            return nil;
                                                                                        }
                                                                                        id<GADMediationRewardedAdEventDelegate> delegate = nil;
                                                                                        if (originalCompletionHandler) {
                                                                                            delegate = originalCompletionHandler(rewardedAd, error);
                                                                                        }
                                                                                        originalCompletionHandler = nil;
                                                                                        return delegate;
                                                                                    };

  GADMAdapterInMobiInterstitialRewardedAd *__weak weakSelf = self;
  NSString *accountID = _interstitialAdConfig.credentials.settings[GADMAdapterInMobiAccountID];
  [GADMAdapterInMobiInitializer.sharedInstance
      initializeWithAccountID:accountID
            completionHandler:^(NSError *_Nullable error) {
              GADMAdapterInMobiInterstitialRewardedAd *strongSelf = weakSelf;
              if (!strongSelf) {
                return;
              }

              if (error) {
                GADMAdapterInMobiLog(@"Initialization failed: %@", error.localizedDescription);
                strongSelf->_interstitialRenderCompletionHandler(nil, error);
                return;
              }

              [strongSelf requestInterstitialAd];
            }];
}

- (void)requestInterstitialAd {
  long long placementId =
      [_interstitialAdConfig.credentials.settings[GADMAdapterInMobiPlacementID] longLongValue];
  if (placementId == 0) {
    NSError *error = GADMAdapterInMobiErrorWithCodeAndDescription(
        GADMAdapterInMobiErrorInvalidServerParameters,
        @"GADMediationAdapterInMobi - Error : Placement ID not specified.");
    _interstitialRenderCompletionHandler(nil, error);
    return;
  }

  if ([_interstitialAdConfig isTestRequest]) {
    GADMAdapterInMobiLog(
        @"Please enter your device ID in the InMobi console to receive test ads from "
        @"InMobi");
  }

  _interstitialRewardedAd = [[IMInterstitial alloc] initWithPlacementId:placementId delegate:self];

  GADInMobiExtras *extras = _interstitialAdConfig.extras;
  if (extras && extras.keywords) {
    [_interstitialRewardedAd setKeywords:extras.keywords];
  }

  if (_interstitialAdConfig.watermark != nil) {
    IMWatermark *watermark =
        [[IMWatermark alloc] initWithWaterMarkImageData:_interstitialAdConfig.watermark];
    [_interstitialRewardedAd setWatermarkWith:watermark];
  }

  GADMAdapterInMobiSetTargetingFromAdConfiguration(_interstitialAdConfig);
  GADMAdapterInMobiSetUSPrivacyCompliance();

  NSData *bidResponseData =
      GADMAdapterInMobiBidResponseDataFromAdConfigration(_interstitialAdConfig);
  GADMAdapterInMobiRequestParametersMediationType mediationType =
      bidResponseData ? GADMAdapterInMobiRequestParametersMediationTypeRTB
                      : GADMAdapterInMobiRequestParametersMediationTypeWaterfall;
  NSDictionary<NSString *, id> *requestParameters = GADMAdapterInMobiRequestParameters(
      extras, mediationType,
      GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment);
  [_interstitialRewardedAd setExtras:requestParameters];

  if (bidResponseData) {
    [_interstitialRewardedAd load:bidResponseData];
  } else {
    [_interstitialRewardedAd load];
  }
}

- (void)presentFromViewController:(nonnull UIViewController *)viewController {
  if ([_interstitialRewardedAd isReady]) {
    [_interstitialRewardedAd showFrom:viewController];
  } else {
    NSError *error = GADMAdapterInMobiErrorWithCodeAndDescription(
        GADMAdapterInMobiErrorAdNotReady,
        @"InMobi SDK is not ready to present an interstitialRewarded ad.");
    [_interstitalAdEventDelegate didFailToPresentWithError:error];
  }
}

- (void)stopBeingDelegate {
  _interstitialRewardedAd.delegate = nil;
}

#pragma mark IMInterstitialDelegate Methods

- (void)interstitialDidFinishLoading:(nonnull IMInterstitial *)interstitial {
  GADMAdapterInMobiLog(@"InMobi SDK loaded an interstitialRewarded ad successfully.");
  _interstitalAdEventDelegate = _interstitialRenderCompletionHandler(self, nil);
}

- (void)interstitial:(nonnull IMInterstitial *)interstitial
    didFailToLoadWithError:(nonnull IMRequestStatus *)error {
  GADMAdapterInMobiLog(@"InMobi SDK failed to load interstitialRewarded ad.");
  _interstitialRenderCompletionHandler(nil, error);
}

- (void)interstitialWillPresent:(nonnull IMInterstitial *)interstitial {
  GADMAdapterInMobiLog(@"InMobi SDK will present a full screen interstitialRewarded ad.");
  [_interstitalAdEventDelegate willPresentFullScreenView];
}

- (void)interstitialDidPresent:(nonnull IMInterstitial *)interstitial {
  GADMAdapterInMobiLog(@"InMobi SDK did present a full screen interstitialRewarded ad.");
}

- (void)interstitial:(nonnull IMInterstitial *)interstitial
    didFailToPresentWithError:(nonnull IMRequestStatus *)error {
  GADMAdapterInMobiLog(@"InMobi SDK did fail to present interstitialRewarded ad.");
  [_interstitalAdEventDelegate didFailToPresentWithError:error];
}

- (void)interstitialWillDismiss:(nonnull IMInterstitial *)interstitial {
  GADMAdapterInMobiLog(@"InMobi SDK will dismiss an interstitialRewarded ad.");
  [_interstitalAdEventDelegate willDismissFullScreenView];
}

- (void)interstitialDidDismiss:(nonnull IMInterstitial *)interstitial {
  GADMAdapterInMobiLog(@"InMobi SDK did dismiss an interstitialRewarded ad.");
  [_interstitalAdEventDelegate didDismissFullScreenView];
}

- (void)interstitial:(nonnull IMInterstitial *)interstitial
    didInteractWithParams:(nullable NSDictionary<NSString *, id> *)params {
  GADMAdapterInMobiLog(@"InMobi SDK recorded a click on an interstitialRewarded ad.");
  [_interstitalAdEventDelegate reportClick];
}

- (void)userWillLeaveApplicationFromInterstitial:(nonnull IMInterstitial *)interstitial {
  GADMAdapterInMobiLog(
      @"InMobi SDK will cause the user to leave the application from an interstitialRewarded ad.");
}

- (void)interstitialDidReceiveAd:(nonnull IMInterstitial *)interstitial {
  GADMAdapterInMobiLog(@"InMobi AdServer returned a response for interstitialRewarded ad.");
}

- (void)interstitialAdImpressed:(nonnull IMInterstitial *)interstitial {
  GADMAdapterInMobiLog(@"InMobi SDK recorded an impression from interstitialRewarded ad.");
  [_interstitalAdEventDelegate reportImpression];
}

@end
