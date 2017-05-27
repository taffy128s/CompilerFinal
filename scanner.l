%{
#include <stdio.h>
#include <string.h>
#include "y.tab.h"
#define MAXLEN 4096
char buffer[MAXLEN] = {0};
int bufferIdx = 0, commentMatched = 1, quoteMatched = 1;
int sourceOn = 1, tokenOn = 1, lineNum = 1;
void putInBuffer(char *input) {
    int len = strlen(input), i;
    for (i = 0; i < len; i++) {
        if (bufferIdx >= MAXLEN) {
            fprintf(stderr, "Buffer overflow!\n");
            exit(-1);
        } else {
            buffer[bufferIdx++] = input[i];
        }
    }
}
void printAndInit() {
    if (sourceOn) printf("%d:%s\n", lineNum, buffer);
    memset(buffer, 0, sizeof(buffer));
    bufferIdx = 0;
}
void printToken(char *type) {
    if (tokenOn) printf("#%s:%s\n", type, yytext);
}
%}

%x COMMENT_ONE
%x COMMENT_MUL
%x STRING

%%
#[ \t]*pragma[ \t]+source[ \t]+on  {putInBuffer(yytext); sourceOn = 1; BEGIN 0; }
#[ \t]*pragma[ \t]+source[ \t]+off {putInBuffer(yytext); sourceOn = 0; BEGIN 0; }
#[ \t]*pragma[ \t]+token[ \t]+on   {putInBuffer(yytext); tokenOn = 1; BEGIN 0; }
#[ \t]*pragma[ \t]+token[ \t]+off  {putInBuffer(yytext); tokenOn = 0; BEGIN 0; }
#[ \t]*include.*                   {putInBuffer(yytext); fprintf(stderr, "______#include detected, but will ignore it\n"); }
#.*                                {fprintf(stderr, "Error at line %d: %s\n", lineNum, yytext); exit(-1); }

void        {printToken("key"); putInBuffer(yytext); return void_type; }
int         {printToken("key"); putInBuffer(yytext); return int_type; }
double      {printToken("key"); putInBuffer(yytext); return double_type; }
bool        {printToken("key"); putInBuffer(yytext); return bool_type; }
char        {printToken("key"); putInBuffer(yytext); return char_type; }
null        {printToken("key"); putInBuffer(yytext); }
for         {printToken("key"); putInBuffer(yytext); return for_key; }
while       {printToken("key"); putInBuffer(yytext); return while_key; }
do          {printToken("key"); putInBuffer(yytext); return do_key; }
if          {printToken("key"); putInBuffer(yytext); return if_key; }
else        {printToken("key"); putInBuffer(yytext); return else_key; }
switch      {printToken("key"); putInBuffer(yytext); return switch_key; }
return      {printToken("key"); putInBuffer(yytext); return return_key; }
break       {printToken("key"); putInBuffer(yytext); return break_key; }
continue    {printToken("key"); putInBuffer(yytext); return continue_key; }
const       {printToken("key"); putInBuffer(yytext); return const_prefix; }
true        {printToken("key"); putInBuffer(yytext); return other_constant; }
false       {printToken("key"); putInBuffer(yytext); return other_constant; }
struct      {printToken("key"); putInBuffer(yytext); }
case        {printToken("key"); putInBuffer(yytext); return case_key; }
default     {printToken("key"); putInBuffer(yytext); return default_key; }

