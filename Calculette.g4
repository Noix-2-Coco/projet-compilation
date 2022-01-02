//projet de compilation Alice GYDÉ et Coline TREHOUT
grammar Calculette;
// règles de la grammaire

//start à remplacer par calcul
start returns [ String code ]
@init{ $code = new String(); } // On initialise $code, pour ensuite l’utiliser comme accumulateur
@after{ System.out.println($code); } // on affiche le code MVaP stocké dans code 
: (decl { $code += $decl.code; })*
NEWLINE*
(instruction { $code += $instruction.code; })*
{ $code += " HALT\n"; }
;

finInstruction
: (NEWLINE 
| ';')+
;

decl returns [ String code ]
: TYPE IDENTIFIANT finInstruction
{// à compléter
}
;

//System.out.println($bool.code + "WRITE\n" + "POP\n" + "HALT\n");


fin_expression
 : EOF | NEWLINE | ';'
;

instruction returns [ String code ]
: expression finInstruction
{
 // à compléter alcooline
}
| assignation finInstruction
{
// à compléter
}
| finInstruction
{
$code="";
}
| 'print' '('expression')' {$code = $expression.code + "WRITE\n" + "POP\n";}
;

assignation returns [ String code ]
: IDENTIFIANT '=' expression
{
// à compléter
}
;

//expression est une expression arithmétique ou un booléen
expression returns [String code]
: expr_arithmetique {$code = $expr_arithmetique.code;}
| bool {$code = $bool.code;}
;

//expressions arithmétiques
expr_arithmetique returns [String code]
 : '(' a=expr_arithmetique ')' {$code = $a.code;}
 | a=expr_arithmetique '/' b=expr_arithmetique {$code = $a.code + $b.code + "DIV" + '\n';}
 | a=expr_arithmetique '*' b=expr_arithmetique {$code = $a.code + $b.code + "MUL" + '\n';}
 | a=expr_arithmetique '+' b=expr_arithmetique {$code = $a.code + $b.code + "ADD" + '\n';}
 | a=expr_arithmetique '-' b=expr_arithmetique {$code = $a.code + $b.code + "SUB" + '\n';}
 | '-' ENTIER {$code = "PUSHI " + -$ENTIER.int + '\n';} 
 | ENTIER {$code = "PUSHI " + $ENTIER.int + '\n';}
// | FLOAT {$code = "  PUSHF " + $FLOAT.text + '\n';}
/*| ENTIER {
    $type = "int";
    $code = "  PUSHI " + $ENTIER.text + "\n";
 };*/
 ;

//booléens
 bool returns [String code]
 : '(' a=bool ')' {$code = $a.code;}
 //comparaisons d'expressions arithmétiques
 | 'not' a=bool {$code = "PUSHI 1" + '\n' + $a.code + "SUB" + '\n';} //1-a
 | aexp=expr_arithmetique '>' bexp=expr_arithmetique {$code = $aexp.code + $bexp.code + "SUP" + '\n';}
 | aexp=expr_arithmetique '>=' bexp=expr_arithmetique {$code = $aexp.code + $bexp.code + "SUPEQ" + '\n';}
 | aexp=expr_arithmetique '<' bexp=expr_arithmetique {$code = $aexp.code + $bexp.code + "INF" + '\n';}
 | aexp=expr_arithmetique '<=' bexp=expr_arithmetique {$code = $aexp.code + $bexp.code + "INFEQ" + '\n';}
 | aexp=expr_arithmetique '<>' bexp=expr_arithmetique {$code = $aexp.code + $bexp.code + "NEQ" + '\n';}
 | a=bool 'and' b=bool {$code = $a.code + $b.code + "MUL" + '\n';} //a*b
 | a=bool 'or' b=bool
    {
        //ou classsique (a + b >= 1)
        $code = $a.code + $b.code + "ADD" + '\n';
        $code += "PUSHI" + "1" + '\n';
        $code += "SUPEQ" + '\n';
    }
// ou exclusif
 | a=bool 'xor' b=bool
    {
        $code = $a.code + $b.code + "NEQ" + '\n';
    }
 | 'true' {$code = "PUSHI" + "1" + '\n';}
 | 'false' {$code = "PUSHI" + "0" + '\n';}
;


// lexer
TYPE : 'int' | 'float' | 'bool'; // pour pouvoir gérer des entiers, Booléens et floats

IDENTIFIANT : ('a' ..'z' | 'A' ..'Z') (
		'a' ..'z'
		| 'A' ..'Z'
		| '_'
		| '0' ..'9'
	)*; //minuscule + majuscule + _ + chiffres
ENTIER : ('0'..'9')+;
//fragment EXPOSANT: ('e' | 'E') ('+' | '-')? ENTIER;
//FLOAT : ENTIER (('.') ('0' ..'9')*)? EXPOSANT?;

// règles du lexer. Skip pour dire ne rien faire
NEWLINE : '\r'? '\n' -> skip;
WS : (' '|'\t')+ -> skip;
UNMATCH : . -> skip;