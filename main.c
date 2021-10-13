/*
 * Leda -- The Gemini DOTS compiler
 *
 * Copyright (c) 2015-2021 Gemini Complex Corporation. All rights reserved.
 *
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <errno.h>
#include <stdbool.h>
#include <fcntl.h>
#include <inttypes.h>

#include "libgcore/util.h"
#include "libgcore/stim.h"

static const char usage[] = "Usage: %s -p <profile.json> [dots_file ...]\n";

int main(int argc, char *argv[]){

    if(argc <= 1){
        fprintf(stderr, usage, argv[0]);
        exit(EXIT_FAILURE);
    }

    char *profile_path = NULL;
    struct profile *profile = NULL;
    struct dots **dotses = NULL;
    
    char opt;
    optind = 1;
    opterr = 1;

    // grab the switches
    while((opt = getopt(argc, argv, "p:")) != -1){
        switch (opt){
            case 'p': 
                profile_path = strdup(optarg); 
                break;
            default:
                fprintf(stderr, usage, argv[0]);
                exit(1);
                break;
        }
    }

    if(profile_path == NULL){
        fprintf(stderr, "error: no profile path given.\n");
        exit(EXIT_FAILURE);
    }

    if((profile = get_profile_by_path(profile_path)) == NULL){
        fprintf(stderr, "error: failed to parse profile path.\n");
        exit(EXIT_FAILURE);
    }


    char **dots_paths = NULL;
    int num_dotses = argc-optind;

    if(num_dotses <= 0){
        fprintf(stderr, "No dots files given.\n");
        exit(EXIT_FAILURE);
    }

    printf("parsing %i dots files...\n", num_dotses);
    if((dots_paths = (char **)malloc(num_dotses*sizeof(char *))) == NULL){
        die("malloc failed");
    }

    if((dotses = (struct dots **)malloc(num_dotses*sizeof(struct dots *))) == NULL){
        die("malloc failed");
    }

    int j = 0;
    for(int i=optind; i<argc; i++){
        dots_paths[j] = strdup(argv[i]);
        dotses[j] = parse_dots(profile, dots_paths[j]);
        j += 1;
    }

    printf("compiling %i dots files...\n", num_dotses);
    for(int i=0; i<num_dotses; i++){
        if(dotses[i] == NULL){
            fprintf(stderr, "error: failed to parse dots '%s'\n", dots_paths[i]);
            exit(EXIT_FAILURE);
        }
        char *stim_path = NULL;
        char *dots_path_fixed = strdup(dots_paths[i]);
        char *ext = &(dots_path_fixed[strlen(dots_path_fixed)-2]);
        if(strcmp(ext, ".s") != 0){
            fprintf(stderr, "dots file '%s' must be named: <name>.s\n", dots_paths[i]);
            exit(EXIT_FAILURE);
        }

        int stim_path_len = (strlen(dots_path_fixed)*sizeof(char)) + 50;
        if((stim_path = (char*)malloc(stim_path_len)) == NULL){
            die("malloc failed");
        }
        // chop off extension
        (*ext) = '\0';
        snprintf(stim_path, stim_path_len, "%s.stim", dots_path_fixed);

        printf("compiling %s -> %s\n", dots_paths[i], stim_path);
        struct stim *stim = get_stim_by_dots(profile, dotses[i]);
        stim_serialize_to_path(stim , stim_path);
    }
     
    return EXIT_SUCCESS;

}



