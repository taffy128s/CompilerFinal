%{
/*
    when it's defined, output log
*/
#define DEBUG_MODE
/*
    indicate the section that this compiler is generating
*/
#define GEN_BSS 1
#define GEN_DATA 2
#define GEN_TEXT 3
/*
    includes
*/
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "my_code.h"
#define FILE_NAME "Blink.s"
#define MAXLEN 4096
extern int lineNum, commentMatched, quoteMatched;
extern char buffer[MAXLEN], *yytext;
/*
    vars used for code gen
*/
char *now_func_id, *now_label;  // show the nearest function id and label
int now_dec_type = 0;           // show the nearest declaration type
int now_local_var_num = 0;      // show the number of vars in present function
int now_stack_pos = 0;          // memorize present stack position of nearest function
int arg_pass_num = 0, arg_type[MAX_ARG_NUM]; // show the argument number in exprs
int now_gen = 0;                // memorize the sector this compiler is generating
int above_and_include_setup = 1;// show _Z5 or _Z4
int func_def_counter = 0;       // count function definition number
int if_label_nums[128];         // "if" label numbers
int if_label_used = 0;          // "if" label used
int if_label_depth = -1;        // "if" label depth
int while_label_nums[128];      // "while" label numbers
int while_label_used = 0;       // "while" label used
int while_label_depth = -1;     // "while" label depth
int logic_label_used = 0;       // "logic" label used
FILE *f_asm;                    // output file descriptor
/*
    self-defined functions
*/
char *gen_label() {
    int index = look_up_symbol(now_func_id), len = strlen(now_func_id), i, j = 0;
    char *p = calloc(sizeof(char), 3 + len + table[index].para_num + 2);
    p[j++] = '_';
    p[j++] = 'Z';
    if (above_and_include_setup) {
        p[j++] = '5';
    } else {
        p[j++] = '4';
    }
    for (i = 0; i < len; i++) {
        p[j++] = now_func_id[i];
    }
    if (table[index].para_num == 0) {
        p[j++] = 'v';
        p[j] = '\0';
    } else {
        for (i = 0; i < table[index].para_num; i++) {
            p[j++] = 'i';
        }
        p[j] = '\0';
    }
    if (!strcmp(now_func_id, "setup")) {
        above_and_include_setup = 0;
    }
    return p;
}
%}

%start program
%token int_type double_type bool_type char_type void_type id const_prefix
%token int_constant char_constant double_constant other_constant
%token plus_plus minus_minus
%token less_equal bigger_equal equal_equal not_equal
%token and_and or_or
%token if_key else_key
%token switch_key case_key default_key
%token while_key do_key for_key
%token continue_key break_key return_key
%union {
    int integer, expr_type;
    char *ident;
}

%type <integer> int_constant
%type <ident> id
%type <expr_type> int_type double_type bool_type char_type void_type expr_with_no_func_call expr

%left or_or
%left and_and
%nonassoc '!'
%left '>' '<' less_equal bigger_equal equal_equal not_equal
%left '+' '-'
%left '*' '/' '%'
%nonassoc uminus
%left plus_plus minus_minus

%%

program : glo_defs
        ;

glo_defs : glo_defs glo_def
         | glo_def
         ;

glo_def : var_dec
        | const_dec
        | func
        ;

non_void_type : int_type
                {
                    now_dec_type = int_type;
                    #ifdef DEBUG_MODE
                    printf("______now_dec_type: %d\n", now_dec_type);
                    #endif
                }
              | double_type
                {
                    now_dec_type = double_type;
                    #ifdef DEBUG_MODE
                    printf("______now_dec_type: %d\n", now_dec_type);
                    #endif
                }
              | bool_type
                {
                    now_dec_type = bool_type;
                    #ifdef DEBUG_MODE
                    printf("______now_dec_type: %d\n", now_dec_type);
                    #endif
                }
              | char_type
                {
                    now_dec_type = char_type;
                    #ifdef DEBUG_MODE
                    printf("______now_dec_type: %d\n", now_dec_type);
                    #endif
                }
              ;

func : non_void_type id
       {
           // no need to detect error now...
           install_symbol($2, FUNC);
           now_func_id = (char *) copys($2);
           #ifdef DEBUG_MODE
           printf("______now_func_id: %s, and is installed in scope %d\n", now_func_id, cur_scope);
           #endif
       }
       '(' paras ')' dec_or_def
     | void_type
       {
           now_dec_type = void_type;
           #ifdef DEBUG_MODE
           printf("______now_dec_type: %d\n", now_dec_type);
           #endif
       }
       id
       {
           // no need to detect error now...
           install_symbol($3, FUNC);
           now_func_id = (char *) copys($3);
           #ifdef DEBUG_MODE
           printf("______now_func_id: %s, and is installed in scope %d\n", now_func_id, cur_scope);
           #endif
       }
       '(' paras ')' dec_or_def
     ;

dec_or_def : {
                 int is_declared = have_declared(now_func_id);
                 if (is_declared == 1) {
                     fprintf(stderr, "Error at line %d: multiple declaration.\n", lineNum);
                     exit(1);
                 }
             }
             ';'
           | {
                 // Error detection...
                 int i, j, index;
                 now_local_var_num = 0;
                 now_stack_pos = 392;
                 if (now_gen != GEN_TEXT) {
                     now_gen = GEN_TEXT;
                     fprintf(f_asm, "    .text\n");
                 }
                 now_label = gen_label();
                 fprintf(f_asm, "    .align    1\n");
                 fprintf(f_asm, "    .global    %s\n", now_label);
                 fprintf(f_asm, "    .type    %s, @function\n", now_label);
                 fprintf(f_asm, "%s:\n", now_label);
                 fprintf(f_asm, "    push.s    { $lp }\n");
                 fprintf(f_asm, "    addi    $sp, $sp, -400\n");
                 index = look_up_symbol(now_func_id);
                 table[index].label_name = now_label;
                 for (i = 0; i < table[index].para_num; i++) {
                     install_symbol(table[index].para_id[i], VAR);
                     #ifdef DEBUG_MODE
                     printf("______one symbol is installed, scope: %d, count: %d\n", cur_scope + 1, now_local_var_num);
                     #endif
                     j = look_up_symbol(table[index].para_id[i]);
                     table[j].scope = cur_scope + 1;
                     table[j].type = table[index].para_type[i];
                     table[j].var_counter = now_local_var_num++;
                     fprintf(f_asm, "    swi    $r%d, [$sp + (%d)]\n", i, i * 4);
                 }
                 func_def_counter++;
             }
             compound
             {
                 fprintf(f_asm, "    addi    $sp, $sp, 400\n");
                 fprintf(f_asm, "    pop.s    { $lp }\n");
                 fprintf(f_asm, "    ret\n");
                 fprintf(f_asm, "    .size    %s, .-%s\n", now_label, now_label);
                 #ifdef DEBUG_MODE
                 printf("______function ends, and it had %d vars.\n", now_local_var_num);
                 #endif
             }
           ;

