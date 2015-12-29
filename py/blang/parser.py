#!/usr/bin/env python

from ply import yacc

from .ast import *
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
    p[0] = Definition(p[1], [])

def p_definition_basic_init(p):
    "definition : NAME ival ';'"
    p[0] = Definition(p[1].name, [p[2]])

def p_definition_vec(p):
    "definition : NAME '[' ']' ival_list ';'"
    p[0] = Definition(p[1].name, p[4], 1)

def p_definition_vec_sized(p):
    "definition : NAME '[' NUMBER ']' ival_list ';'"
    p[0] = Definition(p[1].name, p[5], p[3])

def p_definition_function(p):
    "definition : NAME '(' ')' statement"
    p[0] = Function(p[1].name, [], p[4])

def p_definition_function2(p):
    "definition : NAME '(' arg_list_decl ')' statement"
    p[0] = Function(p[1].name, p[3], p[5])

##############################################################################
# Statements

def p_statement_switch(p):
    "statement : SWITCH '(' expr ')' statement"
    p[0] = SwitchStmt(p[3], p[5])

def p_statement_goto(p):
    "statement : GOTO expr ';'"
    p[0] = GotoStmt(p[2])

def p_statement_label(p):
    "statement : NAME ':' statement"
    p[0] = p[3]
    p[0].attach_label(p[1].name)

def p_statement_case_label(p):
    """
    statement : CASE NUMBER ':' statement
              | CASE CHARACTER ':' statement
    """
    p[0] = p[4]
    p[0].attach_case(p[1])

def p_statement_variable(p):
    """
    statement : AUTO auto_decl_list ';'
              | EXTRN extrn_decl_list ';'
    """
    p[0] = VariableStmt(p[2])

def p_statement_if(p):
    "statement : IF '(' expr ')' statement opt_else"
    p[0] = IfStmt(p[3], p[5], p[6])

def p_statement_return(p):
    "statement : RETURN '(' expr ')' ';'"
    p[0] = ReturnStmt(p[3])

def p_statement_void_return(p):
    "statement : RETURN ';'"
    p[0] = ReturnStmt()

def p_statement_compound(p):
    "statement : '{' statement_list '}'"
    p[0] = CompoundStmt(p[2])

def p_statement_while(p):
    "statement : WHILE '(' expr ')' statement"
    p[0] = WhileStmt(p[3], p[5])

def p_statement_expr(p):
    "statement : expr ';'"
    p[0] = ExprStmt(p[1])

def p_statement_null(p):
    "statement : ';'"
    p[0] = NullStmt()

##############################################################################
# Expressions

def p_rv0_number(p):
    """
    rv0 : NUMBER
    rv0 : CHARACTER
    """
    p[0] = Number(p[1])

def p_rv0_string(p):
    "rv0 : STRING"
    p[0] = String(p[1])

def p_rv0_paren(p):
    "rv0 : '(' expr ')'"
    p[0] = p[2]

def p_rv0_call_empty(p):
    "rv0 : v0 '(' ')'"
    p[0] = Call(p[1], [])

def p_rv0_call(p):
    "rv0 : v0 '(' arglist ')'"
    p[0] = Call(p[1], p[3])

def p_lv0(p):
    "lv0 : NAME"
    p[0] = Name(p[1].name, p[1][1])

def p_lv0_vec(p):
    "lv0 : v0 '[' expr ']'"
    p[0] = BinOp('+', p[1], p[3])

def p_post_inc(p):
    "rv1 : lv0 incdec"
    p[0] = Inc(p[2], p[1], True)

def p_pre_inc(p):
    "rv2 : incdec lv"
    p[0] = Inc(p[2], p[1], False)

def p_rv2_unary(p):
    "rv2 : unary_op rv2"
    p[0] = UnaryOp(p[1], p[2])

def p_rv2_deref(p):
    "rv2 : '&' lv"
    p[0] = p[2]

def p_lv2(p):
    "lv2 : '*' rv2"
    p[0] = p[2]

def p_rv3(p):
    "rv10 : rv9 '?' expr ':' expr"
    p[0] = TernaryOp(p[1], p[3], p[5])

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
    p[0] = BinOp(p[2], p[1], p[3])

def p_binop_eq(p):
    "expr : lv ASSIGN expr"
    p[0] = Assign('=', p[1], p[3])

def p_expr_load(p):
    """
    v0 : lv0
    rv1 : lv0
    rv2 : lv2
    """
    p[0] = Load(p[1])

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
    p[0] = p[1]

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
    p[0] = p[1:]

def p_list_append(p):
    """
    program : program definition
    ival_list : ival_list ',' ival
    auto_decl_list : auto_decl_list ',' auto_decl
    statement_list : statement_list statement
    arglist : arglist ',' expr
    """
    p[0] = p[1]
    p[0].append(p[len(p) - 1])

def p_name_list_base(p):
    """
    arg_list_decl : NAME
    extrn_decl_list : NAME
    """
    p[0] = [p[1].name]

def p_name_list_append(p):
    """
    arg_list_decl : arg_list_decl ',' NAME
    extrn_decl_list : extrn_decl_list ',' NAME
    """
    p[0] = p[1]
    p[0].append(p[3].name)

def p_opt_else(p):
    "opt_else : ELSE statement"
    p[0] = p[2]

def p_opt_no_else(p):
    "opt_else :"
    p[0] = None

def p_auto_decl(p):
    "auto_decl : NAME"
    p[0] = Variable(p[1].name, True)

def p_auto_decl_vec(p):
    "auto_decl : NAME '[' NUMBER ']'"
    p[0] = Variable(p[1].name, True, p[3])

def p_ival(p):
    """
    ival : NAME
         | NUMBER
         | CHARACTER
         | STRING
    """
    p[0] = p[1]

##############################################################################

parser = yacc.yacc()
