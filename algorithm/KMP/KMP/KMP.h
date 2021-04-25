//
//  KMP.h
//  KMP
//
//  Created by disen zhang on 2021/4/17.
//

#ifndef KMP_h
#define KMP_h

#include <iostream>
#include <stdlib.h>


void init_next(string pattern, int next[]) {
    
    unsigned long len = pattern.length();
    next[0] = 0;
    
    for(int i = 1,k = 0; i < len; i++) {
        while(k > 0 && pattern[k] != pattern[i]) {
            k = next[k - 1];
        }
        
        if(pattern[k] == pattern[i]) {
            k ++;
        }
        
        next[i] = k;
    }
}

bool search(string content, string pattern) {
    
    int next[pattern.length()];
    init_next(pattern, next);
    
    int i = 0;
    while (i <= content.length() - pattern.length()) {
        
        int j = 0;
        for (; j < pattern.length(); j ++) {
            if (pattern[j] == content[i + j]) {
                continue;
            }
            
            int jump = j - next[j - 1];
            i += MAX(jump, 1);;
            break;
        }
        
        if (j == pattern.length()) {
            return true;
        }
    }
    
    return false;
}



#endif /* KMP_h */
