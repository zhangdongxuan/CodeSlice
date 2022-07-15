//
//  ViewController.m
//  ServerTest
//
//  Created by disen zhang on 2022/6/8.
//

#import "ViewController.h"
#include "Server.h"
#include "Client.h"

#define STEP_COUNT 256

int localServerPort;

@interface ViewController ()

@property(nonatomic, strong) NSMutableArray *arrFileHandle;


@end

@implementation ViewController

- (CGFloat)addButton:(NSString *)title  origin:(CGPoint)point action:(SEL)action {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button setTitle:title forState:UIControlStateNormal];
    button.backgroundColor = UIColor.darkGrayColor;
    [button sizeToFit];
    button.frame = CGRectMake(point.x, point.y, button.frame.size.width + 16, button.frame.size.height);
    [button addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:button];
    
    return point.x + button.frame.size.width;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.arrFileHandle = [NSMutableArray array];
    [self updateRlimit];
    
    UILabel *lable = [[UILabel alloc] init];
    lable.text = @"server:";
    lable.textColor = UIColor.blackColor;
    lable.font = [UIFont systemFontOfSize:16];
    [lable sizeToFit];
    lable.frame = CGRectMake(30, 100, lable.frame.size.width, lable.frame.size.height);
    [self.view addSubview:lable];
    
    CGFloat right = [self addButton:@"start " origin:{60, 140} action:@selector(onStartServer) ];
    right =  [self addButton:@"创建句柄 " origin:{right + 12, 140} action:@selector(onClickOpenFileButton) ];
    right = [self addButton:@"start select " origin:{60, 185} action:@selector(onStartServerSelect) ];
    right = [self addButton:@"stop select " origin:{right + 12, 185} action:@selector(onStopServerSelect) ];
    right =[self addButton:@"start poll " origin:{60, 230} action:@selector(onStartServerPoll) ];
    right = [self addButton:@"stop poll " origin:{right + 12, 230} action:@selector(onStopServerPoll) ];
    right = [self addButton:@"send data " origin:{right + 12, 230} action:@selector(onSendDataToClient) ];
    
    lable = [[UILabel alloc] init];
    lable.text = @"client:";
    lable.textColor = UIColor.blackColor;
    lable.font = [UIFont systemFontOfSize:16];
    [lable sizeToFit];
    lable.frame = CGRectMake(30, 290, lable.frame.size.width, lable.frame.size.height);
    [self.view addSubview:lable];

    right = [self addButton:@"connect " origin:{60, 330} action:@selector(onStartConnect) ];
    right = [self addButton:@"send data " origin:{right + 12, 330} action:@selector(onSendDataToServer) ];
    right = [self addButton:@"select " origin:{right + 12, 330} action:@selector(onClientStartSelect) ];
    

    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationWillTerminateNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull note) {
        onExit();
        closeConnect();
    }];
}


#pragma - mark Server
- (void)onStartServer {
    localServerPort = random() % 10000 + 10000;
    int serverSocket = startServer(localServerPort);
    while (serverSocket < 0) {
        localServerPort = random() % 10000 + 10000;
        serverSocket = startServer(localServerPort);
    }
    
    NSLog(@"server start socket:%d port:%d", serverSocket, localServerPort);
}

- (void)onStartServerSelect {
    NSLog(@"开始 server select");
    select_servermsg();
}

- (void)onStopServerSelect {
    NSLog(@"stop server select");
    stop_serverselect();
}

- (void)onStartServerPoll {
    NSLog(@"开始 server poll");
    poll_servermsg();
}

- (void)onStopServerPoll {
    NSLog(@"stop server poll");
    stop_serverpolling();
}

- (void)onSendDataToClient {
    NSLog(@"server send data click");
    sendMsgToRandomClient();
}

- (void)onClickOpenFileButton {
    NSString *path = [[NSBundle mainBundle] pathForResource:@"readme" ofType:@"txt"];
    for (int i = 0; i < STEP_COUNT; i ++) {
        int fd = open(path.UTF8String, O_RDONLY, S_IRUSR | S_IWUSR);
        [self.arrFileHandle addObject:@(fd)];
        NSLog(@"open file fd:%d", fd);
    }
}

#pragma - mark Client
- (void)onStartConnect {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        for (int i = 0; i < 1; i++) {
            int socket = startConnect(localServerPort);
            NSLog(@"client connected socket:%d", socket);
        }
    });
}

- (void)onSendDataToServer {
    printf("----------------client send data click-------------------------\n");
    sendMsgWithLastConnect();
}

- (void)onClientStartSelect {
    NSLog(@"开始 client select");
    select_clientmsg();
}

- (void)updateRlimit {
    NSString *exeName = [[NSBundle mainBundle] infoDictionary][@"CFBundleExecutable"]; // 其实这个结果就是 @"WeChat"
    NSString *exePath = [[NSBundle mainBundle] pathForResource:exeName ofType:@""];
    NSFileHandle *fileHandle = [NSFileHandle fileHandleForReadingAtPath:exePath];
    [fileHandle closeFile];

    struct rlimit rlim;

    if (getrlimit(RLIMIT_NOFILE, &rlim) < 0) {
        NSLog(@"unable to getrlimit");
    } else {
        NSLog(@"getrlimit result:%llu", rlim.rlim_cur);
    }

    if (rlim.rlim_cur < 2560) {
        rlim.rlim_cur = 2560;
        if (setrlimit(RLIMIT_NOFILE, &rlim) < 0) {
            NSLog(@"unable to setrlimit");
        } else {
            NSLog(@"finish setrlimit");
        }
    }
}

@end
