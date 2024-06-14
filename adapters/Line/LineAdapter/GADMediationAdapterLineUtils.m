// Copyright 2023 Google LLC
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

#import "GADMediationAdapterLineUtils.h"

#import <FiveAd/FiveAd.h>

#import "GADMediationAdapterLineConstants.h"

/// Returns application ID from the configuration.
static NSString *_Nullable GADMediationAdapterLineApplicationID(
    NSArray<GADMediationCredentials *> *_Nonnull credentialsArray,
    NSError *_Nullable *_Nonnull errorPtr) {
  if (!credentialsArray.count) {
    *errorPtr = GADMediationAdapterLineErrorWithCodeAndDescription(
        GADMediationAdapterLineErrorInvalidServerParameters,
        @"Server configuration did not contain a credential for LINE mediation.");
    return nil;
  }

  NSMutableSet<NSString *> *applicationIDSet = [[NSMutableSet alloc] init];
  for (GADMediationCredentials *credentials in credentialsArray) {
    GADMediationAdapterLineMutableSetAddObject(
        applicationIDSet, credentials.settings[GADMediationAdapterLineCredentialKeyApplicationID]);
  }

  if (!applicationIDSet.count) {
    *errorPtr = GADMediationAdapterLineErrorWithCodeAndDescription(
        GADMediationAdapterLineErrorInvalidServerParameters,
        @"Server configuration did not contain any application ID for LINE mediation.");
    return nil;
  }

  NSString *applicationID = applicationIDSet.anyObject;
  if (applicationIDSet.count > 1) {
    GADMediationAdapterLineLog(@"Found multiple application IDs. Please remove unused application "
                               @"IDs from the AdMob UI. Application IDs: %@",
                               applicationIDSet);
    GADMediationAdapterLineLog(@"Initializing FiveAd SDK with the application ID: %@",
                               applicationID);
  }
  return applicationID;
}

/// FADAdLoader object returned from registration.
static FADAdLoader *_Nullable gAdLoader;

NSError *_Nullable GADMediationAdapterLineRegisterFiveAd(
    NSArray<GADMediationCredentials *> *_Nonnull credentialsArray) {
  if (FADSettings.isConfigRegistered) {
    GADMediationAdapterLineLog(@"FiveAd SDK is already registered");
    return nil;
  }

  NSError *error = nil;
  NSString *applicationID = GADMediationAdapterLineApplicationID(credentialsArray, &error);
  if (error) {
    return error;
  }

  // Initialize FiveAd SDK.
  GADMobileAds *mobileAds = GADMobileAds.sharedInstance;
  FADConfig *config = [[FADConfig alloc] initWithAppId:applicationID];
  [config enableSoundByDefault:!mobileAds.applicationMuted];
  [config setIsTest:mobileAds.requestConfiguration.testDeviceIdentifiers.count];

  NSNumber *childDirectedTreatment = mobileAds.requestConfiguration.tagForChildDirectedTreatment;
  FADNeedChildDirectedTreatment needChildDirectedTreatment =
      kFADNeedChildDirectedTreatmentUnspecified;
  if (childDirectedTreatment != nil) {
    needChildDirectedTreatment = childDirectedTreatment.boolValue
                                     ? kFADNeedChildDirectedTreatmentTrue
                                     : kFADNeedChildDirectedTreatmentFalse;
  }
  [config setNeedChildDirectedTreatment:needChildDirectedTreatment];

  FADAdLoader *adLoader = [FADAdLoader adLoaderForConfig:config outError:&error];
  if (error) {
    GADMediationAdapterLineLog(@"There was an error while initializing FADAdLoader: %@",
                               error.localizedDescription);
    return GADMediationAdapterLineErrorWithFiveAdErrorCode(error.code);
  }
  gAdLoader = adLoader;

  return nil;
}

FADAdLoader *_Nullable GADMediationAdapterLineFADAdLoaderForRegisteredConfig(
    NSError *_Nullable *_Nullable errorPtr) {
  if (!gAdLoader) {
    NSString *errorDescription = @"FiveAd SDK hasn't been registered with FADConfig. It must be "
                                 @"registered first to initialize an ad loader.";
    GADMediationAdapterLineLog(errorDescription);
    *errorPtr = GADMediationAdapterLineErrorWithCodeAndDescription(
        GADMediationAdapterLineErrorFailedToInitializeAdLoader, errorDescription);
    return nil;
  }

  return gAdLoader;
}

NSError *GADMediationAdapterLineErrorWithCodeAndDescription(GADMediationAdapterLineErrorCode code,
                                                            NSString *_Nonnull description) {
  NSDictionary *userInfo =
      @{NSLocalizedDescriptionKey : description, NSLocalizedFailureReasonErrorKey : description};
  NSError *error = [NSError errorWithDomain:GADMediationAdapterLineErrorDomain
                                       code:code
                                   userInfo:userInfo];
  return error;
}

NSError *_Nonnull GADMediationAdapterLineErrorWithFiveAdErrorCode(FADErrorCode code) {
  NSString *description = @"Five Ad returned with a failure callback.";
  NSDictionary<NSErrorUserInfoKey, NSString *> *userInfo =
      @{NSLocalizedDescriptionKey : description, NSLocalizedFailureReasonErrorKey : description};
  NSError *error = [NSError errorWithDomain:GADMediationAdapterFiveAdErrorDomain
                                       code:code
                                   userInfo:userInfo];
  return error;
}

void GADMediationAdapterLineLog(NSString *_Nonnull format, ...) {
#ifdef DEBUG
  va_list arguments;
  va_start(arguments, format);
  NSString *log = [[NSString alloc] initWithFormat:format arguments:arguments];
  va_end(arguments);

  NSLog(@"GADMediationAdapterLine - %@", log);
#endif
}

void GADMediationAdapterLineMutableSetAddObject(NSMutableSet *_Nullable set,
                                                NSObject *_Nonnull object) {
  if (object) {
    [set addObject:object];  // Allow pattern.
  }
}

NSString *_Nullable GADMediationAdapterLineSlotID(GADMediationCredentials *_Nonnull credentials,
                                                  NSError *_Nullable *_Nonnull errorPtr) {
  NSString *slotID = credentials.settings[GADMediationAdapterLineCredentialKeyAdUnit];
  if (!slotID) {
    NSString *errorDescription = [NSString
        stringWithFormat:@"Invalid slot ID was received from the ad configuration. Please verify "
                         @"the ad unit mapping from the AdMob UI. Slot ID: %@.",
                         slotID];
    *errorPtr = GADMediationAdapterLineErrorWithCodeAndDescription(
        GADMediationAdapterLineErrorInvalidServerParameters, errorDescription);
    return nil;
  }
  return slotID;
}

BOOL GADMediationAdapterLineShouldEnableAudio(GADExtras *_Nullable extras) {
  GADMediationAdapterLineExtras *lineExtras = (GADMediationAdapterLineExtras *)extras;
  BOOL enableSound = !GADMobileAds.sharedInstance.applicationMuted;
  if (lineExtras) {
    switch (lineExtras.adAudio) {
      case GADMediationAdapterLineAdAudioMuted:
        enableSound = NO;
        break;
      case GADMediationAdapterLineAdAudioUnmuted:
        enableSound = YES;
        break;
      default:
        break;
    }
  }
  return enableSound;
}

NSString *_Nullable GADMediationAdapterLineWatermarkStringFromAdConfiguration(
    GADMediationAdConfiguration *_Nonnull adConfiguration) {
  NSData *watermark = adConfiguration.watermark;
  return [[NSString alloc] initWithData:watermark encoding:NSUTF8StringEncoding];
  ;
}
