//
//  Server.c
//  ServerTest
//
//  Created by disen zhang on 2022/6/8.
//

#include "Server.h"
#include <netinet/in.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/socket.h>
#include <unistd.h>
#include <netinet/tcp.h>
#include <fcntl.h>
#include <sys/stat.h>
#include <time.h>
#include <vector>
#include "poll.h"

#define FD_CAN_READ 1
#define FD_CAN_WRITE 1 << 1
#define FD_ERROR 1 << 2
#define MG_F_CONNECTING (1 << 3)         /* connect() call in progress */

#ifndef INVALID_SOCKET
#  define INVALID_SOCKET (-1)
#endif

#ifndef POLL_MAX_EVENTS
#define POLL_MAX_EVENTS 1024
#endif

static int g_svfd;
std::vector<int> g_fds;
pthread_t select_thread;
pthread_t poll_thread;

static bool g_selecting;
static bool g_polling;


void onExit(void) {
    for (auto s = g_fds.begin(); s != g_fds.end(); s++) {
        int sock = *s;
        shutdown(sock, SHUT_RDWR);
        close(sock);
    }
    
    printf("程序退出\n");
}

int startServer(int port) {
    struct sockaddr_in address;
    address.sin_family = AF_INET;
    address.sin_addr.s_addr = INADDR_ANY;
    address.sin_port = htons(port);
    
    
    // Creating socket file descriptor
    if ((g_svfd = socket(AF_INET, SOCK_STREAM, 0)) == 0) {
        printf("socket failed\n");
        return -1;
    }

    // Forcefully attaching socket to the port 8080
    int opt = 1;
    int ret = setsockopt(g_svfd, SOL_SOCKET, SO_KEEPALIVE, &opt, sizeof(opt));
    if (ret != 0) {
        perror("setsockopt");
        close(g_svfd);
        return -2;
    }
    
    // Forcefully attaching socket to the port 8080
    if (bind(g_svfd, (struct sockaddr*)&address, sizeof(address)) < 0) {
        perror("bind");
        close(g_svfd);
        return -3;
    }
    
    if (listen(g_svfd, SOMAXCONN) < 0) {
        perror("listen");
        close(g_svfd);
        return -4;
    }
    
    g_fds.push_back(g_svfd);
    return g_svfd;
}


void mg_add_to_set(int sock, fd_set *set, int *max_fd) {
    if (sock != INVALID_SOCKET && sock < (int) FD_SETSIZE) {
        FD_SET(sock, set);
        if (*max_fd == INVALID_SOCKET || sock > *max_fd) {
            *max_fd = sock;
        }
    }
}

int accept_client_conn(void) {
    int cs = accept(g_svfd, NULL, NULL);
    if (cs < 0) {
        perror("accept");
        return -1;
    }
    
    g_fds.push_back(cs);
    printf("Server Accept acc:%d\n", cs);
    return cs;
}

long send_data_to_socket(int socket) {
    char buf[1024] = {0};
    const size_t buf_size = sizeof(buf) - 1;
    snprintf(buf, buf_size, "Server Wirte Data To Socket:%d", socket);
    long sendLen = send(socket, buf, strlen(buf), 0);
    if (sendLen == 0) {
        printf("Send Failed\n");
    }
    
    return sendLen;
}

void read_data_from_socket(int sockfd) {
    char recv_data[1024] = {0};
    long rc = recv(sockfd, recv_data, sizeof(recv_data), 0);
    if (rc <= 0) {
        printf("Server Read Failed cs:%ld\n", rc);
        return;
    }

    printf("Server Socket acc:%d revc:%s \n", sockfd, recv_data);
}

void *server_select(void *udata) {
    g_selecting = true;
    while (g_selecting) {
        int milli = 1500;
        struct timeval tv;
        tv.tv_sec = milli / 1000;
        tv.tv_usec = (milli % 1000) * 1000;
        
        fd_set read_set, err_set;
        FD_ZERO(&read_set);
        FD_ZERO(&err_set);
        
        //    https://stackoverflow.com/questions/36415680/setting-up-select-and-write-fds-in-c
        int max_fd = INVALID_SOCKET;
        
        for (auto sock = g_fds.begin(); sock != g_fds.end(); sock++) {
            mg_add_to_set(*sock, &read_set, &max_fd);
            mg_add_to_set(*sock, &err_set, &max_fd);
        }
        
        
        int num_selected = select((int) max_fd + 1, &read_set, NULL, &err_set, &tv);
        if (num_selected <= 0) {
            continue;
        }
        
        unsigned long size = g_fds.size();
        for (int i = 0; i < size; i++) {
            int sock = g_fds[i];
            
            if (FD_ISSET(sock, &read_set)) {
                if (sock == g_svfd) {
                    accept_client_conn();
                } else {
                    read_data_from_socket(sock);
                }
                
                continue;
            }
            
            if (FD_ISSET(sock, &err_set)) {
                printf("select:%d error\n", sock);
                continue;
            }
        }
    }
    
    return NULL;
}

void select_servermsg(void) {
    pthread_attr_t attr;
    (void)pthread_attr_init(&attr);
    pthread_create(&select_thread, &attr, server_select, NULL);
    pthread_attr_destroy(&attr);
}

void stop_serverselect(void) {
    g_selecting = false;
}

//  https://www.ibm.com/docs/en/i/7.4?topic=designs-using-poll-instead-select
void *server_poll(void *udata) {
    g_polling = true;
    while (g_polling) {
        int32_t maxsock = 0;
        unsigned long fd_size = g_fds.size() * sizeof(pollfd);
        struct pollfd *pollfds = (struct pollfd *)malloc(fd_size);
        
        for (auto sock = g_fds.begin(); sock != g_fds.end(); sock++) {
            pollfds[maxsock].fd = *sock;
            pollfds[maxsock].events = POLLIN;
            ++maxsock;
        }
        
        int rc = poll(pollfds, maxsock, 10);
        if (rc < 0) {
            continue;;
        }
        
        for (int j = 0; j < maxsock; j++) {
            if (pollfds[j].revents & POLLIN) {
                int socket = pollfds[j] .fd;
                if (socket == g_svfd) {
                    accept_client_conn();
                } else {
                    read_data_from_socket(socket);
                }
            }
        }
    }
    
    return NULL;
}

void poll_servermsg(void) {
    pthread_attr_t attr;
    (void)pthread_attr_init(&attr);
    pthread_create(&poll_thread, &attr, server_poll, NULL);
    pthread_attr_destroy(&attr);
}

void stop_serverpolling(void) {
    g_polling = false;
}

int sendMsgToRandomClient(void) {
    int seq = (int)random() % g_fds.size();
    int socket = g_fds[seq];
    send_data_to_socket(socket);
    printf("Server Seq:%d Socket:%d Send Data\n", seq, socket);
    
    return 0;
}
