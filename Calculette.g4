//projet de compilation Alice GYDÉ et Coline TREHOUT
grammar Calculette;

//import d'une bibliothèque
@header 
{
    import java.util.HashMap;
}

@parser::members 
{
    //position à laquelle est stockée la variable
    int position = 0; 
    //hashmap qui contient le nom de la variable (string) et sa position dans la pile (entier)
    HashMap<String, Integer> variable = new HashMap<String, Integer>();

    //création des numéros d'étiquettes (première = 0)
    int current_label = 0;

    String newlabel() {
        return Integer.toString(current_label++);
    }
}

// règles de la grammaire
// /!\ start à remplacer par calcul
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
: TYPE id=IDENTIFIANT finInstruction
{
    variable.put($id.text, position);
    position ++;
    $code = "PUSHI 0\n"; //valeur par défaut -> 0
}
;

//System.out.println($bool.code + "WRITE\n" + "POP\n" + "HALT\n");


instruction returns [ String code ]
: expression finInstruction
{
    $code = $expression.code + "POP\n";
}
| assignation finInstruction
{
    $code = $assignation.code;
}
| finInstruction
{
$code="";
}
| PRINT '('expression')' {$code = $expression.code + "WRITE\n" + "POP\n";}
| bloc {$code = $bloc.code;}
| condition {$code = $condition.code;} 
| do_while {$code = $do_while.code;}
;

assignation returns [String code]
: id=IDENTIFIANT '=' expression
{
    $code = $expression.code;
    $code += "STOREG " + variable.get($id.text) + "\n"; 
}
;

bloc returns [String code]
 @init {
   $code = new String();
 }
 : '{' NEWLINE*
      (instruction  {$code += $instruction.code;})+
   '}'
;

//structure conditionnelle (si(cond) sinon (facultatif))
condition returns [String code]
    @init 
    {
        String instruction_if = new String();
        String instruction_else = new String();
        String label_if = newlabel(); //label_if permet de sauter les instructions if
        String label_else = newlabel(); //label_if permet de sauter les instructions else
    }
    : IF '(' bool ')' NEWLINE*
    (bloc {instruction_if += $bloc.code;}
    | instruction {instruction_if += $instruction.code;}
    )
    (ELSE NEWLINE*
    (bloc {instruction_else += $bloc.code;}
    | instruction {instruction_else += $instruction.code;}
    | condition {instruction_else += $condition.code;}
    ))? 
    {
        $code = $bool.code;
        $code += "JUMPF " + label_if + "\n";
        $code += instruction_if;
        if (instruction_else != "") 
        {$code += "JUMP " + label_else + "\n";}

        $code += "LABEL " + label_if + "\n";

        if (instruction_else != "") 
        {
            $code += instruction_else;
            $code += "LABEL " + label_else + "\n";
        }
    }
;

//répéter tant que (do while)
do_while returns [String code]
    @init 
    {
        String instruction_do_while = new String();
    }
    : DO NEWLINE*
    (bloc {instruction_do_while += $bloc.code;}
    | instruction {instruction_do_while += $instruction.code;}
    )
    WHILE '(' bool ')'
    {
        String label_do_while = newlabel(); //nouvelle étiquette pour le do while
        $code = "LABEL " + label_do_while + "\n"; //on étiquète le début du do while
        $code += instruction_do_while; 
        $code += "PUSHI 1" + '\n' + $bool.code + '\n'+ "SUB" + '\n'; //négation de la condition
        $code += "JUMPF " + label_do_while + "\n"; //si not(condition) est fausse on répète les instructions du do while 
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
 | a=expr_arithmetique MUL_DIV b=expr_arithmetique {$code = $a.code + $b.code + $MUL_DIV.getText() + '\n';}
 | a=expr_arithmetique '+' b=expr_arithmetique {$code = $a.code + $b.code + "ADD" + '\n';}
 | a=expr_arithmetique '-' b=expr_arithmetique {$code = $a.code + $b.code + "SUB" + '\n';}
 | '-' ENTIER {$code = "PUSHI " + -$ENTIER.int + '\n';} 
 | ENTIER {$code = "PUSHI " + $ENTIER.int + '\n';}
 |id=IDENTIFIANT {$code= "PUSHG " + variable.get($id.text) + "\n";}
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
 | aexp=expr_arithmetique '==' bexp=expr_arithmetique {$code = $aexp.code + $bexp.code + "EQUAL" + '\n';}
 | a=bool 'and' b=bool {$code = $a.code + $b.code + "MUL" + '\n';} //a*b
 | a=bool 'or' b=bool
    {
        //ou classsique (a + b >= 1)
        $code = $a.code + $b.code + "ADD" + '\n';
        $code += "PUSHI " + "1" + '\n';
        $code += "SUPEQ" + '\n';
    }
// ou exclusif
 | a=bool 'xor' b=bool
    {
        $code = $a.code + $b.code + "NEQ" + '\n';
    }
 | 'true' {$code = "PUSHI " + "1" + '\n';}
 | 'false' {$code = "PUSHI " + "0" + '\n';}
 |id=IDENTIFIANT {$code= "PUSHG " + variable.get($id.text) + "\n";}

;


// règles du lexer
TYPE : 'int' | 'float' | 'bool'; // pour pouvoir gérer des entiers, Booléens et floats

//entier ne peut pas commencer par 0 sauf 0
ENTIER : '0' | ('1'..'9')('0'..'9')*;
//fragment EXPOSANT: ('e' | 'E') ('+' | '-')? ENTIER;
//FLOAT : ENTIER (('.') ('0' ..'9')*)? EXPOSANT?;

//pour que la multiplication et la division aient le même niveau de priorité
MUL_DIV : '*' {setText("MUL");}
| '/' {setText("DIV");}
;

//condition
IF : 'if' | 'si';
ELSE : 'else' | 'sinon';

//boucle
DO : 'do' | 'repeter';
WHILE : 'while' | 'tantque';

//affichage
PRINT : 'print' | 'afficher';

//commence obligatoirement par une lettre puis lettres ou chiffres ou underscore
IDENTIFIANT : ('a' ..'z' | 'A' ..'Z') (
		'a' ..'z'
		| 'A' ..'Z'
		| '_'
		| '0' ..'9'
	)*; 

// Skip pour dire ne rien faire
NEWLINE : '\r'? '\n';
WS : (' '|'\t')+ -> skip;
UNMATCH : . -> skip;