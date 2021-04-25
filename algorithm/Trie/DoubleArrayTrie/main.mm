//
//  main.m
//  DoubleArrayTrie
//
//  Created by disen zhang on 2021/3/24.
//

#import <Foundation/Foundation.h>
#include "double_array_trie.h"

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        // insert code here...
        NSLog(@"Hello, World!");
        
        DoubleArrayTrie dat;
        dat.load_file("/Users/disenzhang/Projects/Xcode/CodeSlice/Leetcode/fs_kw_main.txt");
        dat.make();
        
        // greedy_search
        vector<string> index_s = dat.acsearch("2021年3月27日，ceo交易所发生了一起一场梦一场空");
        
        // load from file
//        dat.load_file("/Users/disenzhang/Desktop/fs_kw_main.txt");
        // or add word
        
//        dat.add_word("he");
//        dat.add_word("her");
//        dat.add_word("she");
//        dat.add_word("shit");
//        dat.make();
//        vector<string> index_s = dat.search("ushers");
        
        for (int i = 0; i < index_s.size(); i++) {
            printf("%s\n", index_s[i].c_str());
        }
        
        // maximum_search
//        vector<string> index_s = dat.maximum_search("ushers");
    }
    return 0;
}
