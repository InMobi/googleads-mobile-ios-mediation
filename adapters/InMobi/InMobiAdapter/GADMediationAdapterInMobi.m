// Copyright 2019 Google LLC
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

@implementation GADMediationAdapterInMobi {
  /// InMobi rewarded ad wrapper.
  GADMAdapterInMobiRewardedAd *_rewardedAd;

  /// InMobi banner ad wrapper.
  GADMAdapterInMobiBannerAd *_bannerAd;

  /// InMobi interstitial ad wrapper.
  GADMAdapterInMobiInterstitialAd *_interstitialAd;
    
  /// InMobi interstitial rewarded ad wrapper.
  GADMAdapterInMobiRewardedAd *_interstitialRewardedAd;

  /// InMobi native ad wrapper.
  GADMAdapterInMobiUnifiedNativeAd *_nativeAd;
}

- (void)collectSignalsForRequestParameters:(nonnull GADRTBRequestParameters *)params
                         completionHandler:
                             (nonnull GADRTBSignalCompletionHandler)completionHandler {
  GADInMobiExtras *extras = params.extras;
  NSNumber *childDirectedTreatment =
      GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment;
  NSDictionary<NSString *, id> *requestParameters = GADMAdapterInMobiRequestParameters(
      extras, GADMAdapterInMobiRequestParametersMediationTypeRTB, childDirectedTreatment);
  NSString *keywords = nil;
  if (extras && extras.keywords) {
    keywords = extras.keywords;
  }

  NSString *token = [IMSdk getTokenWithExtras:requestParameters andKeywords:keywords];

  if (!token.length) {
    NSString *errorMessage =
        [NSString stringWithFormat:@"A nil or empty bid token is returned by InMobi: %@", token];
    NSError *error = GADMAdapterInMobiErrorWithCodeAndDescription(
        GADMAdapterInMobiErrorInvalidBidToken, errorMessage);
    completionHandler(nil, error);
    return;
  }

  completionHandler(token, nil);
}

+ (void)setUpWithConfiguration:(nonnull GADMediationServerConfiguration *)configuration
             completionHandler:(nonnull GADMediationAdapterSetUpCompletionBlock)completionHandler {
  if (GADMAdapterInMobiInitializer.sharedInstance.initializationState ==
      GADMAdapterInMobiInitStateInitialized) {
    completionHandler(nil);
    return;
  }

  NSMutableSet<NSString *> *accountIDs = [[NSMutableSet alloc] init];

  for (GADMediationCredentials *cred in configuration.credentials) {
    NSString *accountIDFromSettings = cred.settings[GADMAdapterInMobiAccountID];
    if (accountIDFromSettings.length) {
      GADMAdapterInMobiMutableSetAddObject(accountIDs, accountIDFromSettings);
    }
  }

  if (!accountIDs.count) {
    NSError *error = GADMAdapterInMobiErrorWithCodeAndDescription(
        GADMAdapterInMobiErrorInvalidServerParameters,
        @"InMobi mediation configurations did not contain a valid account ID.");
    completionHandler(error);
    return;
  }

  NSString *accountID = [accountIDs anyObject];
  if (accountIDs.count > 1) {
    GADMAdapterInMobiLog(@"Found the following account IDs: %@. "
                         @"Please remove any account IDs you are not using from the AdMob UI.",
                         accountIDs);
    GADMAdapterInMobiLog(@"Initializing InMobi SDK with the account ID: %@", accountID);
  }

  [GADMAdapterInMobiInitializer.sharedInstance initializeWithAccountID:accountID
                                                     completionHandler:^(NSError *_Nullable error) {
                                                       completionHandler(error);
                                                     }];
}

+ (GADVersionNumber)adSDKVersion {
  NSString *versionString = [IMSdk getVersion];
  NSArray<NSString *> *versionComponents = [versionString componentsSeparatedByString:@"."];

  GADVersionNumber version = {0};
  if (versionComponents.count >= 3) {
    version.majorVersion = versionComponents[0].integerValue;
    version.minorVersion = versionComponents[1].integerValue;
    version.patchVersion = versionComponents[2].integerValue;
  }
  return version;
}