paras : paras ',' para
      | para
      |
      ;

para : non_void_type id
       {
           int index = look_up_symbol(now_func_id);
           table[index].para_id[table[index].para_num] = (char *) copys($2);
           table[index].para_type[table[index].para_num++] = now_dec_type;
           #ifdef DEBUG_MODE
           printf("______function %s is at index [%d], and now it has %d parameters\n", now_func_id, index, table[index].para_num);
           #endif
       }
     | non_void_type id arr_dim
       {
           fprintf(stderr, "Error at line %d: array is not allowed.\n", lineNum);
           exit(1);
       }
     ;

declares : declares declare
         | declare
         ;

declare : var_dec
        | const_dec
        ;

statements : statements statement
           | statement
           ;

statement : id
            {
                arg_pass_num = 0;
            }
            '(' exprs ')' ';'
            {
                int i, index;
                index = look_up_symbol($1);
                if (index == -1 || table[index].status != FUNC) {
                    fprintf(stderr, "Error at line %d: function not found.\n", lineNum);
                    exit(1);
                }
                if (arg_pass_num != table[index].para_num) {
                    fprintf(stderr, "Error at line %d: argument number not matched.\n", lineNum);
                    exit(1);
                }
                for (i = 0; i < arg_pass_num; i++) {
                    if (arg_type[i] != table[index].para_type[i]) {
                        fprintf(stderr, "Error at line %d: argument type not matched.\n", lineNum);
                    exit(1);
                    }
                }
                #ifdef DEBUG_MODE
                printf("______passing %d arguments\n", arg_pass_num);
                #endif
                for (i = arg_pass_num - 1; i >= 0; i--) {
                    now_stack_pos += 4;
                    fprintf(f_asm, "    lwi    $r%d, [$sp + (%d)]\n", i, now_stack_pos);
                }
                fprintf(f_asm, "    bal %s\n", table[index].label_name);
            }
          | id '=' expr ';'
            {
                int index;
                index = look_up_symbol($1);
                if (index == -1) {
                    fprintf(stderr, "Error at line %d: symbol not found.\n", lineNum);
                    exit(1);
                }
                if (table[index].status != VAR) {
                    fprintf(stderr, "Error at line %d: cannot assign value to a non-var id.\n", lineNum);
                    exit(1);
                }
                #ifdef DEBUG_MODE
                printf("______id %s is at local place %d\n", $1, table[index].var_counter);
                #endif
                now_stack_pos += 4;
                fprintf(f_asm, "    lwi    $r0, [$sp + (%d)]\n", now_stack_pos);
                fprintf(f_asm, "    swi    $r0, [$sp + (%d)]\n", table[index].var_counter * 4);
            }
          | id arr_dim_expr '=' expr ';'
            {
                fprintf(stderr, "Error at line %d: array is not allowed.\n", lineNum);
                exit(1);
            }
          | compound
          | if_key '(' expr ')' gen_if compound gen_if_lable_with_jump else_key compound gen_if_lable
          | if_key '(' expr ')' gen_if compound gen_if_lable
          | switch_key '(' id ')' '{' cases default_case '}'
          | while_key 
            {
                while_label_depth++;
                while_label_nums[while_label_depth] = while_label_used;
                while_label_used += 2;
                fprintf(f_asm, ".W%d:\n", while_label_nums[while_label_depth]);
            }
            '(' expr ')' gen_while compound gen_while_end
          | do_key compound while_key '(' expr ')' ';'
          | for_key '(' exprs ';' exprs ';' exprs ')' compound
          | continue_key ';'
          | break_key ';'
          | return_key expr ';'
          | id plus_plus ';'
            {
                int index = look_up_symbol($1);
                if (index == -1) {
                    fprintf(stderr, "Error at line %d: symbol not found.\n", lineNum);
                    exit(1);
                }
                if (table[index].status != VAR) {
                    fprintf(stderr, "Error at line %d: cannot assign value to a non-var id.\n", lineNum);
                    exit(1);
                }
                fprintf(f_asm, "    lwi    $r0, [$sp + (%d)]\n", table[index].var_counter * 4);
                fprintf(f_asm, "    addi    $r0, $r0, 1\n");
                fprintf(f_asm, "    swi    $r0, [$sp + (%d)]\n", table[index].var_counter * 4);
            }
          | id minus_minus ';'
            {
                int index = look_up_symbol($1);
                if (index == -1) {
                    fprintf(stderr, "Error at line %d: symbol not found.\n", lineNum);
                    exit(1);
                }
                if (table[index].status != VAR) {
                    fprintf(stderr, "Error at line %d: cannot assign value to a non-var id.\n", lineNum);
                    exit(1);
                }
                fprintf(f_asm, "    lwi    $r0, [$sp + (%d)]\n", table[index].var_counter * 4);
                fprintf(f_asm, "    subi    $r0, $r0, 1\n");
                fprintf(f_asm, "    swi    $r0, [$sp + (%d)]\n", table[index].var_counter * 4);
            }
          ;
          
gen_while : {
                now_stack_pos += 4;
                fprintf(f_asm, "    lwi    $r0, [$sp + (%d)]\n", now_stack_pos);
                fprintf(f_asm, "    beqz    $r0, .W%d\n", while_label_nums[while_label_depth] + 1);
            }
          ;
            
gen_while_end : {
                    fprintf(f_asm, "    j    .W%d\n", while_label_nums[while_label_depth]);
                    fprintf(f_asm, ".W%d:\n", while_label_nums[while_label_depth] + 1);
                    while_label_depth--;
                }
              ;
gen_if : {
             if_label_depth++;
             if_label_nums[if_label_depth] = if_label_used;
             if_label_used += 2;
             now_stack_pos += 4;
             fprintf(f_asm, "    lwi    $r0, [$sp + (%d)]\n", now_stack_pos);
             fprintf(f_asm, "    beqz    $r0, .I%d\n", if_label_nums[if_label_depth]);
         }
       ;

