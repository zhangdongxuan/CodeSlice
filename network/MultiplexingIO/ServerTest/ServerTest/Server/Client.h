//
//  Client.h
//  ServerTest
//
//  Created by disen zhang on 2022/6/8.
//

#ifndef Client_h
#define Client_h

#if defined(__cplusplus)
extern "C" {
#endif

#include <stdio.h>

int startConnect(int port);
void closeConnect();
long sendMsgWithLastConnect(void);
void select_clientmsg(void);

#if defined(__cplusplus)
}
#endif

#endif /* Client_h */


