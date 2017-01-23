%{
#include "base.h"
#include "blang.tab.h"

union yylval_t {
    int assign_op;
    I number;
    I name;
    struct {
        char *s;
        size_t len;
    } str;
};
YYSTYPE yylval;

static char unescape(char c);
static I parse_number(I base);
static I parse_name(char *name);

%}

%x comment
%x character
%x string

%{
    static I char_lit;
    static int char_shift;

    static char string_buf[8192];
    static char *string_p;
%}
%%

 /* whitespace */
[ \t\n]+

 /* comment */
"/*"    BEGIN(comment);
<comment>{
    [^*]+
    \*
    "*/"  BEGIN(INITIAL);
}

 /* character literal */
' {
    char_lit = 0;
    char_shift = 0;
    BEGIN(character);
}
<character>{
    \*. {
        char_lit |= (I)unescape(yytext[1]) << char_shift;
        char_shift += 8;
    }
    [^'*\n] {
        char_lit |= (I)yytext[0] << char_shift;
        char_shift += 8;
    }
    ' {
        BEGIN(INITIAL);
        yylval.num = char_lit;
        return CHAR;
    }
    . abort();
    <<EOF>>  abort();
}

 /* string literal */
\" {
    string_p = string_buf;
    BEGIN(string);
}
<string>{
    \*.     *string_p++ = unescape(yytext[1]);
    [^"*\n]+ {
        memcpy(string_p, yytext, yyleng);
        string_p += yyleng;
    }
    \n      abort();
    \" {
        BEGIN(INITIAL);
        *string_p++ = '\x04';
        yylval.str.s = string_buf;
        yylval.str.len = string_p - string_buf;
        return STRING;
    }
    . abort();
    <<EOF>>  abort();
}

 /* number */
[1-9][0-9]* return parse_number(10);
0[0-9]*     return parse_number(8);

 /* keywords */
auto    return AUTO;
case    return CASE;
else    return ELSE;
extrn   return EXTRN;
goto    return GOTO;
if      return IF;
return  return RETURN;
switch  return SWITCH;
while   return WHILE;

 /* operators */
"++"    return INC;
"--"    return DEC;
"<<"    return SHIFTL;
">>"    return SHIFTR;
"<="    return LTE;
">="    return GTE;
"=="    return EQ;
"!="    return NEQ;
[{}\[\]()*\-&~!+<>&|?:,/%;] {
    return yytext[0];
}

 /* assignment */
"="      yylval.binop = 0;      return ASSIGN;
"=<<"    yylval.binop = SHIFTL; return ASSIGN;
"=>>"    yylval.binop = SHIFTR; return ASSIGN;
"=<="    yylval.binop = LTE;    return ASSIGN;
"=>="    yylval.binop = GTE;    return ASSIGN;
"==="    yylval.binop = EQ;     return ASSIGN;
"=!="    yylval.binop = NEQ;    return ASSIGN;
=[=|&-+%*/] {
    /* TODO: This isn't right. */
    yylval.binop = yytext[0];
    return ASSIGN;
}

 /* name */
[a-z._A-Z][a-z._A-Z0-9]* {
    yylval.name = parse_name(yytext);
    return NAME;
}

 /* lex error */
.       abort();

%%

char unescape(char c)
{
    switch (c) {
        case '0': return '\0';
        case 'e': return '\x04';
        case '(': return '{';
        case ')': return '}';
        case 'n': return '\n';
    }
    return c;
}

I parse_number(I base) {
    int i;
    I out = 0;

    for (i = 0; i < yyleng; i++)
        out = base * out + yytext[i] - '0';
    yylval.num = out;

    return NUMBER;
}

I parse_name(char *name) {
    I x = 0;
    int i;
    char *s;

    // Only the first 8 characters matter.
    for (i = 0, s = name; i < 8 && *s; s++)
        x |= (I)*s << (8 * i++);

    return x;
}

int yywrap()
{
    return 1;
}

#if 0
int main()
{
    char temp[] = " ";
    char *s;
    int token;

    while (token = yylex()) {
        switch (token) {
        case 258: s = "ASSIGN"; break;
        case 259: s = "CHAR"; break;
        case 260: s = "DEC"; break;
        case 261: s = "EQ"; break;
        case 262: s = "GTE"; break;
        case 263: s = "INC"; break;
        case 264: s = "LTE"; break;
        case 265: s = "NAME"; break;
        case 266: s = "NEQ"; break;
        case 267: s = "NUMBER"; break;
        case 268: s = "SHIFTL"; break;
        case 269: s = "SHIFTR"; break;
        case 270: s = "STRING"; break;
        case 271: s = "AUTO"; break;
        case 272: s = "CASE"; break;
        case 273: s = "ELSE"; break;
        case 274: s = "EXTRN"; break;
        case 275: s = "GOTO"; break;
        case 276: s = "IF"; break;
        case 277: s = "RETURN"; break;
        case 278: s = "SWITCH"; break;
        case 279: s = "WHILE"; break;
        default:
            s = temp;
            *s = (char)token;
        }
        printf("token: %s (%d)\n", s, token);
    }
}
#endif
