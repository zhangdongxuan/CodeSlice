#include <stdio.h>
#include <stdlib.h>
#include "Server.h"

void on_exit(void)
{
    //do something when process exits
    exit_server();
    printf("on_exit\n");
}

int main(int argc, char * argv[]) {
    if (argc != 2) {
        printf("please add port\n");
        return 0;
    }
    
    atexit(on_exit);

    int port = atoi(argv[1]);
    printf("port:%d\n", port);
    int ret = start_server(port);
    if (ret < 0) {
        printf("server start fail\n");
        return 0;
    }

    accept_client_conn();
    
    return 0;
}

