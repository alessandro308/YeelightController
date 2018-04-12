//
//  JSONSplitter.c
//  YeelightController2
//
//  Created by Alessandro Pagiaro on 28/01/2018.
//  Copyright © 2018 Alessandro Pagiaro. All rights reserved.
//

#include "JSONSplitter.h"
#include <string.h>
#include <stdlib.h>

/*
    This function split the json input into two jsons. One of them is correct, the other one is the notify json that can
    be ignored.
    The logic is to count the number of curly brackets in order to understand if there are two json attached. In this is
    true, then search for the useful json.
 */
char* get_one_json(char* input, int len){
    int count = 0;
    int curr = 0;
    char* s = (char*) malloc(sizeof(char)*len);
    if(input[curr] == '{'){
        count++;
        s[curr] = input[curr];
        curr++;
    }
    while(count != 0){
        if(input[curr]=='{')
            count++;
        if(input[curr]=='}')
            count--;
        s[curr] = input[curr];
        curr++;
    }
    if(strstr(s, "props") != NULL){ //If there is props in the JSON
        if(len-curr > 2){ //Probably there is another to parse
            return NULL;
        }
        else{
            return get_one_json(input + curr, len-curr);
        }
        
    }
    s[curr] = '\0';
    return s;
}