fclose      {printToken("key"); putInBuffer(yytext); yylval.ident = (char *) copys(yytext); return id; }
clearerr    {printToken("key"); putInBuffer(yytext); yylval.ident = (char *) copys(yytext); return id; }
feof        {printToken("key"); putInBuffer(yytext); yylval.ident = (char *) copys(yytext); return id; }
ferror      {printToken("key"); putInBuffer(yytext); yylval.ident = (char *) copys(yytext); return id; }
fflush      {printToken("key"); putInBuffer(yytext); yylval.ident = (char *) copys(yytext); return id; }
fgetpos     {printToken("key"); putInBuffer(yytext); yylval.ident = (char *) copys(yytext); return id; }
fopen       {printToken("key"); putInBuffer(yytext); yylval.ident = (char *) copys(yytext); return id; }
fread       {printToken("key"); putInBuffer(yytext); yylval.ident = (char *) copys(yytext); return id; }
freopen     {printToken("key"); putInBuffer(yytext); yylval.ident = (char *) copys(yytext); return id; }
fseek       {printToken("key"); putInBuffer(yytext); yylval.ident = (char *) copys(yytext); return id; }
fsetpos     {printToken("key"); putInBuffer(yytext); yylval.ident = (char *) copys(yytext); return id; }
ftell       {printToken("key"); putInBuffer(yytext); yylval.ident = (char *) copys(yytext); return id; }
fwrite      {printToken("key"); putInBuffer(yytext); yylval.ident = (char *) copys(yytext); return id; }
remove      {printToken("key"); putInBuffer(yytext); yylval.ident = (char *) copys(yytext); return id; }
rename      {printToken("key"); putInBuffer(yytext); yylval.ident = (char *) copys(yytext); return id; }
rewind      {printToken("key"); putInBuffer(yytext); yylval.ident = (char *) copys(yytext); return id; }
setbuf      {printToken("key"); putInBuffer(yytext); yylval.ident = (char *) copys(yytext); return id; }
setvbuf     {printToken("key"); putInBuffer(yytext); yylval.ident = (char *) copys(yytext); return id; }
tmpfile     {printToken("key"); putInBuffer(yytext); yylval.ident = (char *) copys(yytext); return id; }
tmpnam      {printToken("key"); putInBuffer(yytext); yylval.ident = (char *) copys(yytext); return id; }
fprintf     {printToken("key"); putInBuffer(yytext); yylval.ident = (char *) copys(yytext); return id; }
printf      {printToken("key"); putInBuffer(yytext); yylval.ident = (char *) copys(yytext); return id; }
sprintf     {printToken("key"); putInBuffer(yytext); yylval.ident = (char *) copys(yytext); return id; }
vfprintf    {printToken("key"); putInBuffer(yytext); yylval.ident = (char *) copys(yytext); return id; }
vprintf     {printToken("key"); putInBuffer(yytext); yylval.ident = (char *) copys(yytext); return id; }
vsprintf    {printToken("key"); putInBuffer(yytext); yylval.ident = (char *) copys(yytext); return id; }
fscanf      {printToken("key"); putInBuffer(yytext); yylval.ident = (char *) copys(yytext); return id; }
scanf       {printToken("key"); putInBuffer(yytext); yylval.ident = (char *) copys(yytext); return id; }
sscanf      {printToken("key"); putInBuffer(yytext); yylval.ident = (char *) copys(yytext); return id; }
fgetc       {printToken("key"); putInBuffer(yytext); yylval.ident = (char *) copys(yytext); return id; }
fgets       {printToken("key"); putInBuffer(yytext); yylval.ident = (char *) copys(yytext); return id; }
fputc       {printToken("key"); putInBuffer(yytext); yylval.ident = (char *) copys(yytext); return id; }
fputs       {printToken("key"); putInBuffer(yytext); yylval.ident = (char *) copys(yytext); return id; }
getc        {printToken("key"); putInBuffer(yytext); yylval.ident = (char *) copys(yytext); return id; }
getchar     {printToken("key"); putInBuffer(yytext); yylval.ident = (char *) copys(yytext); return id; }
gets        {printToken("key"); putInBuffer(yytext); yylval.ident = (char *) copys(yytext); return id; }
putc        {printToken("key"); putInBuffer(yytext); yylval.ident = (char *) copys(yytext); return id; }
putchar     {printToken("key"); putInBuffer(yytext); yylval.ident = (char *) copys(yytext); return id; }
puts        {printToken("key"); putInBuffer(yytext); yylval.ident = (char *) copys(yytext); return id; }
ungetc      {printToken("key"); putInBuffer(yytext); yylval.ident = (char *) copys(yytext); return id; }
perror      {printToken("key"); putInBuffer(yytext); yylval.ident = (char *) copys(yytext); return id; }

