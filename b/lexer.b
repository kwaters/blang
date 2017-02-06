/* vim: set ft=blang : */

/* Token format.

    KIND VALUE[0] VALUE[1]
*/

/* Token kinds. */
T_ASSIGN 258;
T_CHAR   259;
T_DEC    260;
T_EQ     261;
T_GTE    262;
T_INC    263;
T_LTE    264;
T_NAME   265;
T_NEQ    266;
T_NUMBER 267;
T_SHIFTL 268;
T_SHIFTR 269;
T_STRING 270;
T_AUTO   271;
T_CASE   272;
T_ELSE   273;
T_EXTRN  274;
T_GOTO   275;
T_IF     276;
T_RETURN 277;
T_SWITCH 278;
T_WHILE  279;

lIsAlpha(c) {
    if (c >= 'A' & c <= 'Z')
        return (1);
    if (c >= 'a' & c <= 'z')
        return (1);
    if (c == '_')
        return (1);
    if (c == '.')
        return (1);
    return (0);
}

lIsDigit(c) {
    if (c < '0')
        return (0);
    if (c > '9')
        return (0);
    return (1);
}

lIsIdent(c) {
    extrn lIsDigit, lIsAlpha;

    if (lIsDigit(c))
        return (1);
    if (lIsAlpha(c))
        return (1);
    return (0);
}

/* Get the next character of the input, or '*e' if it's empty. */
lGetC() {
    extrn ibGet;
    return (ibGet());
}

/* Return the last character to the input. */
lReplace(char) {
    extrn ibUnget;
    ibUnget(char);
}

lError(char) {
    extrn exit;
    exit();
}

/* Eat whitespace and comments. */
lEatWhte(tok) {
    extrn lGetC, lReplace, lComment;
    auto c, peek;

loop:
    switch (c = lGetC()) {
    case ' ':
    case '*t':
    case '*n':
        goto loop;

    case '/':
        if ((peek = lGetC()) == '**') {
            lComment();
            goto loop;
        }

        /* Token is "/" not followed by "*". */
        lReplace(peek);
        tok[0] = '/';
        return (0);
    }

    lReplace(c);
    return (1);
}

/* Consume a comment after "/" "*". */
lComment() {
    extrn lGetC, lError;
    auto c;

state1:
    switch (lGetC()) {
    case '**':
        goto state2;
    case '*e':
        goto error;
    }
    goto state1;

state2:
    switch (lGetC()) {
    case '/':
        return;
    case '**':
        goto state2;
    case '*e':
        goto error;
    }
    goto state1;

error:
    lError("Unterminated comment");
}

