#define MAX_TABLE_SIZE 5000
#define MAX_ARG_NUM 5
#define FUNC 1
#define VAR 2
#define CONST 3
#define MINUS 1
#define PLUS 2

struct symbol_entry {
    char *name;
    char *label_name;
    int type;
    int scope;
    char *para_id[64];
    int para_type[64];
    int para_num;
    int defined_function;
	int try_to_invoke;
    int status; // VAR, FUNC, CONST
    int var_offset;
} table[MAX_TABLE_SIZE];

extern int cur_scope, cur_counter;