gen_if_lable_with_jump : {
                             fprintf(f_asm, "    j    .I%d\n", if_label_nums[if_label_depth] + 1);
                             fprintf(f_asm, ".I%d:\n", if_label_nums[if_label_depth]++);
                         }
                       ;

gen_if_lable : {
                   fprintf(f_asm, ".I%d:\n", if_label_nums[if_label_depth]++);
                   if_label_depth--;
               }
             ;

cases : cases one_case
      | one_case
      ;

one_case : case_key int_or_char ':' statements
         | case_key int_or_char ':'
         ;

default_case : default_key ':' statements
             | default_key ':'
             |
             ;

int_or_char : int_constant
            | char_constant
            ;

compound : '{' handle_scope1 declares statements '}' handle_scope2
         | '{' handle_scope1 declares '}' handle_scope2
         | '{' handle_scope1 statements '}' handle_scope2
         | '{' handle_scope1 '}' handle_scope2
         ;

handle_scope1 : {
                    cur_scope++;
                }
              ;

handle_scope2 : {
                    pop_up_symbol(cur_scope);
                    #ifdef DEBUG_MODE
                    printf("______symbols in scope %d have been popped\n", cur_scope);
                    #endif
                    cur_scope--;
                }
              ;

exprs : exprs ',' expr
        {
            #ifdef DEBUG_MODE
            printf("______parsing arg%d, type:%d\n", arg_pass_num, $3);
            #endif
            arg_type[arg_pass_num] = $3;
            arg_pass_num++;
        }
      | expr
        {
            #ifdef DEBUG_MODE
            printf("______parsing arg%d, type:%d\n", arg_pass_num, $1);
            #endif
            arg_type[arg_pass_num] = $1;
            arg_pass_num++;
        }
      |
      ;

const_dec : const_prefix non_void_type const_list ';'
          ;

const_list : const_list ',' const_single
           | const_single
           ;

const_single : id '=' all_constant
               {
                   int index = look_up_symbol($1);
                   if (index >= 0) {
                       fprintf(stderr, "Error at line %d: multiple definition.\n", lineNum);
                       exit(1);
                   }
                   install_symbol($1, CONST);
                   #ifdef DEBUG_MODE
                   printf("______one symbol is installed, scope: %d, count: %d\n", cur_scope, now_local_var_num);
                   #endif
                   index = look_up_symbol($1);
                   now_stack_pos += 4;
                   fprintf(f_asm, "    lwi    $r0, [$sp + (%d)]\n", now_stack_pos);
                   fprintf(f_asm, "    swi    $r0, [$sp + (%d)]\n", now_local_var_num * 4);
                   table[index].var_counter = now_local_var_num++;
               }
             ;

all_constant : int_constant
             | char_constant
             | double_constant
             | other_constant
             ;

var_dec : non_void_type var_list ';'
        ;

var_list : var_list ',' var_single
         | var_single
         ;

var_single : single_arr
             {
                 fprintf(stderr, "Error at line %d: array is not allowed.\n", lineNum);
                 exit(1);
             }
           | single_one
           ;

single_arr : id arr_dim
           | id arr_dim '=' arr_ini
           ;

arr_dim : arr_dim '[' int_constant ']'
        | '[' int_constant ']'
        ;

arr_dim_expr : arr_dim_expr '[' expr ']'
             | '[' expr ']'
             ;

arr_dim_expr_with_no_func_call : arr_dim_expr_with_no_func_call '[' expr_with_no_func_call ']'
                               | '[' expr_with_no_func_call ']'
                               ;

arr_ini : '{' ini_seq '}'
        ;

ini_seq : ini_seq ',' expr_with_no_func_call
        | expr_with_no_func_call
        ;

single_one : id
             {
                 int index = look_up_symbol($1);
                 if (index >= 0) {
                     fprintf(stderr, "Error at line %d: multiple definition.\n", lineNum);
                     exit(1);
                 }
                 install_symbol($1, VAR);
                 #ifdef DEBUG_MODE
                 printf("______one symbol is installed, scope: %d, count: %d\n", cur_scope, now_local_var_num);
                 #endif
                 index = look_up_symbol($1);
                 table[index].var_counter = now_local_var_num++;
             }
           | id '=' expr_with_no_func_call
             {
                 int index = look_up_symbol($1);
                 if (index >= 0) {
                     fprintf(stderr, "Error at line %d: multiple definition.\n", lineNum);
                     exit(1);
                 }
                 install_symbol($1, VAR);
                 #ifdef DEBUG_MODE
                 printf("______one symbol is installed, scope: %d, count: %d\n", cur_scope, now_local_var_num);
                 #endif
                 index = look_up_symbol($1);
                 now_stack_pos += 4;
                 fprintf(f_asm, "    lwi    $r0, [$sp + (%d)]\n", now_stack_pos);
                 fprintf(f_asm, "    swi    $r0, [$sp + (%d)]\n", now_local_var_num * 4);
                 table[index].var_counter = now_local_var_num++;
             }
           ;

