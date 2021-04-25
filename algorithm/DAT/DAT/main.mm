//
//  main.m
//  DAT
//
//  Created by disen zhang on 2021/3/24.
//

#import <Foundation/Foundation.h>
#include "DoubleArrayTrie.hpp"

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        
        DoubleArrayTrie trie;
        trie.add_keyword("he");
        trie.add_keyword("she");
        
        string arr[] = {"hello", "world", "coder", "ios", "iPhone", "Xcode", "OS"};
        int count = sizeof(arr) / sizeof(arr[0]);
        for (int i = 0; i < count; i++) {
            trie.add_keyword(arr[i]);
        }
        
        trie.build_tree();
        bool exist = trie.search("xcode");
        printf("exist:%u\n", exist);
        
    }
    return 0;
}
