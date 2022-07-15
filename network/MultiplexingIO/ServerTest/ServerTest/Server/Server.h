//
//  Server.h
//  ServerTest
//
//  Created by disen zhang on 2022/6/8.
//

#ifndef Server_h
#define Server_h

#if defined(__cplusplus)
extern "C" {
#endif

#include <stdio.h>

int startServer(int port);
void onExit(void);

void poll_servermsg(void) ;
void poll_servermsg(void);
void select_servermsg(void);

void stop_serverselect(void);
void stop_serverpolling(void);

int sendMsgToRandomClient(void);

#if defined(__cplusplus)
}
#endif

#endif /* Server_h */
