//
//  main.m
//  KMP
//
//  Created by disen zhang on 2021/3/21.
//

#import <Foundation/Foundation.h>
#include <string>
#include "KMP.h"

using namespace std;

bool contain_force(string word, string keyword) {
    for (int i = 0; i <= word.length() - keyword.length(); i ++) {
        for (int j = 0; j < keyword.length(); j ++) {
            char ch = word[i + j];
            char k_ch = keyword[j];
            if (ch != k_ch) {
                break;
            }
            
            if (j == keyword.length() -1) {
                return true;
            }
        }
    }
    
    return false;
}

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        
        bool contain = contain_force("I am a iOS coder, I can write good style oc code", "write");
        printf("contain:%u\n", contain);
        
        bool exist = search("ABCDABCDABDE", "ABCDABD");
        printf("kmp search exist:%u\n", exist);
    }
    return 0;
}
