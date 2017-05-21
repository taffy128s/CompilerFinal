#define MAX_TABLE_SIZE 5000
#define MAX_ARG_NUM 5
#define FUNC 1
#define VAR 2
#define CONST 3

struct symbol_entry {
    char *name;
    int type;
    int scope;
    char *para_id[64];
    int para_type[64];
    int para_num;
    int defined_function;
    int status;
    int var_counter;
} table[MAX_TABLE_SIZE];

extern int cur_scope, cur_counter;