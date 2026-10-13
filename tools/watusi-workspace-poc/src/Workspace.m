#import "Workspace.h"
#import <Security/Security.h>

static NSString *const WBGOrigin = @"https://5jjltkwg.tail256e07.ts.net";
static NSString *const WBGService = @"watgbridge.workspace.poc.v1";
static NSString *WBGString(id value) { return [value isKindOfClass:NSString.class] ? value : @""; }
static NSDictionary *WBGKey(void) {
    return @{(__bridge id)kSecClass:(__bridge id)kSecClassGenericPassword,
             (__bridge id)kSecAttrService:WBGService,
             (__bridge id)kSecAttrAccount:NSBundle.mainBundle.bundleIdentifier ?: @"workspace"};
}
static NSString *WBGToken(void) {
    NSMutableDictionary *query = [WBGKey() mutableCopy];
    query[(__bridge id)kSecReturnData] = @YES;
    CFTypeRef result = NULL;
    if (SecItemCopyMatching((__bridge CFDictionaryRef)query, &result) != errSecSuccess) return @"";
    return [[NSString alloc] initWithData:CFBridgingRelease(result) encoding:NSUTF8StringEncoding] ?: @"";
}
static BOOL WBGSaveToken(NSString *token) {
    if (!token.length) {
        OSStatus status = SecItemDelete((__bridge CFDictionaryRef)WBGKey());
        return status == errSecSuccess || status == errSecItemNotFound;
    }
    NSDictionary *values = @{(__bridge id)kSecValueData:[token dataUsingEncoding:NSUTF8StringEncoding]};
    OSStatus status = SecItemUpdate((__bridge CFDictionaryRef)WBGKey(), (__bridge CFDictionaryRef)values);
    if (status == errSecItemNotFound) {
        NSMutableDictionary *query = [WBGKey() mutableCopy];
        [query addEntriesFromDictionary:values];
        query[(__bridge id)kSecAttrAccessible] = (__bridge id)kSecAttrAccessibleWhenUnlockedThisDeviceOnly;
        status = SecItemAdd((__bridge CFDictionaryRef)query, NULL);
    }
    return status == errSecSuccess;
}

@interface WBGAPI : NSObject <NSURLSessionTaskDelegate>
@property(nonatomic,strong) NSURLSession *session;
- (void)request:(NSString *)path query:(NSArray<NSURLQueryItem *> *)query body:(NSDictionary *)body
          token:(NSString *)token completion:(void (^)(id, NSInteger, NSError *))completion;
@end
@implementation WBGAPI
- (instancetype)init {
    if ((self = [super init])) {
        NSURLSessionConfiguration *c = NSURLSessionConfiguration.ephemeralSessionConfiguration;
        c.HTTPCookieStorage = nil; c.HTTPShouldSetCookies = NO; c.URLCache = nil;
        c.requestCachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
        c.timeoutIntervalForRequest = 30; c.timeoutIntervalForResource = 45;
        _session = [NSURLSession sessionWithConfiguration:c delegate:self delegateQueue:nil];
    }
    return self;
}
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
 willPerformHTTPRedirection:(NSHTTPURLResponse *)response newRequest:(NSURLRequest *)request
 completionHandler:(void (^)(NSURLRequest *))completionHandler { completionHandler(nil); }
