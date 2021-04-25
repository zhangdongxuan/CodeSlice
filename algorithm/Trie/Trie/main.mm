//
//  main.m
//  Trie
//
//  Created by disen zhang on 2021/3/17.
//

#import <Foundation/Foundation.h>
#include "Trie.hpp"

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        
        
        Trie *trie = new Trie();
        
        string arr[] = {"hello", "world", "coder", "ios", "iPhone", "Xcode", "OS"};
        int count = sizeof(arr) / sizeof(arr[0]);
        for (int i = 0; i < count; i++) {
            trie->insert(arr[i]);
        }
        
        trie->print_all_keyword();
        
        bool exist = trie->search("OS");
        printf("OS exist:%d\n", exist);
        
        trie->remove("OS");
        
        exist = trie->search("OS");
        printf("after rm OS exist:%d\n", exist);
        
        trie->print_all_keyword();
        
        exist = trie->search("Xcode");
        printf("Xcode exist:%d\n", exist);
        
        trie->remove_keyword("Xcode");
        exist = trie->search("Xcode");
        printf("after rm Xcode exist:%d\n", exist);
        
        trie->print_all_keyword();
    }
    return 0;
}
