#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "my_code.h"

extern FILE *f_asm;
extern int now_dec_type;
int cur_counter = 0;
int cur_scope = 0;

char *copyn(int n, char *s) {
    char *p, *q;
    p = q = (char *) calloc(sizeof(char), n);
    while (--n >= 0) {
        *q++ = *s++;
    }
    return p;
}

char *copys(char *s) {
    return copyn(strlen(s) + 1, s);
}

void init_symbol_table() {
    memset(table, 0, sizeof(table));
}

void install_symbol(char *s, int status) {
    if (cur_counter >= MAX_TABLE_SIZE) {
        fprintf(stderr, "Symbol table is full.\n");
    } else {
        table[cur_counter].name = copys(s);
        table[cur_counter].label_name = 0;
        table[cur_counter].type = now_dec_type;
        table[cur_counter].scope = cur_scope;
        table[cur_counter].para_num = 0;
        table[cur_counter].defined_function = 0;
		table[cur_counter].try_to_invoke = 0;
        table[cur_counter].status = status;
        table[cur_counter].var_offset = 0;
        cur_counter++;
    }
}

int look_up_symbol(char *s) {
    int i;
    if (cur_counter == 0) {
        return -1;
    }
    for (i = cur_counter - 1; i >= 0; i--) {
        if (!strcmp(s, table[i].name))
            return i;
    }
    return -1;
}

void pop_up_symbol(int scope) {
    int i;
    if (cur_counter == 0) return;
    for (i = cur_counter - 1; i >= 0; i--) {
        if (table[i].scope != scope)
            break;
    }
    cur_counter = i + 1;
}

int have_declared(char *s) {
    int i;
    for (i = cur_counter - 2; i >= 0; i--) {
        if (!strcmp(s, table[i].name))
            return 1;
    }
    return 0;
}

char *check_func_not_defined() {
	int i;
	for (i = cur_counter - 1; i >= 0; i--) {
		if (table[i].status == FUNC && table[i].defined_function == 0 && table[i].try_to_invoke == 1) {
			return table[i].name;
		}
	}
	return NULL;
}