expr : expr or_or expr
       {
           now_stack_pos += 4;
           fprintf(f_asm, "    lwi    $r0, [$sp + (%d)]\n", now_stack_pos);
           fprintf(f_asm, "    bnez    $r0, .L%d\n", logic_label_used);
           now_stack_pos += 4;
           fprintf(f_asm, "    lwi    $r0, [$sp + (%d)]\n", now_stack_pos);
           fprintf(f_asm, "    beqz    $r0, .L%d\n", logic_label_used + 1);
           fprintf(f_asm, ".L%d:\n", logic_label_used);
           fprintf(f_asm, "    movi    $r0, 1\n");
           fprintf(f_asm, "    j    .L%d\n", logic_label_used + 2);
           fprintf(f_asm, ".L%d:\n", logic_label_used + 1);
           fprintf(f_asm, "    movi    $r0, 0\n");
           fprintf(f_asm, ".L%d:\n", logic_label_used + 2);
           fprintf(f_asm, "    swi    $r0, [$sp + (%d)]\n", now_stack_pos);
           now_stack_pos -= 4;
           logic_label_used += 3;
           $$ = int_type;
       }
     | expr and_and expr
       {
           now_stack_pos += 4;
           fprintf(f_asm, "    lwi    $r0, [$sp + (%d)]\n", now_stack_pos);
           fprintf(f_asm, "    beqz    $r0, .L%d\n", logic_label_used);
           now_stack_pos += 4;
           fprintf(f_asm, "    lwi    $r0, [$sp + (%d)]\n", now_stack_pos);
           fprintf(f_asm, "    beqz    $r0, .L%d\n", logic_label_used);
           fprintf(f_asm, "    movi    $r0, 1\n");
           fprintf(f_asm, "    j    .L%d\n", logic_label_used + 1);
           fprintf(f_asm, ".L%d:\n", logic_label_used);
           fprintf(f_asm, "    movi    $r0, 0\n");
           fprintf(f_asm, ".L%d:\n", logic_label_used + 1);
           fprintf(f_asm, "    swi    $r0, [$sp + (%d)]\n", now_stack_pos);
           now_stack_pos -= 4;
           logic_label_used += 2;
           $$ = int_type;
       }
     | '!' expr
       {
           now_stack_pos += 4;
           fprintf(f_asm, "    lwi    $r0, [$sp + (%d)]\n", now_stack_pos);
           fprintf(f_asm, "    slti    $r0, $r0, 1\n");
           fprintf(f_asm, "    zeb    $r0, $r0\n");
           fprintf(f_asm, "    swi    $r0, [$sp + (%d)]\n", now_stack_pos);
           now_stack_pos -= 4;  
           $$ = $2;
       }
     | expr '<' expr
       {
           now_stack_pos += 4;
           fprintf(f_asm, "    lwi    $r1, [$sp + (%d)]\n", now_stack_pos);
           now_stack_pos += 4;
           fprintf(f_asm, "    lwi    $r0, [$sp + (%d)]\n", now_stack_pos);
           fprintf(f_asm, "    slts    $r0, $r0, $r1\n");
           fprintf(f_asm, "    swi    $r0, [$sp + (%d)]\n", now_stack_pos);
           now_stack_pos -= 4;  
           if ($1 != $3) {
               fprintf(stderr, "Error at line %d: type not matched.\n", lineNum);
               exit(1);  
           }
           $$ = $1;
       }
     | expr '>' expr
       {
           now_stack_pos += 4;
           fprintf(f_asm, "    lwi    $r1, [$sp + (%d)]\n", now_stack_pos);
           now_stack_pos += 4;
           fprintf(f_asm, "    lwi    $r0, [$sp + (%d)]\n", now_stack_pos);
           fprintf(f_asm, "    slts    $r0, $r1, $r0\n");
           fprintf(f_asm, "    swi    $r0, [$sp + (%d)]\n", now_stack_pos);
           now_stack_pos -= 4; 
           if ($1 != $3) {
               fprintf(stderr, "Error at line %d: type not matched.\n", lineNum);
               exit(1);  
           }
           $$ = $1;
       }
     | expr less_equal expr
       {
           now_stack_pos += 4;
           fprintf(f_asm, "    lwi    $r1, [$sp + (%d)]\n", now_stack_pos);
           now_stack_pos += 4;
           fprintf(f_asm, "    lwi    $r0, [$sp + (%d)]\n", now_stack_pos);
           fprintf(f_asm, "    slts    $r0, $r1, $r0\n");
           fprintf(f_asm, "    xori    $r0, $r0, 1\n");
           fprintf(f_asm, "    swi    $r0, [$sp + (%d)]\n", now_stack_pos);
           now_stack_pos -= 4;  
           if ($1 != $3) {
               fprintf(stderr, "Error at line %d: type not matched.\n", lineNum);
               exit(1);  
           }
           $$ = $1;
       }
     | expr bigger_equal expr
       {
           now_stack_pos += 4;
           fprintf(f_asm, "    lwi    $r1, [$sp + (%d)]\n", now_stack_pos);
           now_stack_pos += 4;
           fprintf(f_asm, "    lwi    $r0, [$sp + (%d)]\n", now_stack_pos);
           fprintf(f_asm, "    slts    $r0, $r0, $r1\n");
           fprintf(f_asm, "    xori    $r0, $r0, 1\n");
           fprintf(f_asm, "    swi    $r0, [$sp + (%d)]\n", now_stack_pos);
           now_stack_pos -= 4;  
           if ($1 != $3) {
               fprintf(stderr, "Error at line %d: type not matched.\n", lineNum);
               exit(1);  
           }
           $$ = $1;
       }
     | expr equal_equal expr
       {
           now_stack_pos += 4;
           fprintf(f_asm, "    lwi    $r1, [$sp + (%d)]\n", now_stack_pos);
           now_stack_pos += 4;
           fprintf(f_asm, "    lwi    $r0, [$sp + (%d)]\n", now_stack_pos);
           fprintf(f_asm, "    sub    $r0, $r0, $r1\n");
           fprintf(f_asm, "    slti    $r0, $r0, 1\n");
           fprintf(f_asm, "    zeb    $r0, $r0\n");
           fprintf(f_asm, "    swi    $r0, [$sp + (%d)]\n", now_stack_pos);
           now_stack_pos -= 4;
           if ($1 != $3) {
               fprintf(stderr, "Error at line %d: type not matched.\n", lineNum);
               exit(1);  
           }
           $$ = $1;
       }
     | expr not_equal expr
       {
           now_stack_pos += 4;
           fprintf(f_asm, "    lwi    $r1, [$sp + (%d)]\n", now_stack_pos);
           now_stack_pos += 4;
           fprintf(f_asm, "    lwi    $r0, [$sp + (%d)]\n", now_stack_pos);
           fprintf(f_asm, "    sub    $r0, $r0, $r1\n");
           fprintf(f_asm, "    movi    $r1, 0\n");
           fprintf(f_asm, "    slt    $r0, $r1, $r0\n");
           fprintf(f_asm, "    zeb    $r0, $r0\n");
           fprintf(f_asm, "    swi    $r0, [$sp + (%d)]\n", now_stack_pos);
           now_stack_pos -= 4;
           if ($1 != $3) {
               fprintf(stderr, "Error at line %d: type not matched.\n", lineNum);
               exit(1);  
           }
           $$ = $1;
       }
     | expr '+' expr
       {
           now_stack_pos += 4;
           fprintf(f_asm, "    lwi    $r1, [$sp + (%d)]\n", now_stack_pos);
           now_stack_pos += 4;
           fprintf(f_asm, "    lwi    $r0, [$sp + (%d)]\n", now_stack_pos);
           fprintf(f_asm, "    add    $r0, $r0, $r1\n");
           fprintf(f_asm, "    swi    $r0, [$sp + (%d)]\n", now_stack_pos);
           now_stack_pos -= 4;
           if ($1 != $3) {
               fprintf(stderr, "Error at line %d: type not matched.\n", lineNum);
               exit(1);  
           }
           $$ = $1;
       }
     | expr '-' expr
       {
           now_stack_pos += 4;
           fprintf(f_asm, "    lwi    $r1, [$sp + (%d)]\n", now_stack_pos);
           now_stack_pos += 4;
           fprintf(f_asm, "    lwi    $r0, [$sp + (%d)]\n", now_stack_pos);
           fprintf(f_asm, "    sub    $r0, $r0, $r1\n");
           fprintf(f_asm, "    swi    $r0, [$sp + (%d)]\n", now_stack_pos);
           now_stack_pos -= 4;
           if ($1 != $3) {
               fprintf(stderr, "Error at line %d: type not matched.\n", lineNum);
               exit(1);  
           }
           $$ = $1;
       }
     | expr '*' expr
       {
           now_stack_pos += 4;
           fprintf(f_asm, "    lwi    $r1, [$sp + (%d)]\n", now_stack_pos);
           now_stack_pos += 4;
           fprintf(f_asm, "    lwi    $r0, [$sp + (%d)]\n", now_stack_pos);
           fprintf(f_asm, "    mul    $r0, $r0, $r1\n");
           fprintf(f_asm, "    swi    $r0, [$sp + (%d)]\n", now_stack_pos);
           now_stack_pos -= 4;
           if ($1 != $3) {
               fprintf(stderr, "Error at line %d: type not matched.\n", lineNum);
               exit(1);  
           }
           $$ = $1;
       }
     | expr '/' expr
       {
           now_stack_pos += 4;
           fprintf(f_asm, "    lwi    $r1, [$sp + (%d)]\n", now_stack_pos);
           now_stack_pos += 4;
           fprintf(f_asm, "    lwi    $r0, [$sp + (%d)]\n", now_stack_pos);
           fprintf(f_asm, "    divsr    $r0, $r1, $r0, $r1\n");
           fprintf(f_asm, "    swi    $r0, [$sp + (%d)]\n", now_stack_pos);
           now_stack_pos -= 4;
           if ($1 != $3) {
               fprintf(stderr, "Error at line %d: type not matched.\n", lineNum);
               exit(1);  
           }
           $$ = $1;
       }
     | expr '%' expr
       {
           now_stack_pos += 4;
           fprintf(f_asm, "    lwi    $r1, [$sp + (%d)]\n", now_stack_pos);
           now_stack_pos += 4;
           fprintf(f_asm, "    lwi    $r0, [$sp + (%d)]\n", now_stack_pos);
           fprintf(f_asm, "    divsr    $r0, $r1, $r0, $r1\n");
           fprintf(f_asm, "    swi    $r1, [$sp + (%d)]\n", now_stack_pos);
           now_stack_pos -= 4;
           if ($1 != $3) {
               fprintf(stderr, "Error at line %d: type not matched.\n", lineNum);
               exit(1);  
           }
           $$ = $1;
       }
     | '-' expr %prec uminus
       {
           now_stack_pos += 4;
           fprintf(f_asm, "    lwi    $r1, [$sp + (%d)]\n", now_stack_pos);
           fprintf(f_asm, "    movi    $r0, 0\n");
           fprintf(f_asm, "    sub    $r0, $r0, $r1\n");
           fprintf(f_asm, "    swi    $r0, [$sp + (%d)]\n", now_stack_pos);
           now_stack_pos -= 4;  
           $$ = $2;
       }
     | expr plus_plus
       {
           now_stack_pos += 4;
           fprintf(f_asm, "    lwi    $r0, [$sp + (%d)]\n", now_stack_pos);
           fprintf(f_asm, "    addi    $r0, $r0, 1\n");
           fprintf(f_asm, "    swi    $r0, [$sp + (%d)]\n", now_stack_pos);
           now_stack_pos -= 4;
           $$ = $1;
       }
     | expr minus_minus
       {
           now_stack_pos += 4;
           fprintf(f_asm, "    lwi    $r0, [$sp + (%d)]\n", now_stack_pos);
           fprintf(f_asm, "    subi    $r0, $r0, 1\n");
           fprintf(f_asm, "    swi    $r0, [$sp + (%d)]\n", now_stack_pos);
           now_stack_pos -= 4;  
           $$ = $1;
       }
     | id
       {
           int index = look_up_symbol($1);
           if (index == -1 || table[index].status == FUNC) {
               fprintf(stderr, "Error at line %d: symbol not found.\n", lineNum);
               exit(1);
           }
           fprintf(f_asm, "    lwi    $r0, [$sp + (%d)]\n", table[index].var_counter * 4);
           fprintf(f_asm, "    swi    $r0, [$sp + (%d)]\n", now_stack_pos);
           now_stack_pos -= 4;
           $$ = table[index].type;
       }
     | id arr_dim_expr
       {
           fprintf(stderr, "Error at line %d: not allowed type.\n", lineNum);
           exit(1);  
       }
     | int_constant
       {
           fprintf(f_asm, "    movi    $r0, %d\n", $1);
           fprintf(f_asm, "    swi    $r0, [$sp + (%d)]\n", now_stack_pos);
           now_stack_pos -= 4;
           $$ = int_type;
       }
     | char_constant
       {
           fprintf(stderr, "Error at line %d: not allowed type.\n", lineNum);
           exit(1);  
       }
     | double_constant
       {
           $$ = double_type;
       }
     | other_constant
       {
           fprintf(stderr, "Error at line %d: not allowed type.\n", lineNum);
           exit(1);  
       }
     | id '(' exprs ')'
       {
           int i, index = look_up_symbol($1);
           if (index == -1 || table[index].status != FUNC) {
               fprintf(stderr, "Error at line %d: function not found.\n", lineNum);
               exit(1);
           }
           if (table[index].type != int_type && table[index].type != double_type) {
               fprintf(stderr, "Error at line %d: not allowed type.\n", lineNum);
               exit(1);  
           }
           for (i = 0; i < arg_pass_num; i++) {
               if (arg_type[i] != table[index].para_type[i]) {
                   fprintf(stderr, "Error at line %d: argument type not matched.\n", lineNum);
               exit(1);
               }
           }
           #ifdef DEBUG_MODE
           printf("______passing %d arguments\n", arg_pass_num);
           #endif
           for (i = arg_pass_num - 1; i >= 0; i--) {
               now_stack_pos += 4;
               fprintf(f_asm, "    lwi    $r%d, [$sp + (%d)]\n", i, now_stack_pos);
           }
           fprintf(f_asm, "    bal %s\n", table[index].label_name);
           fprintf(f_asm, "    swi    $r0, [$sp + (%d)]\n", now_stack_pos);
           now_stack_pos -= 4;
           $$ = table[index].type;
       }
     | '(' expr ')'
       {
           $$ = $2;
       }
     ;

