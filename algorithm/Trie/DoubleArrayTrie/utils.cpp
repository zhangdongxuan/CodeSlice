#include <iostream>
#include <vector>
#include <deque>
#include <algorithm>
#include <fstream>
#include <locale>
#include <string>
#include <codecvt>
#include "utils.h"

using namespace std;

vector<string> cut(const string &word, bool if_reverse=false){
    vector<string> segments;
    string tmp = "";
    for (int i=0; i < word.size(); i++){
        if(word.at(i) <= -1){
            tmp = "";
            tmp += word.at(i);
            i++;
            tmp += word.at(i);
            i++;
            tmp += word.at(i);
            segments.push_back(tmp);
        } else {
            tmp = word.at(i);
            segments.push_back(tmp);
        }
    }
    if (if_reverse){
        reverse(segments.begin(), segments.end());
    }
    return segments;
}

vector<wstring> read_file(const string& file_name){
    ifstream ifs(file_name, ifstream::in);
    string line;
    vector<wstring> company_names;
    while(getline(ifs, line)){
        wstring wline = string_to_wstring(line);
        company_names.push_back(wline);
    }
    ifs.close();
    return company_names;
}

wstring string_to_wstring(const string& str) {
    std::wstring_convert<std::codecvt_utf8_utf16<wchar_t>> converter;
    return converter.from_bytes(str);
}

string wstring_to_string(const wstring& str) {
    std::wstring_convert<std::codecvt_utf8_utf16<wchar_t>> converter;
    return converter.to_bytes(str);
}  
