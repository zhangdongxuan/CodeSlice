//
//  DoubleArrayTrie.hpp
//  DAT
//
//  Created by disen zhang on 2021/3/26.
//

#ifndef DoubleArrayTrie_hpp
#define DoubleArrayTrie_hpp

#include <stdio.h>
#include <string>
#include <vector>
#include <deque>
#include <unordered_map>

using namespace std;

typedef struct Siblings {
    int code;
    int col;
    wstring cur;
    wstring keyword;
} Node;

typedef unordered_map<wstring, vector<Node>> siblings_def;

class DoubleArrayTrie {

private:
    
    int char_num = 0;
    int alloc_size = 5000;
    int num_words = 0;
    
    vector<wstring> segments;
    vector<int> base;
    vector<int> check;
    
    unordered_map<int, int> output;
    unordered_map<wstring, int> vocab;
    
public:
    DoubleArrayTrie();
    void add_keyword(string keyword);
    void build_tree();
    bool search(string keyword);
    int get_parent_state(Node node);
    int get_begin(vector<Node> siblings);
    void fetch_first_siblings (deque<vector<Node>> &queue);
    void fetch_siblings(deque<vector<Node>> &queue, vector<Node> node);
};

#endif /* DoubleArrayTrie_hpp */
