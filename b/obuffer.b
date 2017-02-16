/* vim: set ft=blang : */

/* Output formatting mini-language.
 *
 * Formats are enclosed in [], characters outside of formats are passed
 * through.
 *
 * Formats take 3 ':' sepreated arguments, all of which are optional.
 *
 * The first field is the '.' seperated path to the variable to print.  The
 * path defaults to 0.
 *
 * ex:
 *    obFmt("[1.3.2]", x)  is equivelent to printn(x[1][3][2])
 *
 * The second field is the name of the formatter.
 *
 * The third field is a sub-formatter, the exact meaning of which depends on
 * the formatter.
 */

obPutc(c) {
    extrn putchar;
    putchar(c);
}

/* Print object using format. */
obFmt(fmt, object) {
    extrn obFmtI;
    obFmtI(fmt, 0, object, 0);
}

/* Format internal.
 *
 * start: The character offset in fmt from the start of the format.
 * maxFP: If this points to a variable, the largest first path argument will be
 * returned through it.
 */
obFmtI(fmt, start, object, maxFP) {
    extrn obSFmt, obPutc;
    extrn printf;
    extrn char;
    extrn ice;
    auto i, c;

    i = start;
    while (1) {
        c = char(fmt, i++);

        if (c == '*e') {
            /* Since sub-parsers have already checked for '*e', we can only hit
             * '*e' at the topmost level. */
            return;
        } else if (c == '[') {
            i = obSFmt(fmt, i, object, maxFP);
        } else if (c == ']') {
            if (start == 0)
                ice("Unexpected ] in format");
            return;
        } else {
            obPutc(c);
        }
    }
}

/* Parse and format a formatting expression.
 *
 * Returns the index of the next character to parse. */
obSFmt(fmt, p, x, maxFP) {
    extrn char, ice;
    extrn printf;
    extrn obPutc, obCmpS, obCNum, obCName, obCList, obCGz, obCBOp, obCUOp,
          obCStr;

    auto object;
    auto cmdS, cmdE, subS;
    auto c;
    auto path;
    auto i;
    auto level;

    object = x;
    cmdS = 0;
    cmdE = 0;

    /* Either this is the top level formater, or we know '[' and ']' are
     * balanced.  If this is the top-level formatter we error on '*e', lower
     * level formatters do not need to check for over-run. */

    path = 0;
    while (1) {
        c = char(fmt, p++);
        if (c == '.') {
            if (maxFP) {
                *maxFP = path > *maxFP ? path : *maxFP;
                maxFP = 0;
            }
            object = object[path];
            path = 0;
        } else if (c == ']') {
            subS = p - 1;
            goto close;
        } else if (c == ':') {
            goto cmdB;
        } else if (c >= '0' & c <= '9') {
            path = 10 * path + c - '0';
        } else {
            ice("Unexpected character.");
        }
    }

cmdB:
    cmdS = p;
    while (1) {
        c = char(fmt, p++);
        if (c == ':') {
            cmdE = p - 1;
            goto subB;
        } else if (c == ']') {
            cmdE = p - 1;
            subS = p - 1;
            goto close;
        } else if (c == '*e') {
            ice("Unexpected end of string.");
        }
    }

subB:
    subS = p;
    level = 0;
    while (1) {
        c = char(fmt, p++);
        if (c == '[')
            level++;
        else if (c == '*e')
            ice("Unexpected end of string");
        else if (c == ']')
            if (--level < 0)
                goto close;
    }

close:
    object = object[path];
    if (maxFP)
        *maxFP = path > *maxFP ? path : *maxFP;

    if (obCmpS("", fmt, cmdS, cmdE))
        obCNum(fmt, subS, object, x);
    else if (obCmpS("name", fmt, cmdS, cmdE))
        obCName(fmt, subS, object, x);
    else if (obCmpS("list", fmt, cmdS, cmdE))
        obCList(fmt, subS, object, x);
    else if (obCmpS("lb", fmt, cmdS, cmdE))
        obPutc('[');
    else if (obCmpS("rb", fmt, cmdS, cmdE))
        obPutc(']');
    else if (obCmpS("bop", fmt, cmdS, cmdE))
        obCBOp(fmt, subS, object, x);
    else if (obCmpS("uop", fmt, cmdS, cmdE))
        obCUOp(fmt, subS, object, x);
    else if (obCmpS("str", fmt, cmdS, cmdE))
        obCStr(fmt, subS, object, x);
    else if (obCmpS("gz", fmt, cmdS, cmdE))
        obCGz(fmt, subS, object, x);
    else
        ice("Unrecognized command");

    return (p);
}

