#include <stdio.h>
#include <stdlib.h>
#include "Client.h"

void on_exit(void) {
    //do something when process exits
    close_connect();
}

int main(int argc, char * argv[]) {
    if (argc != 2) {
        printf("please add port\n");
        return 0;
    }

    atexit(on_exit);
    int port = atoi(argv[1]);
    printf("port:%d\n", port);

    start_connect("127.0.0.1", port);
    
    return 0;
}