[a-zA-Z_][0-9a-zA-Z_]*  {printToken("id"); putInBuffer(yytext); if (!strcmp(yytext, "HIGH") || !strcmp(yytext, "OUTPUT")) {yylval.integer = 1; return int_constant; } else if (!strcmp(yytext, "LOW")) {yylval.integer = 0; return int_constant; } else { yylval.ident = (char *) copys(yytext); return id; } }

"+"         {printToken("op"); putInBuffer(yytext); return '+'; }
"-"         {printToken("op"); putInBuffer(yytext); return '-'; }
"*"         {printToken("op"); putInBuffer(yytext); return '*'; }
"/"         {printToken("op"); putInBuffer(yytext); return '/'; }
"%"         {printToken("op"); putInBuffer(yytext); return '%'; }
"++"        {printToken("op"); putInBuffer(yytext); return plus_plus; }
"--"        {printToken("op"); putInBuffer(yytext); return minus_minus; }
"<"         {printToken("op"); putInBuffer(yytext); return '<'; }
"<="        {printToken("op"); putInBuffer(yytext); return less_equal; }
">"         {printToken("op"); putInBuffer(yytext); return '>'; }
">="        {printToken("op"); putInBuffer(yytext); return bigger_equal; }
"=="        {printToken("op"); putInBuffer(yytext); return equal_equal; }
"!="        {printToken("op"); putInBuffer(yytext); return not_equal; }
"="         {printToken("op"); putInBuffer(yytext); return '='; }
"&&"        {printToken("op"); putInBuffer(yytext); return and_and; }
"||"        {printToken("op"); putInBuffer(yytext); return or_or; }
"!"         {printToken("op"); putInBuffer(yytext); return '!'; }
"&"         {printToken("op"); putInBuffer(yytext); return '&'; }

":"         {printToken("punc"); putInBuffer(yytext); return ':'; }
";"         {printToken("punc"); putInBuffer(yytext); return ';'; }
","         {printToken("punc"); putInBuffer(yytext); return ','; }
"."         {printToken("punc"); putInBuffer(yytext); return '.'; }
"["         {printToken("punc"); putInBuffer(yytext); return '['; }
"]"         {printToken("punc"); putInBuffer(yytext); return ']'; }
"("         {printToken("punc"); putInBuffer(yytext); return '('; }
")"         {printToken("punc"); putInBuffer(yytext); return ')'; }
"{"         {printToken("punc"); putInBuffer(yytext); return '{'; }
"}"         {printToken("punc"); putInBuffer(yytext); return '}'; }