+ (nullable Class<GADAdNetworkExtras>)networkExtrasClass {
  return [GADInMobiExtras class];
}

+ (GADVersionNumber)adapterVersion {
  NSArray<NSString *> *versionComponents =
      [GADMAdapterInMobiVersion componentsSeparatedByString:@"."];
  GADVersionNumber version = {0};
  if (versionComponents.count >= 4) {
    version.majorVersion = versionComponents[0].integerValue;
    version.minorVersion = versionComponents[1].integerValue;
    version.patchVersion =
        versionComponents[2].integerValue * 100 + versionComponents[3].integerValue;
  }
  return version;
}

- (void)loadRewardedAdForAdConfiguration:
            (nonnull GADMediationRewardedAdConfiguration *)adConfiguration
                       completionHandler:
                           (nonnull GADMediationRewardedLoadCompletionHandler)completionHandler {
  if (!_rewardedAd) {
    NSString *placementIdentifierString =
        adConfiguration.credentials.settings[GADMAdapterInMobiPlacementID];
    NSNumber *placementIdentifier =
        [NSNumber numberWithLongLong:placementIdentifierString.longLongValue];
    _rewardedAd =
        [[GADMAdapterInMobiRewardedAd alloc] initWithPlacementIdentifier:placementIdentifier];
  }

  [_rewardedAd loadRewardedAdForAdConfiguration:adConfiguration
                              completionHandler:completionHandler];
}

- (void)loadBannerForAdConfiguration:(nonnull GADMediationBannerAdConfiguration *)adConfiguration
                   completionHandler:
                       (nonnull GADMediationBannerLoadCompletionHandler)completionHandler {
  if (!_bannerAd) {
    _bannerAd = [[GADMAdapterInMobiBannerAd alloc] init];
  }

  [_bannerAd loadBannerAdForAdConfiguration:adConfiguration completionHandler:completionHandler];
}

- (void)loadInterstitialForAdConfiguration:
            (nonnull GADMediationInterstitialAdConfiguration *)adConfiguration
                         completionHandler:(nonnull GADMediationInterstitialLoadCompletionHandler)
                                               completionHandler {
  if (!_interstitialAd) {
    _interstitialAd = [[GADMAdapterInMobiInterstitialAd alloc] init];
  }

  [_interstitialAd loadInterstitialAdForAdConfiguration:adConfiguration
                                      completionHandler:completionHandler];
}

- (void)loadRewardedInterstitialAdForAdConfiguration:(GADMediationRewardedAdConfiguration *)adConfiguration completionHandler:(GADMediationRewardedLoadCompletionHandler)completionHandler {
    if (!_interstitialRewardedAd) {
      NSString *placementIdentifierString =
          adConfiguration.credentials.settings[GADMAdapterInMobiPlacementID];
      NSNumber *placementIdentifier =
          [NSNumber numberWithLongLong:placementIdentifierString.longLongValue];
        _interstitialRewardedAd =
          [[GADMAdapterInMobiRewardedAd alloc] initWithPlacementIdentifier:placementIdentifier];
    }

    [_interstitialRewardedAd loadRewardedAdForAdConfiguration:adConfiguration
                                completionHandler:completionHandler];
}

- (void)loadNativeAdForAdConfiguration:(nonnull GADMediationNativeAdConfiguration *)adConfiguration
                     completionHandler:
                         (nonnull GADMediationNativeLoadCompletionHandler)completionHandler {
  if (!_nativeAd) {
    _nativeAd = [[GADMAdapterInMobiUnifiedNativeAd alloc] init];
  }

  [_nativeAd loadNativeAdForAdConfiguration:adConfiguration completionHandler:completionHandler];
}

@end
