//
//  ACAutomaton.h
//  Aho–Corasic
//
//  Created by disen zhang on 2021/3/19.
//

#ifndef ACAutomaton_h
#define ACAutomaton_h

#include <stdio.h>
#include <string>
#include <map>
#include <vector>


using namespace std;

struct TrieNode {
    bool flag;
    string keyword;
    TrieNode *fail;
    map<char, TrieNode *> next;
};


class ACAutomaton {
private:
    TrieNode *root_node;
    
public:
    
    ACAutomaton(vector<string> words) {
        root_node = new TrieNode();
        for (int i = 0; i < words.size(); i++) {
            add(words[i]);
        }
        
        init_fail();
    }
    
    void add(string word) {
        
        TrieNode *node = root_node;
        for (int i = 0; i < word.length(); i++) {
            char ch = word[i];
            if (node->next.count(ch) <= 0) {
                node->next.insert(make_pair(ch, new TrieNode()));
            }
            
            node = node->next[ch];
        }
        
        node->flag = true;
        node->keyword = word;
    }
    
    void init_fail() {
        
        vector<TrieNode *> queue;
        
        // 先处理root的孩子结点
        for(auto iterator = root_node->next.begin(); iterator != root_node->next.end(); iterator ++) {
            TrieNode *it_node = iterator->second;
            it_node->fail = root_node;
            
            //将root孩子结点入队
            queue.push_back(it_node);
        }
        
        while (queue.size() != 0) {
            TrieNode *node = queue[0];
            queue.erase(queue.begin());
            
            // 遍历node结点的next孩子结点
            for(auto iterator = node->next.begin(); iterator != node->next.end(); iterator ++) {
                char ch = iterator->first;
                TrieNode *it_node = iterator->second;
                queue.push_back(it_node);
                
                // 先指向父结点的fail指针
                TrieNode *fail_node = node->fail;
                while (true) {
                    /* 说明找到了根结点还没有找到，则将fail指针指向根节点 */
                    if (fail_node == NULL) {
                        it_node->fail = root_node;
                        break;
                    }
                    
                    if (fail_node->next.count(ch) > 0) {
                        // 如果父结点的fail指针的孩子中有和当前元素ch匹配的孩子结点，说明可以转移，fail指针指向匹配的孩子结点
                        it_node->fail = fail_node->next[ch];
                        break;
                    } else {
                        // 如果父结点的fail指针的孩子中，没有和当前元素ch匹配的孩子结点，则说明不能转移，将fail_node指向父结点的fail指针，重复此过程
                        fail_node = fail_node->fail;
                    }
                }
            }
        }
    }
    
    map<string, int> find(string content) {
        
        map<string, int> keywords;
        
        TrieNode *node = root_node;
        for (int i = 0; i < content.length(); i++) {
            char ch = content[i];
            
            while (true) {
                // 命中孩子结点
                if (node->next.count(ch) > 0) {
                    node = node->next[ch];
                    
                    // 结点转移的时候都要判断一下
                    if (node->flag) {
                        unsigned long index = i - node->keyword.length() + 1;
                        keywords.insert(make_pair(node->keyword, index));
                    }
                    
                    if (node->fail && node->fail->flag) {
                        unsigned long index = i - node->fail->keyword.length() + 1;
                        keywords.insert(make_pair(node->fail->keyword, index));
                    }
                    
                    break;
                }
                
                // node 已经是root结点，还没匹配到
                if (node->fail == NULL) {
                    break;
                }
                
                // 未命中，则指向失败结点
                node = node->fail;
                
                // 结点转移的时候都要判断一下
                if (node->flag) {
                    unsigned long index = i - node->keyword.length() + 1;
                    keywords.insert(make_pair(node->keyword, index));
                }
            }
            
//            if (node->flag) {
//                keywords.insert(make_pair(node->keyword, i));
//            }
        }
        
        return keywords;
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


#endif /* ACAutomaton_h */