expr_with_no_func_call : expr_with_no_func_call or_or expr_with_no_func_call
                         {
                             now_stack_pos += 4;
                             fprintf(f_asm, "    lwi    $r0, [$sp + (%d)]\n", now_stack_pos);
                             fprintf(f_asm, "    bnez    $r0, .L%d\n", logic_label_used);
                             now_stack_pos += 4;
                             fprintf(f_asm, "    lwi    $r0, [$sp + (%d)]\n", now_stack_pos);
                             fprintf(f_asm, "    beqz    $r0, .L%d\n", logic_label_used + 1);
                             fprintf(f_asm, ".L%d:\n", logic_label_used);
                             fprintf(f_asm, "    movi    $r0, 1\n");
                             fprintf(f_asm, "    j    .L%d\n", logic_label_used + 2);
                             fprintf(f_asm, ".L%d:\n", logic_label_used + 1);
                             fprintf(f_asm, "    movi    $r0, 0\n");
                             fprintf(f_asm, ".L%d:\n", logic_label_used + 2);
                             fprintf(f_asm, "    swi    $r0, [$sp + (%d)]\n", now_stack_pos);
                             now_stack_pos -= 4;
                             logic_label_used += 3;
                             $$ = int_type;
                         }
                       | expr_with_no_func_call and_and expr_with_no_func_call
                         {
                             now_stack_pos += 4;
                             fprintf(f_asm, "    lwi    $r0, [$sp + (%d)]\n", now_stack_pos);
                             fprintf(f_asm, "    beqz    $r0, .L%d\n", logic_label_used);
                             now_stack_pos += 4;
                             fprintf(f_asm, "    lwi    $r0, [$sp + (%d)]\n", now_stack_pos);
                             fprintf(f_asm, "    beqz    $r0, .L%d\n", logic_label_used);
                             fprintf(f_asm, "    movi    $r0, 1\n");
                             fprintf(f_asm, "    j    .L%d\n", logic_label_used + 1);
                             fprintf(f_asm, ".L%d:\n", logic_label_used);
                             fprintf(f_asm, "    movi    $r0, 0\n");
                             fprintf(f_asm, ".L%d:\n", logic_label_used + 1);
                             fprintf(f_asm, "    swi    $r0, [$sp + (%d)]\n", now_stack_pos);
                             now_stack_pos -= 4;
                             logic_label_used += 2;
                             $$ = int_type;
                         }
                       | '!' expr_with_no_func_call 
                         {
                             now_stack_pos += 4;
                             fprintf(f_asm, "    lwi    $r0, [$sp + (%d)]\n", now_stack_pos);
                             fprintf(f_asm, "    slti    $r0, $r0, 1\n");
                             fprintf(f_asm, "    zeb    $r0, $r0\n");
                             fprintf(f_asm, "    swi    $r0, [$sp + (%d)]\n", now_stack_pos);
                             now_stack_pos -= 4;
                             $$ = $2;
                         }
                       | expr_with_no_func_call '<' expr_with_no_func_call
                         {
                             now_stack_pos += 4;
                             fprintf(f_asm, "    lwi    $r1, [$sp + (%d)]\n", now_stack_pos);
                             now_stack_pos += 4;
                             fprintf(f_asm, "    lwi    $r0, [$sp + (%d)]\n", now_stack_pos);
                             fprintf(f_asm, "    slts    $r0, $r0, $r1\n");
                             fprintf(f_asm, "    swi    $r0, [$sp + (%d)]\n", now_stack_pos);
                             now_stack_pos -= 4;
                             if ($1 != $3) {
                                 fprintf(stderr, "Error at line %d: type not matched.\n", lineNum);
                                 exit(1);  
                             }
                             $$ = $1;
                         }
                       | expr_with_no_func_call '>' expr_with_no_func_call
                         {
                             now_stack_pos += 4;
                             fprintf(f_asm, "    lwi    $r1, [$sp + (%d)]\n", now_stack_pos);
                             now_stack_pos += 4;
                             fprintf(f_asm, "    lwi    $r0, [$sp + (%d)]\n", now_stack_pos);
                             fprintf(f_asm, "    slts    $r0, $r1, $r0\n");
                             fprintf(f_asm, "    swi    $r0, [$sp + (%d)]\n", now_stack_pos);
                             now_stack_pos -= 4; 
                             if ($1 != $3) {
                                 fprintf(stderr, "Error at line %d: type not matched.\n", lineNum);
                                 exit(1);  
                             }
                             $$ = $1;
                         }
                       | expr_with_no_func_call less_equal expr_with_no_func_call
                         {
                             now_stack_pos += 4;
                             fprintf(f_asm, "    lwi    $r1, [$sp + (%d)]\n", now_stack_pos);
                             now_stack_pos += 4;
                             fprintf(f_asm, "    lwi    $r0, [$sp + (%d)]\n", now_stack_pos);
                             fprintf(f_asm, "    slts    $r0, $r1, $r0\n");
                             fprintf(f_asm, "    xori    $r0, $r0, 1\n");
                             fprintf(f_asm, "    swi    $r0, [$sp + (%d)]\n", now_stack_pos);
                             now_stack_pos -= 4;
                             if ($1 != $3) {
                                 fprintf(stderr, "Error at line %d: type not matched.\n", lineNum);
                                 exit(1);  
                             }
                             $$ = $1;
                         }
                       | expr_with_no_func_call bigger_equal expr_with_no_func_call
                         {
                             now_stack_pos += 4;
                             fprintf(f_asm, "    lwi    $r1, [$sp + (%d)]\n", now_stack_pos);
                             now_stack_pos += 4;
                             fprintf(f_asm, "    lwi    $r0, [$sp + (%d)]\n", now_stack_pos);
                             fprintf(f_asm, "    slts    $r0, $r0, $r1\n");
                             fprintf(f_asm, "    xori    $r0, $r0, 1\n");
                             fprintf(f_asm, "    swi    $r0, [$sp + (%d)]\n", now_stack_pos);
                             now_stack_pos -= 4;
                             if ($1 != $3) {
                                 fprintf(stderr, "Error at line %d: type not matched.\n", lineNum);
                                 exit(1);  
                             }
                             $$ = $1;
                         }
                       | expr_with_no_func_call equal_equal expr_with_no_func_call
                         {
                             now_stack_pos += 4;
                             fprintf(f_asm, "    lwi    $r1, [$sp + (%d)]\n", now_stack_pos);
                             now_stack_pos += 4;
                             fprintf(f_asm, "    lwi    $r0, [$sp + (%d)]\n", now_stack_pos);
                             fprintf(f_asm, "    sub    $r0, $r0, $r1\n");
                             fprintf(f_asm, "    slti    $r0, $r0, 1\n");
                             fprintf(f_asm, "    zeb    $r0, $r0\n");
                             fprintf(f_asm, "    swi    $r0, [$sp + (%d)]\n", now_stack_pos);
                             now_stack_pos -= 4;
                             if ($1 != $3) {
                                 fprintf(stderr, "Error at line %d: type not matched.\n", lineNum);
                                 exit(1);  
                             }
                             $$ = $1;
                         }
                       | expr_with_no_func_call not_equal expr_with_no_func_call
                         {
                             now_stack_pos += 4;
                             fprintf(f_asm, "    lwi    $r1, [$sp + (%d)]\n", now_stack_pos);
                             now_stack_pos += 4;
                             fprintf(f_asm, "    lwi    $r0, [$sp + (%d)]\n", now_stack_pos);
                             fprintf(f_asm, "    sub    $r0, $r0, $r1\n");
                             fprintf(f_asm, "    movi    $r1, 0\n");
                             fprintf(f_asm, "    slt    $r0, $r1, $r0\n");
                             fprintf(f_asm, "    zeb    $r0, $r0\n");
                             fprintf(f_asm, "    swi    $r0, [$sp + (%d)]\n", now_stack_pos);
                             now_stack_pos -= 4;
                             if ($1 != $3) {
                                 fprintf(stderr, "Error at line %d: type not matched.\n", lineNum);
                                 exit(1);  
                             }
                             $$ = $1;
                         }
                       | expr_with_no_func_call '+' expr_with_no_func_call
                         {
                             now_stack_pos += 4;
                             fprintf(f_asm, "    lwi    $r1, [$sp + (%d)]\n", now_stack_pos);
                             now_stack_pos += 4;
                             fprintf(f_asm, "    lwi    $r0, [$sp + (%d)]\n", now_stack_pos);
                             fprintf(f_asm, "    add    $r0, $r0, $r1\n");
                             fprintf(f_asm, "    swi    $r0, [$sp + (%d)]\n", now_stack_pos);
                             now_stack_pos -= 4;
                             if ($1 != $3) {
                                 fprintf(stderr, "Error at line %d: type not matched.\n", lineNum);
                                 exit(1);  
                             }
                             $$ = $1;
                         }
                       | expr_with_no_func_call '-' expr_with_no_func_call
                         {
                             now_stack_pos += 4;
                             fprintf(f_asm, "    lwi    $r1, [$sp + (%d)]\n", now_stack_pos);
                             now_stack_pos += 4;
                             fprintf(f_asm, "    lwi    $r0, [$sp + (%d)]\n", now_stack_pos);
                             fprintf(f_asm, "    sub    $r0, $r0, $r1\n");
                             fprintf(f_asm, "    swi    $r0, [$sp + (%d)]\n", now_stack_pos);
                             now_stack_pos -= 4;
                             if ($1 != $3) {
                                 fprintf(stderr, "Error at line %d: type not matched.\n", lineNum);
                                 exit(1);  
                             }
                             $$ = $1;
                         }
                       | expr_with_no_func_call '*' expr_with_no_func_call
                         {
                             now_stack_pos += 4;
                             fprintf(f_asm, "    lwi    $r1, [$sp + (%d)]\n", now_stack_pos);
                             now_stack_pos += 4;
                             fprintf(f_asm, "    lwi    $r0, [$sp + (%d)]\n", now_stack_pos);
                             fprintf(f_asm, "    mul    $r0, $r0, $r1\n");
                             fprintf(f_asm, "    swi    $r0, [$sp + (%d)]\n", now_stack_pos);
                             now_stack_pos -= 4;
                             if ($1 != $3) {
                                 fprintf(stderr, "Error at line %d: type not matched.\n", lineNum);
                                 exit(1);  
                             }
                             $$ = $1;
                         }
                       | expr_with_no_func_call '/' expr_with_no_func_call
                         {
                             now_stack_pos += 4;
                             fprintf(f_asm, "    lwi    $r1, [$sp + (%d)]\n", now_stack_pos);
                             now_stack_pos += 4;
                             fprintf(f_asm, "    lwi    $r0, [$sp + (%d)]\n", now_stack_pos);
                             fprintf(f_asm, "    divsr    $r0, $r1, $r0, $r1\n");
                             fprintf(f_asm, "    swi    $r0, [$sp + (%d)]\n", now_stack_pos);
                             now_stack_pos -= 4;
                             if ($1 != $3) {
                                 fprintf(stderr, "Error at line %d: type not matched.\n", lineNum);
                                 exit(1);  
                             }
                             $$ = $1;
                         }
                       | expr_with_no_func_call '%' expr_with_no_func_call
                         {
                             now_stack_pos += 4;
                             fprintf(f_asm, "    lwi    $r1, [$sp + (%d)]\n", now_stack_pos);
                             now_stack_pos += 4;
                             fprintf(f_asm, "    lwi    $r0, [$sp + (%d)]\n", now_stack_pos);
                             fprintf(f_asm, "    divsr    $r0, $r1, $r0, $r1\n");
                             fprintf(f_asm, "    swi    $r1, [$sp + (%d)]\n", now_stack_pos);
                             now_stack_pos -= 4;
                             if ($1 != $3) {
                                 fprintf(stderr, "Error at line %d: type not matched.\n", lineNum);
                                 exit(1);  
                             }
                             $$ = $1;
                         }
                       | '-' expr_with_no_func_call %prec uminus
                         {
                             now_stack_pos += 4;
                             fprintf(f_asm, "    lwi    $r1, [$sp + (%d)]\n", now_stack_pos);
                             fprintf(f_asm, "    movi    $r0, 0\n");
                             fprintf(f_asm, "    sub    $r0, $r0, $r1\n");
                             fprintf(f_asm, "    swi    $r0, [$sp + (%d)]\n", now_stack_pos);
                             now_stack_pos -= 4;
                             $$ = $2;
                         }
                       | expr_with_no_func_call plus_plus
                         {
                             now_stack_pos += 4;
                             fprintf(f_asm, "    lwi    $r0, [$sp + (%d)]\n", now_stack_pos);
                             fprintf(f_asm, "    addi    $r0, $r0, 1\n");
                             fprintf(f_asm, "    swi    $r0, [$sp + (%d)]\n", now_stack_pos);
                             now_stack_pos -= 4;
                             $$ = $1;
                         }
                       | expr_with_no_func_call minus_minus
                         {
                             now_stack_pos += 4;
                             fprintf(f_asm, "    lwi    $r0, [$sp + (%d)]\n", now_stack_pos);
                             fprintf(f_asm, "    subi    $r0, $r0, 1\n");
                             fprintf(f_asm, "    swi    $r0, [$sp + (%d)]\n", now_stack_pos);
                             now_stack_pos -= 4;
                             $$ = $1;
                         }
                       | id
                         {
                             int index = look_up_symbol($1);
                             if (index == -1 || table[index].status == FUNC) {
                                 fprintf(stderr, "Error at line %d: symbol not found.\n", lineNum);
                                 exit(1);
                             }
                             fprintf(f_asm, "    lwi    $r0, [$sp + (%d)]\n", table[index].var_counter * 4);
                             fprintf(f_asm, "    swi    $r0, [$sp + (%d)]\n", now_stack_pos);
                             now_stack_pos -= 4;
                             $$ = table[index].type;
                         }
                       | id arr_dim_expr_with_no_func_call
                         {
                             fprintf(stderr, "Error at line %d: array is not allowed.\n", lineNum);
                             exit(1);
                         }
                       | int_constant
                         {
                             fprintf(f_asm, "    movi    $r0, %d\n", $1);
                             fprintf(f_asm, "    swi    $r0, [$sp + (%d)]\n", now_stack_pos);
                             now_stack_pos -= 4;
                             $$ = int_type;
                         }
                       | char_constant
                         {
                             fprintf(stderr, "Error at line %d: not allowed type.\n", lineNum);
                             exit(1);
                         }
                       | double_constant
                         {
                             $$ = double_type;
                         }
                       | other_constant
                         {
                             fprintf(stderr, "Error at line %d: not allowed type.\n", lineNum);
                             exit(1);
                         }
                       | '(' expr_with_no_func_call ')'
                         {
                             $$ = $2;
                         }
                       ;

