//
//  Trie.hpp
//  Trie
//
//  Created by disen zhang on 2021/3/19.
//

#ifndef Trie_hpp
#define Trie_hpp

#include <stdio.h>
#include <string>
#include <map>

using namespace std;


struct TrieNode {
    bool flag;
    map<char, TrieNode *> next;
};


class Trie {
private:
    TrieNode *root_node;
    
public:
    Trie() {
        root_node = new TrieNode();
    }
    
    void insert(string word) {
        
        TrieNode *node = root_node;
        for (int i = 0; i < word.length(); i++) {
            char ch = word[i];
            if (node->next.count(ch) <= 0) {
                node->next.insert(make_pair(ch, new TrieNode()));
            }
            
            node = node->next[ch];
        }
        
        node->flag = true;
    }
    
    bool search(string word) {
        TrieNode *node = root_node;
        for (int i = 0; i < word.length(); i++) {
            char ch = word[i];
            if (node->next.count(ch) <= 0) {
                return false;
            }
            
            node = node->next[ch];
        }
        
        return node->flag;
    }
    
    
    bool remove(string word) {
        if (word.length() == 0) {
            return false;
        }
        
        TrieNode *node = root_node;
        return remove(node, word, 0);
    }
    
    bool remove(TrieNode *node, string word, int i) {
        
        if (i >= word.length()) {
            return false;
        }
        
        char ch = word[i];
        if (node->next.count(ch) <= 0) {
            return false;
        }
        
        TrieNode *next_node = node->next[ch];
        
        // 递归结束条件  1. 找到word的尾部节点  2. node 结束
        if (i == word.length() - 1) {
            if (next_node->flag == false) {
                return false;
            }
            
            if (next_node->next.size() == 0) {
                // 已经是最末端
                delete next_node;
                node->next.erase(ch);
                return true;
            } else {
                // 标记为不是word
                next_node->flag = false;
            }
        }

        bool rm = remove(next_node, word, i + 1);
        if (rm) {
            if (node->next.size() == 0) {
                delete node;
                node->next.erase(ch);
            }
        }
        
        return rm;
    }
    
    
    bool remove_keyword(string word) {
        if (word.length() == 0) {
            return false;
        }
        
        char ch = word[0];
        if (root_node->next.count(ch) == 0) {
            return true;
        }
        
        TrieNode *node = root_node->next[ch];
        return remove_node(node, word, 0);
    }
    
    bool remove_node(TrieNode *node, string word, int i) {
        
        if (node == NULL) {
            return false;
        }
        
        if (i >= word.length()) {
            return false;
        }
        
        if (i == word.length() - 1) {
            if (node->flag == false) {
                return false;
            }
            
            // 叶子节点
            if (node->next.size() == 0) {
                return true;
            }
            
            // 非叶子标记 flag 为false
            node->flag = false;
            return false;
        }
        
        
        char next_ch = word[i + 1];
        if (node->next.count(next_ch) == 0) {
            return false;
        }
        
        TrieNode *next_node = node->next[next_ch];
        bool rm = remove_node(next_node, word, i + 1);
        if (rm) {
            if (node->next.size() <= 1) {
                delete next_node;
                node->next.erase(next_ch);
            }
        }
        
        return rm;
    }
    
    
    void print_all_keyword() {
        printf("--------keywords-----------\n");
        
        map<char, TrieNode *>::iterator iterator = root_node->next.begin();
        while (iterator != root_node->next.end()) {
            char ch = iterator->first;
            TrieNode *node = iterator->second;
            string prefix = string(1, ch);
            print_node(prefix, node);
            iterator ++;
        }
        
    }
    
    void print_node(string prefix, TrieNode *node) {
        
        if (node->next.size() == 0) {
            return;
        }
        
        map<char, TrieNode *>::iterator iterator = node->next.begin();
        while (iterator != node->next.end()) {
            char it_ch = iterator->first;
            TrieNode *it_node = iterator->second;
            
            string new_prefix = prefix + it_ch;
            if (it_node->flag) {
                printf("%s\n", new_prefix.c_str());
            }
            
            print_node(new_prefix, it_node);
            iterator ++;
        }
    }
};


#endif /* Trie_hpp */
