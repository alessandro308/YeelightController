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
 
 */
char* json(char* input, int len){
    printf("INPUT: %s\n", input);
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
    if(strstr(s, "props") != NULL){
        if(len-curr < 2) //Probably there is another JSON to parse
            return NULL;
        else
            return json(input + curr, len-curr);
    }
    return s;
}