[0][0-9]+                                  {fprintf(stderr, "Error at line %d: %s\n", lineNum, yytext); exit(-1); }
[0-9]+[a-zA-Z_]+                           {fprintf(stderr, "Error at line %d: %s\n", lineNum, yytext); exit(-1); }
[0-9]+                                     {printToken("integer"); putInBuffer(yytext); yylval.integer = atoi(yytext); return int_constant; }
[0-9]*[.][0-9]+[a-zA-Z_.]+                 {fprintf(stderr, "Error at line %d: %s\n", lineNum, yytext); exit(-1); }
[0-9]+[.][a-zA-Z_.]+                       {fprintf(stderr, "Error at line %d: %s\n", lineNum, yytext); exit(-1); }
[0-9]*[.][0-9]+                            {printToken("double"); putInBuffer(yytext); return double_constant; }
[0-9]+[.]                                  {printToken("double"); putInBuffer(yytext); return double_constant; }
[0-9]*[.][0-9]+[eE][+-]?[0-9]+[a-zA-Z_.]+  {fprintf(stderr, "Error at line %d: %s\n", lineNum, yytext); exit(-1); }
[0-9]+[.][eE][+-]?[0-9]+[a-zA-Z_.]+        {fprintf(stderr, "Error at line %d: %s\n", lineNum, yytext); exit(-1); }
[0-9]+[eE][+-]?[0-9]+[a-zA-Z_.]+           {fprintf(stderr, "Error at line %d: %s\n", lineNum, yytext); exit(-1); }
[0-9]*[.][0-9]+[eE][+-]?[0-9]+             {printToken("sci"); putInBuffer(yytext); return other_constant; }
[0-9]+[.][eE][+-]?[0-9]+                   {printToken("sci"); putInBuffer(yytext); return other_constant; }
[0-9]+[eE][+-]?[0-9]+                      {printToken("sci"); putInBuffer(yytext); return other_constant; }
[']\\n[']                            {printToken("char"); putInBuffer(yytext); return char_constant; }
[']\\t[']                            {printToken("char"); putInBuffer(yytext); return char_constant; }
[']\\[']                             {fprintf(stderr, "Error at line %d: %s\n", lineNum, yytext); exit(-1); }
[0-9a-zA-Z_.]+['].[']                {fprintf(stderr, "Error at line %d: %s\n", lineNum, yytext); exit(-1); }
['].['][0-9a-zA-Z_.]+                {fprintf(stderr, "Error at line %d: %s\n", lineNum, yytext); exit(-1); }
['].[']                              {printToken("char"); putInBuffer(yytext); return char_constant; }
[0-9a-zA-Z_.]["].*["]                {fprintf(stderr, "Error at line %d: %s\n", lineNum, yytext); exit(-1); }
["].*["][0-9a-zA-Z_.]                {fprintf(stderr, "Error at line %d: %s\n", lineNum, yytext); exit(-1); }
\"                                   {if (tokenOn) printf("#string:"); putInBuffer(yytext); quoteMatched = 0; BEGIN STRING; }
<STRING>\"                           {if (tokenOn) printf("\n"); putInBuffer(yytext); quoteMatched = 1; BEGIN 0; return other_constant; }
<STRING>\\n                          {if (tokenOn) ECHO; putInBuffer(yytext); }
<STRING>\\t                          {if (tokenOn) ECHO; putInBuffer(yytext); }
<STRING>\\                           {fprintf(stderr, "Error at line %d: %s\n", lineNum, yytext); exit(-1); }
<STRING>\n                           {fprintf(stderr, "Error at line %d: %s\n", lineNum, yytext); exit(-1); }
<STRING>.                            {if (tokenOn) ECHO; putInBuffer(yytext); }

"//"                {putInBuffer(yytext); BEGIN COMMENT_ONE; }
<COMMENT_ONE>\n     {printAndInit(); lineNum++; BEGIN 0; }
<COMMENT_ONE>.      {putInBuffer(yytext); }
"/*"                {putInBuffer(yytext); commentMatched = 0; BEGIN COMMENT_MUL; }
<COMMENT_MUL>"*/"   {putInBuffer(yytext); commentMatched = 1; BEGIN 0; }
<COMMENT_MUL>\n     {printAndInit(); lineNum++; }
<COMMENT_MUL>.      {putInBuffer(yytext); }
" "                 {putInBuffer(yytext); }
\t                  {putInBuffer(yytext); }
\n                  {printAndInit(); lineNum++; }
.                   {fprintf(stderr, "Error at line %d: %s\n", lineNum, yytext); exit(-1); }
%%

/*int main(int argc, char *argv[]) {
    yylex();
    if (commentMatched == 0 || quoteMatched == 0) {
        fprintf(stderr, "Error at line %d: %s\n", lineNum, yytext);
        exit(-1);
    }
    return 0;
}*/

int yywrap() {
    return 1;
}
