/* WizSpinnerWindowHelper - Scene-aware window lookup for cordova-ios 8+
 *
 * @copyright Platogo Interactive Entertainment GmbH
 * @file WizSpinnerWindowHelper.h
 *
 */

#ifndef WizSpinnerWindowHelper_h
#define WizSpinnerWindowHelper_h

#import <UIKit/UIKit.h>

// Helper to get the key window in scene-based apps (cordova-ios 8+).
// Prefers a window from the foreground-active scene, falls back to any window
// in that scene if no window reports isKeyWindow yet.
// Falls back to deprecated keyWindow for older cordova-ios versions.
static inline UIWindow* wizGetActiveWindow(void) {
    if (@available(iOS 13.0, *)) {
        // Find the foreground-active window scene
        UIWindowScene *activeScene = nil;
        for (UIScene *scene in [UIApplication sharedApplication].connectedScenes) {
            if ([scene isKindOfClass:[UIWindowScene class]] &&
                scene.activationState == UISceneActivationStateForegroundActive) {
                activeScene = (UIWindowScene *)scene;
                break;
            }
        }

        // If no foreground-active scene, try foreground-inactive (e.g. during transitions)
        if (!activeScene) {
            for (UIScene *scene in [UIApplication sharedApplication].connectedScenes) {
                if ([scene isKindOfClass:[UIWindowScene class]] &&
                    scene.activationState == UISceneActivationStateForegroundInactive) {
                    activeScene = (UIWindowScene *)scene;
                    break;
                }
            }
        }

        if (activeScene) {
            // Prefer the key window from the active scene
            for (UIWindow *window in activeScene.windows) {
                if (window.isKeyWindow) {
                    return window;
                }
            }
            // Fallback: return the first window from the active scene
            // (handles case where no window reports isKeyWindow yet)
            if (activeScene.windows.count > 0) {
                return activeScene.windows.firstObject;
            }
        }
    }
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    return [UIApplication sharedApplication].keyWindow;
#pragma clang diagnostic pop
}

#endif /* WizSpinnerWindowHelper_h */
