#!/usr/bin/env python

from ply import yacc

from .lexer import tokens

start = 'program'

# Dangling ELSE resolved as shift.
precedence = (
    ('right', 'ELSE'),
)

##############################################################################
# Top Level Declarations

def p_definition_basic(p):
    "definition : NAME ';'"
    pass

def p_definition_basic_init(p):
    "definition : NAME ival ';'"
    pass

def p_definition_vec(p):
    "definition : NAME '[' ']' ival_list ';'"
    pass

def p_definition_vec_sized(p):
    "definition : NAME '[' NUMBER ']' ival_list ';'"
    pass

def p_definition_function(p):
    "definition : NAME '(' ')' statement"
    pass

def p_definition_function2(p):
    "definition : NAME '(' arg_list_decl ')' statement"
    pass

##############################################################################
# Statements

def p_statement_switch(p):
    "statement : SWITCH '(' expr ')' statement"
    pass

def p_statement_goto(p):
    "statement : GOTO expr ';'"
    pass

def p_statement_label(p):
    "statement : NAME ':' statement"
    pass

def p_statement_case_label(p):
    """
    statement : CASE NUMBER ':' statement
              | CASE CHARACTER ':' statement
    """
    pass

def p_statement_variable(p):
    """
    statement : AUTO auto_decl_list ';'
              | EXTRN extrn_decl_list ';'
    """
    pass

def p_statement_if(p):
    "statement : IF '(' expr ')' statement opt_else"
    pass

def p_statement_return(p):
    "statement : RETURN '(' expr ')' ';'"
    pass

def p_statement_void_return(p):
    "statement : RETURN ';'"
    pass

def p_statement_compound(p):
    "statement : '{' statement_list '}'"
    pass

def p_statement_while(p):
    "statement : WHILE '(' expr ')' statement"
    pass

def p_statement_expr(p):
    "statement : expr ';'"
    pass

def p_statement_null(p):
    "statement : ';'"
    pass

##############################################################################
# Expressions

def p_rv0_number(p):
    """
    rv0 : NUMBER
    rv0 : CHARACTER
    """
    pass

def p_rv0_string(p):
    "rv0 : STRING"
    pass

def p_rv0_paren(p):
    "rv0 : '(' expr ')'"
    pass

def p_rv0_call_empty(p):
    "rv0 : v0 '(' ')'"
    pass

def p_rv0_call(p):
    "rv0 : v0 '(' arglist ')'"
    pass

def p_lv0(p):
    "lv0 : NAME"
    pass

def p_lv0_vec(p):
    "lv0 : v0 '[' expr ']'"
    pass

def p_post_inc(p):
    "rv1 : lv0 incdec"
    pass

def p_pre_inc(p):
    "rv2 : incdec lv"
    pass

def p_rv2_unary(p):
    "rv2 : unary_op rv2"
    pass

def p_rv2_deref(p):
    "rv2 : '&' lv"
    pass

def p_lv2(p):
    "lv2 : '*' rv2"
    pass

def p_rv3(p):
    "rv10 : rv9 '?' expr ':' expr"
    pass

def p_binop(p):
    """
    rv3 : rv3 '*' rv2
        | rv3 '/' rv2
        | rv3 '%' rv2
    rv4 : rv4 '+' rv3
        | rv4 '-' rv3
    rv5 : rv5 SHIFTL rv4
        | rv5 SHIFTR rv4
    rv6 : rv6 '<' rv5
        | rv6 LTE rv5
        | rv6 '>' rv5
        | rv6 GTE rv5
    rv7 : rv7 EQ rv6
        | rv7 NEQ rv6
    rv8 : rv8 '&' rv7
    rv9 : rv9 '|' rv8
    """
    pass

def p_binop_eq(p):
    "expr : lv ASSIGN expr"
    pass

def p_expr_load(p):
    """
    v0 : lv0
    rv1 : lv0
    rv2 : lv2
    """
    pass

def p_expr_pass_through(p):
    """
    unary_op : '-'
             | '!'
             | '~'

    incdec : INC
           | DEC

    v0 : rv0
    rv1 : rv0
    rv2 : rv1
    rv3 : rv2
    rv4 : rv3
    rv5 : rv4
    rv6 : rv5
    rv7 : rv6
    rv8 : rv7
    rv9 : rv8
    rv10 : rv9
    expr : rv10

    lv : lv0
       | lv2
    """
    pass

##############################################################################
# Misc

def p_list_base(p):
    """
    program :
    ival_list :
    statement_list :
    auto_decl_list : auto_decl
    arglist : expr
    """
    pass

def p_list_append(p):
    """
    program : program definition
    ival_list : ival_list ',' ival
    auto_decl_list : auto_decl_list ',' auto_decl
    statement_list : statement_list statement
    arglist : arglist ',' expr
    """
    pass

def p_name_list_base(p):
    """
    arg_list_decl : NAME
    extrn_decl_list : NAME
    """
    pass

def p_name_list_append(p):
    """
    arg_list_decl : arg_list_decl ',' NAME
    extrn_decl_list : extrn_decl_list ',' NAME
    """
    pass

def p_opt_else(p):
    "opt_else : ELSE statement"
    pass

def p_opt_no_else(p):
    "opt_else :"
    pass

def p_auto_decl(p):
    "auto_decl : NAME"
    pass

def p_auto_decl_vec(p):
    "auto_decl : NAME '[' NUMBER ']'"
    pass

def p_ival(p):
    """
    ival : NAME
         | NUMBER
         | CHARACTER
         | STRING
    """
    pass

##############################################################################

parser = yacc.yacc()
