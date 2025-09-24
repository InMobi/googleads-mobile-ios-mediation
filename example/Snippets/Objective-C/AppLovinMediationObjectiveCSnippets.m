//
//  Copyright (C) 2025 Google, Inc.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import <UIKit/UIKit.h>
#import <AppLovinSDK/AppLovinSDK.h>
#import <GoogleMobileAds/GoogleMobileAds.h>

@interface AppLovinMediationObjectiveCSnippets : NSObject
@end

/**
 * Objective-C code snippets for
 * https://developers.google.com/admob/ios/mediation/applovin and
 * https://developers.google.com/ad-manager/mobile-ads-sdk/ios/mediation/applovin
 */
@implementation AppLovinMediationObjectiveCSnippets

- (void)setUserConsent {
    // [START set_user_consent]
    [ALPrivacySettings setHasUserConsent:YES];
    // [END set_user_consent]
}
@end