- (void)request:(NSString *)path query:(NSArray<NSURLQueryItem *> *)query body:(NSDictionary *)body
          token:(NSString *)token completion:(void (^)(id, NSInteger, NSError *))completion {
    NSURLComponents *parts = [NSURLComponents componentsWithString:[WBGOrigin stringByAppendingString:path]];
    parts.queryItems = query;
    NSMutableURLRequest *r = [NSMutableURLRequest requestWithURL:parts.URL];
    [r setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    if (token.length) [r setValue:[@"Bearer " stringByAppendingString:token] forHTTPHeaderField:@"Authorization"];
    if (body) {
        r.HTTPMethod = @"POST";
        [r setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        r.HTTPBody = [NSJSONSerialization dataWithJSONObject:body options:0 error:nil];
    }
    [[self.session dataTaskWithRequest:r completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        NSInteger status = [response isKindOfClass:NSHTTPURLResponse.class] ? ((NSHTTPURLResponse *)response).statusCode : 0;
        id json = nil;
        if (!error && data.length && data.length <= 8 * 1024 * 1024)
            json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
        if (data.length > 8 * 1024 * 1024) error = [NSError errorWithDomain:@"WBG" code:1 userInfo:nil];
        dispatch_async(dispatch_get_main_queue(), ^{ completion(json,status,error); });
    }] resume];
}
@end

@interface WBGWorkspaceController ()
@property(nonatomic,strong) WBGAPI *api;
@property(nonatomic,copy) NSString *token;
@property(nonatomic,strong) NSArray<NSDictionary *> *rows;
@property(nonatomic,strong) UITextField *username;
@property(nonatomic,strong) UITextField *password;
@property(nonatomic,strong) UILabel *status;
@property(nonatomic,strong) UIButton *login;
@property(nonatomic) NSUInteger generation;
@property(nonatomic) BOOL loggedIn;
@property(nonatomic,strong) NSDictionary *conversation;
@end

@implementation WBGWorkspaceController
- (instancetype)init { return [super initWithStyle:UITableViewStyleInsetGrouped]; }
- (void)dealloc { [self.api.session invalidateAndCancel]; }
- (void)viewDidLoad {
    [super viewDidLoad]; self.api = [WBGAPI new]; self.rows = @[];
    self.token = WBGToken(); self.title = @"הלקוחות שלי · בדיקה";
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"סגירה" style:UIBarButtonItemStylePlain target:self action:@selector(close)];
    [self showLogin];
    if (self.token.length) { self.status.text = @"בודק התחברות קיימת…"; [self validateSession]; }
}
- (void)close { self.generation++; [self.api.session invalidateAndCancel]; [self dismissViewControllerAnimated:YES completion:nil]; }
- (void)showLogin {
    self.loggedIn = NO; self.rows = @[]; self.conversation = nil;
    self.navigationItem.rightBarButtonItem = nil;
    self.username = [UITextField new]; self.username.placeholder = @"שם משתמש";
    self.username.autocapitalizationType = UITextAutocapitalizationTypeNone;
    self.username.autocorrectionType = UITextAutocorrectionTypeNo;
    self.username.textContentType = UITextContentTypeUsername;
    self.username.borderStyle = UITextBorderStyleRoundedRect;
    self.password = [UITextField new]; self.password.placeholder = @"סיסמה";
    self.password.secureTextEntry = YES; self.password.textContentType = UITextContentTypePassword;
    self.password.borderStyle = UITextBorderStyleRoundedRect;
    self.status = [UILabel new]; self.status.numberOfLines = 0; self.status.textAlignment = NSTextAlignmentCenter;
    self.status.font = [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
    self.status.text = @"התחברות לשרת שלך. Tailscale צריך להיות מחובר. זו תצוגה נפרדת מהצ׳אטים המקומיים של WhatsApp.";
    self.login = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.login setTitle:@"התחברות" forState:UIControlStateNormal];
    [self.login addTarget:self action:@selector(signIn) forControlEvents:UIControlEventTouchUpInside];
    UIStackView *stack = [[UIStackView alloc] initWithArrangedSubviews:@[self.username,self.password,self.login,self.status]];
    stack.axis = UILayoutConstraintAxisVertical; stack.spacing = 14;
    UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0,0,320,290)];
    [header addSubview:stack]; stack.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:@[[stack.leadingAnchor constraintEqualToAnchor:header.leadingAnchor constant:24],
      [stack.trailingAnchor constraintEqualToAnchor:header.trailingAnchor constant:-24],
      [stack.topAnchor constraintEqualToAnchor:header.topAnchor constant:24]]];
    self.tableView.tableHeaderView = header; [self.tableView reloadData];
}
- (void)error:(NSInteger)status error:(NSError *)error {
    self.login.enabled = YES;
    NSString *message = error ? @"לא ניתן להגיע לשרת. בדוק את Tailscale ואת החיבור." :
       (status == 401 ? @"ההתחברות אינה תקפה. בדוק שם משתמש וסיסמה." :
        (status == 429 ? @"יותר מדי ניסיונות. המתן ונסה שוב." : @"השרת אינו זמין כרגע. נסה שוב."));
    if (!self.loggedIn) self.status.text = message;
    else {
        UIAlertController *a = [UIAlertController alertControllerWithTitle:@"לא ניתן לטעון" message:message preferredStyle:UIAlertControllerStyleAlert];
        [a addAction:[UIAlertAction actionWithTitle:@"אישור" style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:a animated:YES completion:nil];
    }
}
- (void)signIn {
    NSString *user = [self.username.text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    NSString *pass = self.password.text ?: @"";
    if (!user.length || !pass.length) { self.status.text = @"יש להזין שם משתמש וסיסמה."; return; }
    self.login.enabled = NO; self.status.text = @"מתחבר…";
    NSUInteger generation = ++self.generation;
    [self.api request:@"/auth/login" query:nil body:@{@"username":user,@"password":pass} token:nil completion:^(id json, NSInteger code, NSError *error) {
        if (generation != self.generation) return;
        self.password.text = @""; self.login.enabled = YES;
        NSString *token = [json isKindOfClass:NSDictionary.class] ? WBGString(json[@"token"]) : @"";
        if (error || code != 200 || !token.length) { [self error:code error:error]; return; }
        if (!WBGSaveToken(token)) { self.status.text = @"לא ניתן לשמור התחברות באופן מאובטח."; return; }
        self.token = token; [self openWorkspace];
    }];
}
- (void)validateSession {
    NSUInteger generation = ++self.generation;
    [self.api request:@"/auth/me" query:nil body:nil token:self.token completion:^(id json, NSInteger code, NSError *error) {
        if (generation != self.generation) return;
        if (!error && code == 200 && [json isKindOfClass:NSDictionary.class]) [self openWorkspace];
        else {
            if (code == 401) { WBGSaveToken(@""); self.token = @""; }
            [self error:code error:error];
        }
    }];
}
- (void)openWorkspace {
    self.loggedIn = YES; self.tableView.tableHeaderView = nil;
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"התנתקות" style:UIBarButtonItemStylePlain target:self action:@selector(signOut)];
    self.refreshControl = [UIRefreshControl new];
    [self.refreshControl addTarget:self action:@selector(loadRows) forControlEvents:UIControlEventValueChanged];
    [self loadRows];
}
- (void)signOut {
    if (!WBGSaveToken(@"")) {
        UIAlertController *a = [UIAlertController alertControllerWithTitle:@"לא ניתן להתנתק" message:@"לא ניתן להסיר את ההתחברות השמורה. פתח את נעילת המכשיר ונסה שוב." preferredStyle:UIAlertControllerStyleAlert];
        [a addAction:[UIAlertAction actionWithTitle:@"אישור" style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:a animated:YES completion:nil]; return;
    }
    self.generation++; NSString *old = self.token;
    // Fail closed locally even when the server is temporarily unreachable.
    self.token = @""; self.refreshControl = nil;
    self.title = @"הלקוחות שלי · בדיקה"; [self showLogin];
    [self.api request:@"/auth/logout" query:nil body:@{} token:old completion:^(id json, NSInteger code, NSError *error) {}];
}
- (void)loadRows {
    if (!self.loggedIn || !self.token.length) return;
    NSUInteger generation = ++self.generation;
    NSArray *query = nil; NSString *path = @"/conversations";
    if (self.conversation) {
        path = @"/messages-v2";
        NSString *account = WBGString(self.conversation[@"account_id"]);
        query = @[[NSURLQueryItem queryItemWithName:@"chat_jid" value:WBGString(self.conversation[@"jid"])],
                  [NSURLQueryItem queryItemWithName:@"account_id" value:account.length ? account : @"default"]];
    }
    [self.api request:path query:query body:nil token:self.token completion:^(id json, NSInteger code, NSError *error) {
        if (generation != self.generation) return;
        [self.refreshControl endRefreshing];
        if (code == 401) { WBGSaveToken(@""); self.token = @""; self.refreshControl = nil; [self showLogin]; return; }
        if (error || code != 200 || ![json isKindOfClass:NSArray.class]) { [self error:code error:error]; return; }
        NSMutableArray *rows = [NSMutableArray new];
        for (id row in json) if ([row isKindOfClass:NSDictionary.class]) [rows addObject:row];
        self.rows = rows; [self.tableView reloadData];
    }];
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section { return self.rows.count; }
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:nil];
    NSDictionary *row = self.rows[indexPath.row];
    if (self.conversation) {
        NSString *text = WBGString(row[@"text"]);
        cell.textLabel.text = text.length ? text : [NSString stringWithFormat:@"[%@]",WBGString(row[@"type"])];
        cell.detailTextLabel.text = [row[@"from_me"] respondsToSelector:@selector(boolValue)] && [row[@"from_me"] boolValue] ? @"אתה" : @"לקוח";
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    } else {
        NSString *name = WBGString(row[@"name"]);
        cell.textLabel.text = name.length ? name : WBGString(row[@"jid"]);
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ · %@",WBGString(row[@"account_id"]),WBGString(row[@"last_message"])];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    cell.textLabel.numberOfLines = 0; cell.detailTextLabel.numberOfLines = 2;
    return cell;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.conversation) return;
    self.conversation = self.rows[indexPath.row]; self.rows = @[];
    self.title = WBGString(self.conversation[@"name"]);
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"צ׳אטים" style:UIBarButtonItemStylePlain target:self action:@selector(back)];
    [self.tableView reloadData]; [self loadRows];
}
- (void)back {
    self.conversation = nil; self.rows = @[]; self.title = @"הלקוחות שלי · בדיקה";
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"סגירה" style:UIBarButtonItemStylePlain target:self action:@selector(close)];
    [self.tableView reloadData]; [self loadRows];
}
@end
