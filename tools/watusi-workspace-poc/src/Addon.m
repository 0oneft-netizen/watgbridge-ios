#import "Workspace.h"

// Uses public UIKit surfaces only; never replaces WhatsApp's database or methods.
@interface WBGLauncher : NSObject
@property(nonatomic,strong) NSMapTable<UIWindow *,UIButton *> *buttons;
@end
@implementation WBGLauncher
- (instancetype)init {
    if ((self=[super init])) {
        _buttons = [NSMapTable weakToStrongObjectsMapTable];
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(attach) name:UIApplicationDidBecomeActiveNotification object:nil];
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(attach) name:UISceneDidActivateNotification object:nil];
    }
    return self;
}
- (void)attach {
    for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
        if (![scene isKindOfClass:UIWindowScene.class] || scene.activationState != UISceneActivationStateForegroundActive) continue;
        for (UIWindow *window in ((UIWindowScene *)scene).windows) {
            if (!window.isKeyWindow || !window.rootViewController || [self.buttons objectForKey:window]) continue;
            UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
            [button setTitle:@"הלקוחות שלי" forState:UIControlStateNormal];
            button.backgroundColor = UIColor.systemGreenColor;
            [button setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
            button.layer.cornerRadius = 18; button.translatesAutoresizingMaskIntoConstraints = NO;
            [button addTarget:self action:@selector(open:) forControlEvents:UIControlEventTouchUpInside];
            [window addSubview:button]; [self.buttons setObject:button forKey:window];
            [NSLayoutConstraint activateConstraints:@[[button.trailingAnchor constraintEqualToAnchor:window.safeAreaLayoutGuide.trailingAnchor constant:-14],
              [button.bottomAnchor constraintEqualToAnchor:window.safeAreaLayoutGuide.bottomAnchor constant:-76],
              [button.widthAnchor constraintEqualToConstant:132], [button.heightAnchor constraintEqualToConstant:38]]];
        }
    }
}
- (void)open:(UIButton *)sender {
    UIViewController *vc = sender.window.rootViewController;
    while (vc.presentedViewController) vc = vc.presentedViewController;
    if (!vc || vc.isBeingDismissed) return;
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:[WBGWorkspaceController new]];
    [vc presentViewController:nav animated:YES completion:nil];
}
@end

__attribute__((constructor)) static void WBGStart(void) {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *bundle = NSBundle.mainBundle.bundleIdentifier;
        NSSet *allowed = [NSSet setWithArray:@[@"net.whatsapp.WhatsAppSMB",@"net.whatsapp.WhatsApp",@"com.fouadraheb.watusiSMB",@"com.fouadraheb.watusi"]];
        // An untested host release must not silently activate this addon.
        if (![allowed containsObject:bundle] || ![[NSBundle.mainBundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"] isEqual:@"26.38.74"]) return;
        static WBGLauncher *launcher; launcher = [WBGLauncher new];
        [launcher attach];
    });
}
