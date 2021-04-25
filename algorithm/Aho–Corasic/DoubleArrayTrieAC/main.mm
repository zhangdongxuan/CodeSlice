//
//  main.m
//  DoubleArrayTrieAC
//
//  Created by disen zhang on 2021/3/28.
//

#import <Foundation/Foundation.h>
#include "DoubleArrayTrie.hpp"

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        // insert code here...
        NSLog(@"Hello, World!");
        UInt16 test = 0 - 1;
        
        NSString *keyword =  @"微信读书";
        NSUInteger hash = keyword.hash;
        UInt32 tt = 13493432372;
        
        DoubleArrayTrie dat;
        
        dat.load_file("/Users/disenzhang/Projects/Tencent/CodeSlice/Leetcode/fs_kw_main.txt");
//        dat.add_keyword("he");
//        dat.add_keyword("her");
//        dat.add_keyword("she");
//        dat.add_keyword("his");
        // make base & check
        dat.build_tree();
        // greedy_search
        
        vector<string> index_s = dat.acsearch("ushers");
//        vector<string> index_s = dat.acsearch("e织独绣");
//        vector<string> index_s = dat.acsearch("在港股中石油真的是e织独绣啊，在纳斯达克也不错韩国国民银行不挺好的腾讯视频啊啊啊");
        
        for (int i = 0; i < index_s.size(); i++) {
            printf("%s\n", index_s[i].c_str());
        }
        
        NSLog(@"Hello, World!");
    }
    return 0;
}
