#import "Workspace.h"
#import <objc/runtime.h>

// Runtime schema only. No object values, storage reads, or private method calls.
static NSArray *WBGMethods(Class cls) {
    unsigned int count=0; Method *methods=class_copyMethodList(cls,&count);
    NSMutableArray *rows=[NSMutableArray new];
    for (unsigned int i=0; i<count && i<180; i++) {
        const char *types=method_getTypeEncoding(methods[i]);
        [rows addObject:@{@"selector":NSStringFromSelector(method_getName(methods[i])),
                         @"encoding":types ? @(types) : @""}];
    }
    free(methods); return rows;
}
static NSDictionary *WBGNativeSchema(void) {
    unsigned int count=0; Class *classes=objc_copyClassList(&count);
    NSMutableArray<NSString *> *names=[NSMutableArray new];
    for (unsigned int i=0; i<count; i++) {
        NSString *n=@(class_getName(classes[i]));
        if ([n containsString:@"ChatViewController"] || [n containsString:@"ChatMessagesProvider"] ||
            [n containsString:@"ChatSessionCell"] || [n isEqual:@"WAChatSession"] ||
            [n isEqual:@"WAMessage"] || [n isEqual:@"ChatManager"] || [n isEqual:@"WAChatStorage"])
            [names addObject:n];
    }
    free(classes); [names sortUsingSelector:@selector(compare:)];
    NSMutableOrderedSet<NSString *> *chosen=[NSMutableOrderedSet orderedSetWithArray:@[@"ChatViewController",@"ChatManager",@"WAChatSession",@"WAMessage",@"WAChatStorage",@"ChatSessionCell"]];
    [chosen addObjectsFromArray:names];
    NSMutableArray *descriptions=[NSMutableArray new];
    for (NSString *name in chosen) {
        if (descriptions.count>=64) break;
        Class cls=objc_getClass(name.UTF8String); if (!cls) continue;
        NSMutableArray *properties=[NSMutableArray new]; unsigned int n=0;
        objc_property_t *items=class_copyPropertyList(cls,&n);
        for (unsigned int i=0; i<n && i<120; i++) {
            const char *attrs=property_getAttributes(items[i]);
            [properties addObject:@{@"name":@(property_getName(items[i])),@"attributes":attrs ? @(attrs) : @""}];
        }
        free(items);
        Class superClass=class_getSuperclass(cls);
        [descriptions addObject:@{@"class":name,@"superclass":superClass ? @(class_getName(superClass)) : @"",
            @"instance_methods":WBGMethods(cls),@"class_methods":WBGMethods(object_getClass(cls)),@"properties":properties}];
    }
    NSMutableArray *protocols=[NSMutableArray new];
    for (NSString *name in @[@"ChatViewControllerChatMessagesProviding",@"ChatViewControllerContentSendProviding",
        @"ChatViewControllerChatCellsProviding",@"ChatViewControllerChatBarProviding",
        @"ChatViewControllerHeaderViewItemProviding",@"ChatMessageCellDataPresentationProviding",
        @"ChatStorageProviding",@"WAMessageProtocol",@"ChatSessionCellActionsHandling"]) {
        Protocol *p=objc_getProtocol(name.UTF8String);
        NSMutableArray *methods=[NSMutableArray new];
        if (p) {
            for (int required=0; required<2; required++) for (int instance=0; instance<2; instance++) {
                unsigned int n=0; struct objc_method_description *list=protocol_copyMethodDescriptionList(p,required,instance,&n);
                for (unsigned int i=0; i<n && i<180; i++) if (list[i].name)
                    [methods addObject:@{@"selector":NSStringFromSelector(list[i].name),@"encoding":list[i].types ? @(list[i].types) : @"",@"required":@(required),@"instance":@(instance)}];
                free(list);
            }
        }
        [protocols addObject:@{@"protocol":name,@"available":@(p!=nil),@"methods":methods}];
    }
    return @{@"schema_version":@1,@"kind":@"runtime_structure_only",@"app_version":[NSBundle.mainBundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"] ?: @"",
        @"bundle_id":NSBundle.mainBundle.bundleIdentifier ?: @"",@"ios_version":UIDevice.currentDevice.systemVersion,
        @"matching_class_count":@(names.count),@"classes":descriptions,@"protocols":protocols};
}

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
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(attach) name:UIWindowDidBecomeKeyNotification object:nil];
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(attach) name:UIWindowDidBecomeVisibleNotification object:nil];
    }
    return self;
}
- (void)attach {
    if (!NSThread.isMainThread) { dispatch_async(dispatch_get_main_queue(), ^{ [self attach]; }); return; }
    NSMutableOrderedSet<UIWindow *> *windows = [NSMutableOrderedSet new];
    for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
        if (![scene isKindOfClass:UIWindowScene.class] || scene.activationState != UISceneActivationStateForegroundActive) continue;
        [windows addObjectsFromArray:((UIWindowScene *)scene).windows];
    }
    // WhatsApp 26.38.74 has no UIApplicationSceneManifest; support its legacy windows.
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    [windows addObjectsFromArray:UIApplication.sharedApplication.windows];
#pragma clang diagnostic pop
        for (UIWindow *window in windows) {
            if (window.hidden || window.windowLevel != UIWindowLevelNormal || !window.rootViewController) continue;
            UIButton *existing = [self.buttons objectForKey:window];
            if (existing) { [window bringSubviewToFront:existing]; continue; }
            UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
            [button setTitle:@"הלקוחות שלי" forState:UIControlStateNormal];
            button.backgroundColor = UIColor.systemGreenColor;
            [button setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
            button.layer.cornerRadius = 18; button.translatesAutoresizingMaskIntoConstraints = NO;
            [button addTarget:self action:@selector(open:) forControlEvents:UIControlEventTouchUpInside];
            UILongPressGestureRecognizer *press=[[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(inspect:)];
            press.minimumPressDuration=1.5; [button addGestureRecognizer:press];
            [window addSubview:button]; [self.buttons setObject:button forKey:window];
            [NSLayoutConstraint activateConstraints:@[[button.trailingAnchor constraintEqualToAnchor:window.safeAreaLayoutGuide.trailingAnchor constant:-14],
              [button.bottomAnchor constraintEqualToAnchor:window.safeAreaLayoutGuide.bottomAnchor constant:-76],
              [button.widthAnchor constraintEqualToConstant:132], [button.heightAnchor constraintEqualToConstant:38]]];
        }
}
- (void)open:(UIButton *)sender {
    UIViewController *vc = sender.window.rootViewController;
    while (vc.presentedViewController) vc = vc.presentedViewController;
    if (!vc || vc.isBeingDismissed) return;
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:[WBGWorkspaceController new]];
    [vc presentViewController:nav animated:YES completion:nil];
}
- (void)inspect:(UILongPressGestureRecognizer *)gesture {
    if (gesture.state!=UIGestureRecognizerStateBegan) return;
    UIViewController *vc=gesture.view.window.rootViewController;
    while (vc.presentedViewController) vc=vc.presentedViewController;
    if (!vc || vc.isBeingDismissed || [vc isKindOfClass:UIAlertController.class]) return;
    UIAlertController *prompt=[UIAlertController alertControllerWithTitle:@"מיפוי הממשק המקורי" message:@"יצירת דוח של שמות מחלקות וחתימות פונקציות בלבד. הדוח אינו קורא הודעות, סיסמאות או נתוני לקוחות ואינו משנה את WhatsApp." preferredStyle:UIAlertControllerStyleAlert];
    [prompt addAction:[UIAlertAction actionWithTitle:@"ביטול" style:UIAlertActionStyleCancel handler:nil]];
    [prompt addAction:[UIAlertAction actionWithTitle:@"יצירת דוח" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        // Let UIKit finish dismissing the confirmation before presenting sharing UI.
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW,(int64_t)(0.4*NSEC_PER_SEC)),dispatch_get_main_queue(),^{
            NSData *data=[NSJSONSerialization dataWithJSONObject:WBGNativeSchema() options:NSJSONWritingPrettyPrinted error:nil];
            NSString *name=[NSString stringWithFormat:@"WhatsApp-native-map-%@.json",NSUUID.UUID.UUIDString];
            NSURL *url=[NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:name]];
            if (!data || data.length>4*1024*1024 || ![data writeToURL:url options:NSDataWritingAtomic|NSDataWritingFileProtectionComplete error:nil]) return;
            UIActivityViewController *share=[[UIActivityViewController alloc] initWithActivityItems:@[url] applicationActivities:nil];
            share.popoverPresentationController.sourceView=gesture.view;
            share.popoverPresentationController.sourceRect=gesture.view.bounds;
            share.completionWithItemsHandler=^(UIActivityType type,BOOL completed,NSArray *items,NSError *error) { [NSFileManager.defaultManager removeItemAtURL:url error:nil]; };
            [vc presentViewController:share animated:YES completion:nil];
        });
    }]];
    [vc presentViewController:prompt animated:YES completion:nil];
}
@end

__attribute__((constructor)) static void WBGStart(void) {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *bundle = NSBundle.mainBundle.bundleIdentifier;
        NSSet *allowed = [NSSet setWithArray:@[@"net.whatsapp.WhatsAppSMB",@"net.whatsapp.WhatsApp",@"com.fouadraheb.watusiSMB",@"com.fouadraheb.watusi"]];
        // An untested host release must not silently activate this addon.
        BOOL host = [allowed containsObject:bundle];
        // Sideloadly can rewrite the bundle ID. Keep host identity/version checks.
        NSString *executable = [NSBundle.mainBundle objectForInfoDictionaryKey:@"CFBundleExecutable"];
        NSString *watusi = [NSBundle.mainBundle.bundlePath stringByAppendingPathComponent:@"Watusi.dylib"];
        host = host || ([executable isEqual:@"WhatsApp"] && [NSFileManager.defaultManager fileExistsAtPath:watusi]);
        if (!host || ![[NSBundle.mainBundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"] isEqual:@"26.38.74"]) return;
        static WBGLauncher *launcher; launcher = [WBGLauncher new];
        [launcher attach];
        for (NSNumber *seconds in @[@1,@3,@6]) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(seconds.doubleValue * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{ [launcher attach]; });
        }
    });
}