/* Get the next token. */
lMain(tok) {
    extrn lEatWhte, lChar, lError, lGetC, lIsAlpha, lIsDigit, lName, lNumber,
          lOp, lString;
    auto c;

    tok[1] = tok[2] = 0;

    if (!lEatWhte(tok))
        return (0);

    c = lGetC();
    if (lIsDigit(c))
        return (lNumber(c, tok));

    if (lIsAlpha(c))
        return (lName(c, tok));

    switch (c) {
    case '*e':
    case '{':
    case '}':
    case '[':
    case ']':
    case '(':
    case ')':
    case '|':
    case '?':
    case ':':
    case ',':
    case ';':
        tok[0] = c;
        return (0);

    case '*'':
        return (lChar(tok));

    case '*"':
        return (lString(tok));

    case '/':
        lError("ICE. *"/*" should be consumed by lEatWhte()");
    }

    if (!lOp(c, tok, 0))
        return (0);

    lError("Unexpected character");
    return (1);
}

/* Parse a number. |c| should be the first character of the number. */
lNumber(c, tok) {
    extrn T_NUMBER;
    extrn lIsDigit, lGetC, lReplace;
    auto base, num;

    base = c == '0' ? 8 : 10;
    num = 0;

    while (lIsDigit(c)) {
        num = base * num + c - '0';
        c = lGetC();
    }
    lReplace(c);

    tok[0] = T_NUMBER;
    tok[1] = num;
}

lName(c, tok) {
    extrn T_AUTO, T_CASE, T_ELSE, T_EXTRN, T_GOTO, T_IF, T_RETURN, T_SWITCH,
          T_WHILE, T_NAME;
    extrn lchar;
    extrn lIsIdent, lReplace, lGetC;
    auto i;

    i = 0;
    while (lIsIdent(c)) {
        if (i < 8)
            lchar(tok + 1, i++, c);
        c = lGetC();
    }
    lReplace(c);

    /* Test for keywords. */
    if (tok[1] == 'auto')
        tok[0] = T_AUTO;
    else if (tok[1] == 'case')
        tok[0] = T_CASE;
    else if (tok[1] == 'else')
        tok[0] = T_ELSE;
    else if (tok[1] == 'extrn')
        tok[0] = T_EXTRN;
    else if (tok[1] == 'goto')
        tok[0] = T_GOTO;
    else if (tok[1] == 'if')
        tok[0] = T_IF;
    else if (tok[1] == 'return')
        tok[0] = T_RETURN;
    else if (tok[1] == 'switch')
        tok[0] = T_SWITCH;
    else if (tok[1] == 'while')
        tok[0] = T_WHILE;
    else
        tok[0] = T_NAME;

    return (0);
}

lEscape(c) {
    switch (c) {
    case '0':
        return ('*0');
    case 'e':
        return ('*e');
    case '(':
        return ('*(');
    case ')':
        return ('*)');
    case 't':
        return ('*t');
    case 'n':
        return ('*n');
    }
    return (c);
}

/* Parse a character constant. */
lChar(tok) {
    extrn T_CHAR;
    extrn lchar;
    extrn lGetC, lEscape, lError;
    auto c, i;

    i = 0;
    while (1) {
        switch (c = lGetC()) {
        case '**':
            c = lEscape(lGetC());
            goto break;

        case '*'':
            goto exit;

        case '*e':
            lError("Unterminated character constant");

        case '*n':
            /* TODO: Is this right? */
            lError("Newline not allowed in character constant");
        }
break:
        if (i < 8)
            lchar(tok + 1, i++, c);
    }
exit:
    tok[0] = T_CHAR;
    return (0);
}

/* Parse a string.
 *
 * tok[1] is a pointer to the character data of the decoded string.  It must
 * be freed using, "rlsevec(tok[1] - 1, tok[1][-1]);"
 * tok[2] is the length of the string.
 */
lString(tok) {
    extrn T_STRING;
    extrn getvec, rlsevec, memcpy, lchar;
    extrn lGetC, lEscape, lError;
    extrn printf;
    auto i, c, s, newS, limit;

    limit = 4;
    s = getvec(limit + 1) + 1;

    i = 0;
    while (1) {
        switch (c = lGetC()) {
        case '**':
            c = lEscape(lGetC());
            goto break;

        case '"':
            goto exit;

        case '*e':
            lError("Unterminated string constant");

        case '*n':
            lError("Newline not allowed in character constant");
        }
break:
        /* Reserve space for the terminating '*e' */
        if (i + 2 > 8 * limit) {
            newS = getvec(limit * 2 + 1) + 1;
            memcpy(newS, s, limit);
            rlsevec(s - 1, limit);
            s = newS;
            limit =* 2;
        }
        lchar(s, i++, c);
    }

exit:
    /* Terminate string. */
    lchar(s, i, '*e');
    s[-1] = limit;

    tok[0] = T_STRING;
    tok[1] = s;
    tok[2] = i + 1;
    return (0);
}

/* Parse a unary or binary operator. Recurses for assignment operators. */
lOp(c, tok, assign) {
    extrn T_ASSIGN, T_NEQ, T_EQ, T_LTE, T_GTE, T_SHIFTL, T_SHIFTR,
          T_DEC, T_INC;
    extrn lGetC, lReplace;
    auto peek;

    tok[0] = 0;

    switch (c) {
    case '**':
    case '/':
    case '%':
    case '&':
    case '|':
    case '~':
        tok[0] = c;
        goto break;

    case '+':
        if (!assign) {
            if ((peek = lGetC()) == '+') {
                tok[0] = T_INC;
                return (0);
            } else {
                lReplace(peek);
            }
        }
        tok[0] = c;
        goto break;

    case '-':
        if (!assign) {
            if ((peek = lGetC()) == '-') {
                tok[0] = T_DEC;
                return (0);
            } else {
                lReplace(peek);
            }
        }
        tok[0] = c;
        goto break;

    case '=':
        if (assign) {
            tok[0] = T_EQ;
            if ((peek = lGetC()) != '=') {
                lReplace(peek);
                assign = 0;
            }
            goto break;
        } else {
            return (lOp(lGetC(), tok, 1));
        }

    case '<':
        if ((peek = lGetC()) == '=') {
            tok[0] = T_LTE;
        } else if (peek == '<') {
            tok[0] = T_SHIFTL;
        } else {
            tok[0] = c;
            lReplace(peek);
        }
        goto break;

    case '>':
        if ((peek = lGetC()) == '=') {
            tok[0] = T_GTE;
        } else if (peek == '>') {
            tok[0] = T_SHIFTR;
        } else {
            tok[0] = c;
            lReplace(peek);
        }
        goto break;

    case '!':
        if ((peek = lGetC()) == '=') {
            tok[0] = T_NEQ;
        } else if (assign) {
            /* a =! b parses as "=" "!", while a =!= b parses as "=!=". */
            lReplace(peek);
            lReplace(c);
        } else {
            tok[0] = '!';
        }
        goto break;
    }
break:

    if (assign) {
        tok[1] = tok[0];
        tok[0] = T_ASSIGN;
        return (0);
    }
    return (tok[0] == 0);
}


lPrint(tok) {
    extrn printf, putchar;
    extrn lPTKind, lPStr;
    auto x, kind;

    kind = tok[0];
    lPTKind(kind);

    switch (kind) {
    case 258:  /* ASSIGN */
        printf("  ");
        if (tok[1])
            lPTKind(tok[1]);
        goto break;

    case 259:  /* CHAR */
    case 267:  /* NUMBER */
        printf("  %d*n", tok[1]);
        return;

    case 265:  /* NAME */
        printf("  ");
        x = tok[1];
        while (x > 0) {
            putchar(x & 0377);
            x =>> 8;
        }
        goto break;

    case 270:  /* STRING */
        printf("  ");
        lPStr(tok[1], tok[2]);
        goto break;
    }
break:
    printf("*n");
}

/* Print token kind padded out to 6 characters. */
lPTKind(kind) {
    extrn printf, ice;

    if (kind == '*e') {
        printf("EOF     ");
        return;
    } else if (kind < 256) {
        printf("'%c'     ", kind);
        return;
    }

    switch (kind) {
    case 258: printf("T_ASSIGN"); return;
    case 259: printf("T_CHAR  "); return;
    case 260: printf("T_DEC   "); return;
    case 261: printf("T_EQ    "); return;
    case 262: printf("T_GTE   "); return;
    case 263: printf("T_INC   "); return;
    case 264: printf("T_LTE   "); return;
    case 265: printf("T_NAME  "); return;
    case 266: printf("T_NEQ   "); return;
    case 267: printf("T_NUMBER"); return;
    case 268: printf("T_SHIFTL"); return;
    case 269: printf("T_SHIFTR"); return;
    case 270: printf("T_STRING"); return;
    case 271: printf("T_AUTO  "); return;
    case 272: printf("T_CASE  "); return;
    case 273: printf("T_ELSE  "); return;
    case 274: printf("T_EXTRN "); return;
    case 275: printf("T_GOTO  "); return;
    case 276: printf("T_IF    "); return;
    case 277: printf("T_RETURN"); return;
    case 278: printf("T_SWITCH"); return;
    case 279: printf("T_WHILE "); return;
    }
    ice("Invalid token kind.");
}

/* print escaped string */
lPStr(base, len)
{
    extrn putchar, printf, char;
    auto i, c;

    putchar('"');

    i = 0;
    while (i < len) {
        c = char(base, i++);
        switch (c) {
        case '**': printf("****"); goto loop;
        case '*'': printf("***'"); goto loop;
        case '*"': printf("***""); goto loop;
        }

        if (c >= 040 & c <= 0177) {
            putchar(c);
        } else {
            putchar('**');
            switch (c) {
            case '*0': putchar('0'); goto loop;
            case '*e': putchar('e'); goto loop;
            case '*t': putchar('t'); goto loop;
            case '*n': putchar('n'); goto loop;
            }
            /* default case */
            putchar('?');
        }
loop: ;
    }

    putchar('"');
}