obCNum(fmt, subS, x, top) {
    extrn printn, char;
    extrn ice;
    extrn obPutc;

    if (char(fmt, subS) != ']')
        ice("Unexpected sub format");

    if (x < 0) {
        obPutc('-');
        x = -x;
    }
    printn(x, 10);
}

obCList(fmt, subS, x, top) {
    extrn vcSize;
    extrn obFmtI;
    extrn printf;
    auto i, sz, maxFP;

    maxFP = 0;
    i = 0;
    sz = vcSize(x);
    while (i < sz) {
        if (i != 0)
            printf(", ");
        obFmtI(fmt, subS, x + i, &maxFP);
        i =+ maxFP + 1;
    }
}

obCGz(fmt, subS, x, top) {
    extrn obFmtI;
    if (x > 0)
        obFmtI(fmt, subS, top, 0);
}

obCName(fmt, subS, name, top) {
    extrn char;
    extrn ice;
    extrn obPutc;

    if (char(fmt, subS) != ']')
        ice("Unexpected sub format");

    while (name) {
        obPutc(name & 0377);
        name =>> 8;
    }
}

/* Print a binary op */
obCBOp(fmt, subS, op, top) {
    extrn printf, char, ice;

    if (char(fmt, subS) != ']')
        ice("Unexpected sub format");

    /* TODO(kwaters): Is this better done with a table? */
    switch (op) {
    case  1: printf("OR");     return;
    case  2: printf("AND");    return;
    case  3: printf("EQ");     return;
    case  4: printf("NEQ");    return;
    case  5: printf("LT");     return;
    case  6: printf("LTE");    return;
    case  7: printf("GT");     return;
    case  8: printf("GTE");    return;
    case  9: printf("SHIFTL"); return;
    case 10: printf("SHIFTR"); return;
    case 11: printf("MINUS");  return;
    case 12: printf("PLUS");   return;
    case 13: printf("REM");    return;
    case 14: printf("MUL");    return;
    case 15: printf("DIV");    return;
    }
    ice("Unknown binary operation");
}

obCUOp(fmt, subS, op, top) {
    extrn printf, char, ice;

    if (char(fmt, subS) != ']')
        ice("Unexpected sub format");

    /* TODO(kwaters): Is this better done with a table? */
    switch(op) {
    case  1: printf("NEG"); return;
    case  2: printf("NOT"); return;
    }
    ice("Unknown unary operation");
}

/* Print a string. */
obCStr(fmt, subS, s, top) {
    extrn putchar, printf, char;
    extrn ice;
    auto i, c, arg, len;

    i = subS;
    arg = 0;
    while ((c = char(fmt, i++)) != ']') {
        if (c < '0' | c > '9')
            ice("Bad character in str formatter");
        arg = 10 * arg + c - '0';
    }
    len = top[arg];

    i = 0;
    while (i < len) {
        c = char(s, i++);
        switch (c) {
        case '*0': printf("**0"); goto loop;
        case '*e': printf("**e"); goto loop;
        case '*t': printf("**t"); goto loop;
        case '*n': printf("**n"); goto loop;
        case '**': printf("****"); goto loop;
        case '*"': printf("***""); goto loop;
        case '*'': printf("***'"); goto loop;
        }
        if (c >= ' ' & c <= '~')
            putchar(c);
        else
            printf("**?");
loop:;
    }
}

obCmpS(target, fmt, start, end) {
    extrn char;
    extrn printf;
    auto i;

    /* Because target is EOF terminated, it will mismatch without
     * overrunning. */
    i = start;
    while (i < end) {
        if (char(fmt, i) != char(target, i - start))
            return (0);
        i++;
    }
    return (1);
}
