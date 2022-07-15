//
//  Client.c
//  ServerTest
//
//  Created by disen zhang on 2022/6/8.
//

#include "Client.h"
#include <arpa/inet.h>
#include <stdio.h>
#include <string.h>
#include <sys/socket.h>
#include <unistd.h>
#include "errno.h"
#include <vector>

#define FD_CAN_READ 1
#define FD_CAN_WRITE 1 << 1
#define FD_ERROR 1 << 2
#define MG_F_CONNECTING (1 << 3)         /* connect() call in progress */

#ifndef INVALID_SOCKET
#  define INVALID_SOCKET (-1)
#endif


std::vector<int> g_clfds;

void closeConnect(void) {
    for (auto s = g_clfds.begin(); s != g_clfds.end(); s++) {
        int sock = *s;
        shutdown(sock, SHUT_RDWR);
        close(sock);
    }
    
    printf("程序退出\n");
}


int startConnect(int port) {
    int sock = socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);
    if (sock < 0) {
        printf("Socket:%d Create Error\n", sock);
        return -1;
    }
    
    int r = 1;
    setsockopt(sock, SOL_SOCKET, SO_NOSIGPIPE, &r, sizeof(int));
    
    int timeoutMs = 1000;
    __darwin_time_t tv_sec = timeoutMs / 1000;
    __darwin_suseconds_t tv_usec = (timeoutMs % 1000) * 1000;
    struct timeval tv = {tv_sec, tv_usec};
    setsockopt(sock, SOL_SOCKET, SO_SNDTIMEO, &tv, sizeof(tv));
    setsockopt(sock, SOL_SOCKET, SO_RCVTIMEO, &tv, sizeof tv);
    
    struct in_addr addr;
    addr.s_addr = 0;
    inet_pton(AF_INET, "127.0.0.1", &addr);

    struct sockaddr_in to = {0};
    to.sin_addr.s_addr = addr.s_addr;
    to.sin_port = htons(port);
    to.sin_family = AF_INET;
    
    long rc = connect(sock, (struct sockaddr*)&to,sizeof(to));
    if (rc < 0) {
        printf("Socket:%d Connect Failed\n", sock);
        return -1;
    }
    
    g_clfds.push_back(sock);
    return sock;
}

void client_read_data_from_socket(int sockfd) {
    char recv_data[1024] = {0};
    long rc = recv(sockfd, recv_data, sizeof(recv_data), 0);
    if (rc <= 0) {
        printf("Client Read Failed cs:%ld\n", rc);
        return;
    }

    printf("Client Socket acc:%d revc:%s\n", sockfd, recv_data);
}

long send_data_from_socket(int socket) {
    char buf[1024] = {0};
    const size_t buf_size = sizeof(buf) - 1;
    snprintf(buf, buf_size, "Client Send Data From Socket:%d", socket);
    long sendLen = send(socket, buf, strlen(buf), 0);
    if (sendLen == 0) {
        printf("Send Failed\n");
    }
    
    return sendLen;
}

long sendMsgWithLastConnect(void) {
    int seq =  (int)g_clfds.size() - 1;
//    int seq = (int)random() % g_clfds.size();
    int socket = g_clfds[seq];
    long sendLen = send_data_from_socket(socket);
    printf("Client Seq:%d Socket:%d Send Data\n", seq, socket);
    
    return sendLen;
}


extern void mg_add_to_set(int sock, fd_set *set, int *max_fd);

void select_clientmsg(void) {
    int milli = 1500;
    struct timeval tv;
    tv.tv_sec = milli / 1000;
    tv.tv_usec = (milli % 1000) * 1000;
    
    fd_set read_set, write_set, err_set;
    FD_ZERO(&read_set);
    FD_ZERO(&write_set);
    FD_ZERO(&err_set);
    
    int max_fd = INVALID_SOCKET;
    
    for (auto sock = g_clfds.begin(); sock != g_clfds.end(); sock++) {
        mg_add_to_set(*sock, &write_set, &max_fd);
        mg_add_to_set(*sock, &read_set, &max_fd);
        mg_add_to_set(*sock, &err_set, &max_fd);
    }
    
    
    int num_selected = select((int) max_fd + 1, &read_set, &write_set, &err_set, &tv);
    if (num_selected <= 0) {
        return;
    }
    
    printf("select num_ev=%d\n", num_selected);
    
    for (auto s = g_clfds.begin(); s != g_clfds.end(); s++) {
        int sock = *s;
        
        if (FD_ISSET(sock, &read_set)) {
            client_read_data_from_socket(sock);
            continue;
        }
        
        if (FD_ISSET(sock, &err_set)) {
            printf("select:%d error", sock);
            continue;
        }
    }
}