%%

void gen_assembly_header() {
    fprintf(f_asm, "    .file    \"unknown.cpp\"\n");
    fprintf(f_asm, "    ! ABI version\n");
    fprintf(f_asm, "    .abi_2\n");
    fprintf(f_asm, "    ! This asm file is generated by Taffy's compiler\n");
    fprintf(f_asm, "    .flag    verbatim\n");
    fprintf(f_asm, "    ! This vector size directive is required for checking inconsistency on interrupt handler\n");
    fprintf(f_asm, "    .vec_size	16\n");
    fprintf(f_asm, "    ! ------------------------------------\n");
    fprintf(f_asm, "    ! ISA family        : V3M\n");
    fprintf(f_asm, "    ! Pipeline model    : N8\n");
    fprintf(f_asm, "    ! Code model        : LARGE\n");
    fprintf(f_asm, "    ! Endian setting    : little-endian\n");
    fprintf(f_asm, "    ! Use SP floating-point instruction    : No\n");
    fprintf(f_asm, "    ! Use DP floating-point instruction    : No\n");
    fprintf(f_asm, "    ! ABI version    : ABI2\n");
    fprintf(f_asm, "    ! ------------------------------------\n");
    fprintf(f_asm, "    ! Use conditional move           : Yes\n");
    fprintf(f_asm, "    ! Use performance extension      : No\n");
    fprintf(f_asm, "    ! Use performance extension 2    : No\n");
    fprintf(f_asm, "    ! Use string extension           : No\n");
    fprintf(f_asm, "    ! ------------------------------------\n");
    fprintf(f_asm, "    ! V3PUSH instructions      : No\n");
    fprintf(f_asm, "    ! 16-bit instructions      : No\n");
    fprintf(f_asm, "    ! Reduced registers set    : Yes\n");
    fprintf(f_asm, "    ! ------------------------------------\n");
    fprintf(f_asm, "    ! Optimization level    : -O0\n");
    fprintf(f_asm, "    ! ------------------------------------\n");
    fprintf(f_asm, "    ! Cache block size    : 16\n");
    fprintf(f_asm, "    ! ------------------------------------\n");
}

