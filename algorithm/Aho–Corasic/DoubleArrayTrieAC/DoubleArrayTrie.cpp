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

void DoubleArrayTrie::reallocate_storage(int new_size) {
    /* Dynamic allocate the storage */
    vector<int> pad(new_size - base.size() + 1);
    base.insert(base.end(), pad.begin(), pad.end());
    check.insert(check.end(), pad.begin(), pad.end());
    alloc_size = new_size + 1;
}


void DoubleArrayTrie::load_file(const string& file_name){
    /* Load segments from local file */
    segments = read_file(file_name);
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
        
        int failure_point = 0;
        for (int i = 1; i < keyword.size(); i++) {
            word = wstring(1, keyword[i]);
            int code = vocab[word];
            pcode = abs(base[pcode]) + code;
            
            failure_point = find_failure(code, failure_point);
            failure[pcode] = failure_point;
        }
        
        if (base[pcode] > 0) {
            base[pcode] = - base[pcode];
        } else if (base[pcode] == 0) {
            base[pcode] = -1;
        }
        
        output[pcode] = i;
    }
}

vector<string> DoubleArrayTrie::acsearch(string content) {
    
    wstring wcontent = string_to_wstring(content);
    int pcode = 0;
    vector<string> keywords;
    
    for (int i = 0; i < content.size(); i++) {
        wstring word = wstring(1, wcontent[i]);
        int code = vocab[word];
        int t = abs(base[pcode])+ code;
        
        if (code == 0) {
            // 没有出现过的字符，检查关键字，重置状态
            check_keyword(pcode, keywords);
            pcode = 0;
        } else if(check[t] == pcode) {
            // 命中状态
            // 检查是否包含更短的关键词
            check_keyword(pcode , keywords);
            pcode = t;
        } else if(pcode == 0 && check[t] == -1) {
            // 第一个字符
            pcode = t;
        } else if(pcode == 0 && check[t] != -1) {
            // 第一个字符，但是并不是开头字符
            pcode = 0;
        } else if (failure[pcode] != 0) {
            // 未命中，,则状态转移
            check_keyword(pcode , keywords);
            pcode = failure[pcode];
            i --;
        } else {
            // 无法转移的 无法匹配字符，则回到root结点
            check_keyword(pcode , keywords);
            pcode = 0;
            i --;
        }
    }
    
    check_keyword(pcode , keywords);
    return keywords;
}

void DoubleArrayTrie::check_keyword(int pcode, vector<string>& keywords) {
    if (base[pcode] >= 0) {
        return;
    }
    
    int index = output[pcode];
    wstring keyword = segments[index];
    
    keywords.push_back(wstring_to_string(keyword));
}

int DoubleArrayTrie::find_failure(int code, int parent_failure) {
    /* To find out the failure path of the node */
    int failure = 0;
    if (parent_failure == 0) {
        if (check[code] == -1) {
            failure = code;
        }
    } else {
        int b = abs(base[parent_failure]) + code;
        if (check[b] == parent_failure) {
            failure = b;
        }
    }
    return failure;
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
    
    int begin = 0;
    int pos = siblings[0].code + 1 > max_index ? siblings[0].code + 1: max_index;
    
    while (true) {
        begin = pos - siblings[0].code;
        
        bool is_found = true;
        for (int i = 0; i < siblings.size(); i ++) {
            Node node = siblings[i];
            int pcode = begin + node.code;
            
            if (pcode >= alloc_size) { reallocate_storage(pcode); }
            
            if (base[pcode] != 0 || check[pcode] != 0) {
                is_found = false;
                break;
            }
        }
        
        if (is_found == false) {
            pos ++;
            max_index = pos;
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
            vocab[prefix] = ++ char_num;
        }
        
        int pcode = vocab[prefix];
        
        if (pcode >= alloc_size) { reallocate_storage(pcode); }
        
        check[pcode] = -1;
        
        if (keyword.size() == 1) { continue; }
        
        wstring cur = wstring(1, keyword[1]);
        if (vocab[cur] == 0) {
            vocab[cur] = ++ char_num;
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
            vocab[cur] = ++ char_num;
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
