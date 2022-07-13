//
//  Client.c
//  ServerTest
//
//  Created by disen zhang on 2022/6/8.
//

#include "Client.h"
#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>

static int g_socket;

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


void close_connect() {
    shutdown(g_socket, SHUT_RDWR);
    close(g_socket);
    printf("close server socket:%d\n", g_socket);
}

int start_connect(const char *ip, int port) {
    g_socket = socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);
    if (g_socket < 0) {
        printf("Socket:%d Create Error\n", g_socket);
        return -1;
    }
    
    int r = 1;
    setsockopt(g_socket, SOL_SOCKET, SO_NOSIGPIPE, &r, sizeof(int));
    
    // int timeoutMs = 100000;
    // __darwin_time_t tv_sec = timeoutMs / 1000;
    // __darwin_suseconds_t tv_usec = (timeoutMs % 1000) * 1000;
    // struct timeval tv = {tv_sec, tv_usec};
    // setsockopt(g_socket, SOL_SOCKET, SO_SNDTIMEO, &tv, sizeof(tv));
    // setsockopt(g_socket, SOL_SOCKET, SO_RCVTIMEO, &tv, sizeof tv);
    
    struct in_addr addr;
    addr.s_addr = 0;
    inet_pton(AF_INET, ip, &addr);

    struct sockaddr_in to = {0};
    to.sin_addr.s_addr = addr.s_addr;
    to.sin_port = htons(port);
    to.sin_family = AF_INET;
    
    long rc = connect(g_socket, (struct sockaddr*)&to,sizeof(to));
    if (rc < 0) {
        printf("Socket:%d Connect Failed\n", g_socket);
        return -1;
    }


    send_data_from_socket(g_socket);
    client_read_data_from_socket(g_socket);

    return g_socket;
}