void gen_assembly_tail() {
    fprintf(f_asm, "    .ident    \"REDUCED GCC: (2017-05-21_taffy_compiler) 1.0.0\"\n");
    fprintf(f_asm, "    ! ------------------------------------\n");
}

int main() {
    int index;
    if ((f_asm = fopen(FILE_NAME, "w")) == NULL) {
        fprintf(stderr, "Can not open the file %s for writing.\n", FILE_NAME);
    }
    init_symbol_table();
    //---//
    install_symbol("pinMode", FUNC);
    index = look_up_symbol("pinMode");
    table[index].para_type[table[index].para_num++] = int_type;
    table[index].para_type[table[index].para_num++] = int_type;
    table[index].label_name = (char *) copys("pinMode");
    //---//
    install_symbol("digitalWrite", FUNC);
    index = look_up_symbol("digitalWrite");
    table[index].para_type[table[index].para_num++] = int_type;
    table[index].para_type[table[index].para_num++] = int_type;
    table[index].label_name = (char *) copys("digitalWrite");
    //---//
    install_symbol("delay", FUNC);
    index = look_up_symbol("delay");
    table[index].para_type[table[index].para_num++] = int_type;
    table[index].label_name = (char *) copys("delay");
    //---//
    gen_assembly_header();
    yyparse();
    if (func_def_counter == 0 || commentMatched == 0 || quoteMatched == 0) {
        yyerror("");
    }
    printf("No syntax error!\n");
    gen_assembly_tail();
    fclose(f_asm);
    return 0;
}

int yyerror(char *msg) {
	fprintf(stderr, "______ Error at line %d: %s\n", lineNum, buffer);
	fprintf(stderr, "\n" );
	fprintf(stderr, "Unmatched token: %s\n", yytext);
	fprintf(stderr, "______ syntax error\n");
	exit(-1);
}
