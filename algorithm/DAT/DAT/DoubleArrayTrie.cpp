//
//  DoubleArrayTrie.cpp
//  DAT
//
//  Created by disen zhang on 2021/3/26.
//

#include "DoubleArrayTrie.hpp"
#include "utils.h"

DoubleArrayTrie::DoubleArrayTrie() {
    base = vector<int> (alloc_size, 0);
    check = vector<int> (alloc_size, 0);
}

void DoubleArrayTrie::add_keyword(string keyword) {
    wstring skw = string_to_wstring(keyword);
    segments.push_back(skw);
}


void DoubleArrayTrie::build_tree() {
    printf("build tree\n");
    
    deque<vector<Node>> queue;
    fetch_first_siblings(queue);
    
    while (queue.empty() == false) {
        
        vector<Node> siblings = queue.front();
        queue.pop_front();
        fetch_siblings(queue, siblings);
        int begin = get_begin(siblings);
        for(Node node : siblings) {
            int s = get_parent_state(node);
            check[begin + node.code] = s;
            base[s] = begin;
        }
    }
    
    for (int i = 0; i < segments.size(); i ++) {
        wstring keyword = segments[i];
        wstring word = wstring(1, keyword[0]);
        int pcode = vocab[word];
        
        for (int i = 1; i < keyword.size(); i++) {
            word = wstring(1, keyword[i]);
            int code = vocab[word];
            pcode = abs(base[pcode]) + code;
        }
        
        if (base[pcode] > 0) {
            base[pcode] = - base[pcode];
        } else if (base[pcode] == 0) {
            base[pcode] = -1;
        }
        
        output[pcode] = i;
    }
}

bool DoubleArrayTrie::search(string keyword) {
    wstring skw = string_to_wstring(keyword);
    wstring word = wstring(1, skw[0]);
    int pcode = vocab[word];
    
    for (int i = 1; i < skw.length(); i ++) {
        word = wstring(1, skw[i]);
        int pos = base[pcode] + vocab[word];
        if (check[pos] != pcode) {
            return false;
        }
        
        pcode = pos;
    }
    
    if (base[pcode] < 0) {
        return true;
    }
    
    return  false;
}

int DoubleArrayTrie::get_parent_state(Node node) {
    wstring word = wstring(1, node.keyword[0]);
    int code = vocab[word];
    int p = code;
    
    for (int i = 1; i < node.col; i++) {
        word = wstring(1, node.keyword[i]);
        code = vocab[word];
        p = base[p] + code;
    }
    
    return p;
}

int DoubleArrayTrie::get_begin(vector<Node> siblings) {
    int begin = 1;
    
    while (true) {
        bool is_found = true;
        for (int i = 0; i < siblings.size(); i ++) {
            Node node = siblings[i];
            if (base[begin + node.code] != 0 || check[begin + node.code] != 0) {
                is_found = false;
                break;
            }
        }
        
        if (is_found == false) {
            begin ++;
        } else {
            return begin;
        }
    }

    return 0;
}

/**
 [S] ————C———> [SC]
 
 base[S] + C = SC
 check[SC] = S
 
 */

void DoubleArrayTrie::fetch_first_siblings (deque<vector<Node>> &queue) {
    siblings_def siblings;
    
    for (int i = 0; i < segments.size(); i ++) {
        wstring keyword = segments[i];
        
        wstring prefix = wstring(1, keyword[0]);
        if (vocab[prefix] == 0) {
            vocab[prefix] = char_num ++;
        }
        
        int pcode = vocab[prefix];
        
        check[pcode] = -1;
        
        if (keyword.size() == 1) { continue; }
        
        wstring cur = wstring(1, keyword[1]);
        if (vocab[cur] == 0) {
            vocab[cur] = char_num ++;
        }
        
        Node node;
        node.keyword = keyword;
        node.cur = cur;
        node.code = vocab[cur];
        node.col = 1;
        
        siblings[prefix].push_back(node);
    }
    
    
    for (auto it = siblings.begin(); it != siblings.end(); it ++) {
        queue.push_back(it->second);
    }
}

void DoubleArrayTrie::fetch_siblings(deque<vector<Node>> &queue, vector<Node> nodes) {
    siblings_def siblings;
    for (int i = 0; i < nodes.size(); i ++) {
        Node node = nodes[i];
        wstring keyword = node.keyword;
        if (node.col + 1 >= keyword.size()) {
            continue;
        }
        
        wstring cur = wstring(1, keyword[node.col + 1]);
        if (vocab[cur] == 0) {
            vocab[cur] = char_num ++;
        }
        
        Node next_node;
        next_node.cur = cur;
        next_node.code = vocab[cur];
        next_node.keyword = keyword;
        next_node.col = node.col + 1;
        
        siblings[node.cur].push_back(next_node);
    }
    
    for (auto it = siblings.begin(); it != siblings.end(); it ++) {
        queue.push_back(it->second);
    }
}
