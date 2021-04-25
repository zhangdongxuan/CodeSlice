//
//  main.m
//  Aho–Corasic
//
//  Created by disen zhang on 2021/3/19.
//

#import <Foundation/Foundation.h>
#include "ACAutomaton.h"
#include <iostream>
#include <stdlib.h>


int main(int argc, const char * argv[]) {
    @autoreleasepool {
        
        vector<string> list;
        list.push_back("abcdef");
        list.push_back("abhab");
        list.push_back("bcd");
        list.push_back("cde");
        list.push_back("cdfkcdf");
        
        ACAutomaton *ac_automaton = new ACAutomaton(list);
        
        string text = "bcabcdebcedfabcdefababkabhabk";
        map<string, int> keywords = ac_automaton->find(text);
        
        map<string, int>::iterator iterator = keywords.begin();
        while (iterator != keywords.end()) {
            string keyword = iterator->first;
            int index = iterator->second;
            printf("%s:%d\n", keyword.c_str(), index);
            
            iterator ++;
        }
    }
    
    return 0;
}
