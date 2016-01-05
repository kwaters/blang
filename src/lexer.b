/* vim: set ft=blang : */

/* Token format.

    KIND VALUE[0] VALUE[1]
*/

/* Token kinds. */
/*
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
*/

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
    if (lIsDigit(c))
        return (1);
    if (lIsAlpha(c))
        return (1);
    return (0);
}

/* Get the next character of the input, or '*e' if it's empty. */
lGetC() {
}

/* Return the last character to the input. */
lReplace(char) {
}

lError(char) {
    exit();
}

/* Eat whitespace and comments. */
lEatWhte(tok) {
    auto c, peek;

loop:
    switch (c = lGet(C)) {
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
        return (lString());

    case '/':
        lError("ICE. *"/*" should be consumed by lEatWhte()");
    }

    if (!lOp(tok, 0))
        return (0);

    lError("Unexpected character");
    return (1);
}

/* Parse a number. |c| should be the first character of the number. */
lNumber(c, tok) {
    extrn T_NUMBER;
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
    auto i;

    i = 0;
    while (IsIdent(c)) {
        if (i < 8)
            lchar(tok + 1, i++, c);
    }
    lReplace(c);

    /* Test for keywords. */
    if (tok[1] == 'auto' & tok[2] == 0)
        tok[0] = T_AUTO;
    else if (tok[1] == 'case' & tok[2] == 0)
        tok[0] = T_CASE;
    else if (tok[1] == 'else' & tok[2] == 0)
        tok[0] = T_ELSE;
    else if (tok[1] == 'extr' & tok[2] == 'n')
        tok[0] = T_EXTRN;
    else if (tok[1] == 'goto' & tok[2] == 0)
        tok[0] = T_GOTO;
    else if (tok[1] == 'if' & tok[2] == 0)
        tok[0] = T_IF;
    else if (tok[1] == 'retu' & tok[2] == 'rn')
        tok[0] = T_RETURN;
    else if (tok[1] == 'swit' & tok[2] == 'ch')
        tok[0] = T_SWITCH;
    else if (tok[1] == 'whil' & tok[2] == 'e')
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
    auto i;

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
        if (i < 4)
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
    auto i, c, s, newS, limit;

    limit = 8;
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
        if (i + 1 > 4 * limit) {
            newS = getvec(limit * 2 + 1) + 1;
            memcpy(newS, s, limit);
            rlsevec(s - 1, limit);
            s = newS;
            limit =* 2;
        }
        lchar(s, i++, c);
    }

    /* Terminate string. */
    lchar(s, i, '*e');
    s[-1] = limit;

    tok[0] = T_STRING;
    tok[1] = s;
    tok[2] = i;
    return (0);
}

/* Parse a unary or binary operator. Recurses for assignment operators. */
lOp(tok, assign) {
    extrn T_ASSIGN, T_NEQ, T_EQ, T_LTE, T_GTE, T_SHIFTL, T_SHIFTR,
          T_DEC, T_INC;
    auto c, peek;

    tok[0] = 0;

    c = lGetC();
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
            return (BinOp(tok, 1));
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
