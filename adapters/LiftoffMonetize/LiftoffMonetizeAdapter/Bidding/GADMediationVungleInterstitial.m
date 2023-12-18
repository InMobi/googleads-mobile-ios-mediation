// Copyright 2021 Google LLC
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

#import "GADMediationVungleInterstitial.h"
#include <stdatomic.h>
#import "GADMAdapterVungleConstants.h"
#import "GADMAdapterVungleDelegate.h"
#import "GADMAdapterVungleRouter.h"
#import "GADMAdapterVungleUtils.h"

@interface GADMediationVungleInterstitial () <GADMAdapterVungleDelegate,
                                              GADMediationInterstitialAd,
                                              VungleInterstitialDelegate>
@end

@implementation GADMediationVungleInterstitial {
  /// Ad configuration for the ad to be loaded.
  GADMediationInterstitialAdConfiguration *_adConfiguration;

  /// The completion handler to call when an ad loads successfully or fails.
  GADMediationInterstitialLoadCompletionHandler _adLoadCompletionHandler;

  /// The ad event delegate to forward ad rendering events to the Google Mobile Ads SDK.
  __weak id<GADMediationInterstitialAdEventDelegate> _delegate;

  /// Liftoff Monetize interstitial ad instance.
  VungleInterstitial *_interstitialAd;
}

@synthesize desiredPlacement;

#pragma mark - GADMediationVungleInterstitial Methods

- (nonnull instancetype)
    initWithAdConfiguration:(nonnull GADMediationInterstitialAdConfiguration *)adConfiguration
          completionHandler:
              (nonnull GADMediationInterstitialLoadCompletionHandler)completionHandler {
  self = [super init];
  if (self) {
    _adConfiguration = adConfiguration;
    self.desiredPlacement =
        [GADMAdapterVungleUtils findPlacement:adConfiguration.credentials.settings];

    __block atomic_flag adLoadHandlerCalled = ATOMIC_FLAG_INIT;
    __block GADMediationInterstitialLoadCompletionHandler origAdLoadHandler =
        [completionHandler copy];

    /// Ensure the original completion handler is only called once, and is deallocated once called.
    _adLoadCompletionHandler = ^id<GADMediationInterstitialAdEventDelegate>(
        id<GADMediationInterstitialAd> ad, NSError *error) {
      if (atomic_flag_test_and_set(&adLoadHandlerCalled)) {
        return nil;
      }
      id<GADMediationInterstitialAdEventDelegate> delegate = nil;
      if (origAdLoadHandler) {
        delegate = origAdLoadHandler(ad, error);
      }
      origAdLoadHandler = nil;
      return delegate;
    };
  }
  return self;
}

- (void)requestInterstitialAd {
  if (![VungleAds isInitialized]) {
    NSString *appID = [GADMAdapterVungleUtils findAppID:_adConfiguration.credentials.settings];
    [GADMAdapterVungleRouter.sharedInstance initWithAppId:appID delegate:self];
    return;
  }

  [self loadAd];
}

#pragma mark - GADMediationInterstitialAd Methods

- (void)presentFromViewController:(UIViewController *)rootViewController {
  [_interstitialAd presentWith:rootViewController];
}

#pragma mark - Private methods

- (void)loadAd {
  _interstitialAd = [[VungleInterstitial alloc] initWithPlacementId:self.desiredPlacement];
  _interstitialAd.delegate = self;
  VungleAdsExtras *extras = [[VungleAdsExtras alloc] init];
  [extras setWithWatermark:[_adConfiguration.watermark base64EncodedStringWithOptions:0]];
  [_interstitialAd setWithExtras:extras];
  [_interstitialAd load:_adConfiguration.bidResponse];
}

#pragma mark - VungleInterstitialDelegate

- (void)interstitialAdDidLoad:(nonnull VungleInterstitial *)interstitial {
  if (_adLoadCompletionHandler) {
    _delegate = _adLoadCompletionHandler(self, nil);
  }
}

- (void)interstitialAdDidFailToLoad:(nonnull VungleInterstitial *)interstitial
                          withError:(nonnull NSError *)error {
  _adLoadCompletionHandler(nil, error);
}

- (void)interstitialAdWillPresent:(nonnull VungleInterstitial *)interstitial {
  [_delegate willPresentFullScreenView];
}

- (void)interstitialAdDidPresent:(nonnull VungleInterstitial *)interstitial {
  // Google Mobile Ads SDK doesn't have a matching event.
}

- (void)interstitialAdDidFailToPresent:(nonnull VungleInterstitial *)interstitial
                             withError:(nonnull NSError *)error {
  [_delegate didFailToPresentWithError:error];
}

- (void)interstitialAdWillClose:(nonnull VungleInterstitial *)interstitial {
  [_delegate willDismissFullScreenView];
}

- (void)interstitialAdDidClose:(nonnull VungleInterstitial *)interstitial {
  [_delegate didDismissFullScreenView];
}

- (void)interstitialAdDidTrackImpression:(nonnull VungleInterstitial *)interstitial {
  [_delegate reportImpression];
}

- (void)interstitialAdDidClick:(nonnull VungleInterstitial *)interstitial {
  [_delegate reportClick];
}

- (void)interstitialAdWillLeaveApplication:(nonnull VungleInterstitial *)interstitial {
  // Google Mobile Ads SDK doesn't have a matching event.
}

#pragma mark - GADMAdapterVungleDelegate

- (void)initialized:(BOOL)isSuccess error:(nullable NSError *)error {
  if (!isSuccess) {
    _adLoadCompletionHandler(nil, error);
    return;
  }
  [self loadAd];
}

@end
