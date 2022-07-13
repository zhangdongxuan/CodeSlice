//
//  Client.c
//  ServerTest
//
//  Created by disen zhang on 2022/6/8.
//

#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <sys/socket.h>
#include <netinet/in.h>

static int g_svfd;

long send_data_to_socket(int socket) {
    char buf[1024] = {0};
    const size_t buf_size = sizeof(buf) - 1;
    snprintf(buf, buf_size, "Server Have Revc Your Connect, Bye.");
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

    printf("Server Revc:%s from sockfds:%d\n", recv_data, sockfd);
}


void exit_server(void) {
    shutdown(g_svfd, SHUT_RDWR);
    close(g_svfd);
    printf("close server socket:%d\n", g_svfd);
}


int start_server(int port) {
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

    printf("server start with port:%d fd:%d\n", port, g_svfd);
    
    return g_svfd;
}

int accept_client_conn(void) {
    int sockfd = accept(g_svfd, NULL, NULL);
    if (sockfd < 0) {
        perror("accept");
        return -1;
    }

    read_data_from_socket(sockfd);
    send_data_to_socket(sockfd);

    shutdown(sockfd, SHUT_RDWR);
    close(sockfd);

    return sockfd;
}