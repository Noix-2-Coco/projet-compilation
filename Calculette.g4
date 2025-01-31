//projet de compilation Alice GYDÉ et Coline TREHOUT, groupe de TP1
grammar Calculette;

@header 
{
    import java.util.HashMap;
}

@parser::members 
{
    //position à laquelle est stockée la variable
    int position_pile = 2; //début 2 (les 2 premières cases sont réservées pour le calcul des exposants) 
    //hashmap qui contient le nom de la variable (string) et sa position dans la pile (entier)
    HashMap<String, Integer> variable = new HashMap<String, Integer>();

    //création des numéros d'étiquettes (première = 0)
    int current_label = 0;

    //renvoie l'étiquette courante
    String newlabel() {
        return Integer.toString(current_label++);
    }
}

// règles de la grammaire
// /!\ start à remplacer par calcul
start returns [ String code ]
@init 
{ 
    $code = new String(); //On initialise $code, pour ensuite l’utiliser comme accumulateur
    //pour le calcul des exposants a^b
    $code += "PUSHI 0\n"; //a sera stocké à 0
    $code += "PUSHI 0\n"; //b sera stocké à 1
} 
@after  
{ 
    System.out.println($code); // on affiche le code MVaP stocké dans code 
} 
: (decl { $code += $decl.code; })*
NEWLINE*
(instruction { $code += $instruction.code; })* 
EOF
{ $code += " HALT\n"; }
;

finInstruction
: (NEWLINE 
| ';'
)+
;

//déclarations
decl returns [ String code ]
: TYPE id=IDENTIFIANT finInstruction
{
    variable.put($id.text, position_pile); //stockage dans la hashmap
    position_pile ++; 
    $code = "PUSHI 0\n"; //valeur par défaut -> 0
}
;

//instructions
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
| AFFICHER '('expression')' {$code = $expression.code + "WRITE\n" + "POP\n";}
| lire {$code = $lire.code;}
| bloc {$code = $bloc.code;}
| si {$code = $si.code;} 
| si_sinon {$code = $si_sinon.code;} 
| do_while {$code = $do_while.code;}
;

//lecture
lire returns [String code]
: LIRE '(' id=IDENTIFIANT ')'
{
    $code = "READ\n";
    $code += "STOREG " + variable.get($id.text) + "\n"; 
}
;

//affectation
assignation returns [String code]
: id=IDENTIFIANT '=' expression
{
    $code = $expression.code;
    $code += "STOREG " + variable.get($id.text) + "\n"; 
}
;

//bloc d'instructions
bloc returns [String code]
@init 
{
$code = new String();
}
: 
'{' NEWLINE*
    (instruction  {$code += $instruction.code;})+
'}'
;

//if else
si_sinon returns [String code]
@init 
{
    String instruction_if = new String();
    String instruction_else = new String();
    String label_else = newlabel(); //label_else permet d'aller aux instructions else
    String label_fin = newlabel(); //label_fin permet d'aller à la fin
}
: SI '(' bool ')' NEWLINE*
(
| instruction {instruction_if += $instruction.code;}
)
NEWLINE* SINON NEWLINE*
(
    instruction {instruction_else += $instruction.code;}
)
{
    $code = $bool.code;
    $code += "JUMPF " + label_else + "\n";
    $code += instruction_if;
    $code += "JUMP " + label_fin + "\n";
    $code += "LABEL " + label_else + "\n";
    $code += instruction_else;
    $code += "LABEL " + label_fin + "\n";
}
;

//if seulement
si returns [String code]
@init 
{
    String instruction_if = new String();
    String label_fin = newlabel(); //label_fin permet d'aller à la fin
}
: SI '(' bool ')' NEWLINE*
(
    instruction {instruction_if += $instruction.code;}
)
{
    $code = $bool.code;
    $code += "JUMPF " + label_fin + "\n";
    $code += instruction_if;
    $code += "LABEL " + label_fin + "\n";
}
;

//répéter tant que (do while)
do_while returns [String code]
@init 
{
    String instruction_do_while = new String();
}
: REPETER NEWLINE*
(
    instruction {instruction_do_while += $instruction.code;}
)
NEWLINE* TANTQUE '(' bool ')'
{
    String label_do_while = newlabel(); //nouvelle étiquette pour le do while
    $code = "LABEL " + label_do_while + "\n"; //on étiquète le début du do while
    $code += instruction_do_while; 
    $code += "PUSHI 1" + "\n" + $bool.code + "\n" + "SUB" + "\n"; //négation de la condition
    $code += "JUMPF " + label_do_while + "\n"; //si not(condition) est fausse on répète les instructions du do while 
}
;

//expression est une expression arithmétique ou booléenne
expression returns [String code]
: expr_arithmetique {$code = $expr_arithmetique.code;}
| bool {$code = $bool.code;}
;

//expressions arithmétiques
expr_arithmetique returns [String code]
 : '(' a=expr_arithmetique ')' {$code = $a.code;}
 | a=expr_arithmetique EXP b=expr_arithmetique 
 {
    String label_do_while = newlabel(); //nouvelle étiquette pour le do while
    String label_fin = newlabel(); //étiquette fin
    String label_exp_1 = newlabel(); //étiquette test exposant = 1
    String label_exp_0 = newlabel(); //étiquette test exposant = 0

    $code = $a.code + "STOREG 0" + "\n"; //stocke a à 0
    $code += $b.code + "STOREG 1" + "\n";  //stocke b à 1

    //si exp neg, a == 0
    $code += $b.code + "PUSHI 0" + "\n" + "INF\n";
    $code += "JUMPF " + label_exp_0 + "\n";
    $code += "PUSHI 0\n" + "STOREG 0" + "\n";
    $code += "JUMP " + label_fin + "\n";

    //si exp == 0, a = 1
    $code += "LABEL " + label_exp_0 + "\n";
    $code += $b.code + "PUSHI 0" + "\n" + "EQUAL\n"; 
    $code += "JUMPF " + label_exp_1 + "\n";
    $code += "PUSHI 1\n" + "STOREG 0" + "\n";
    $code += "JUMP " + label_fin + "\n";

    //si exp == 1, a = a
    $code += "LABEL " + label_exp_1 + "\n";
    $code += $b.code + "PUSHI 1" + "\n" + "EQUAL\n"; 
    $code += "JUMPF " + label_do_while + "\n";
    $code += "JUMP " + label_fin + "\n";

    //si exp>1, calcul de a
    $code += "LABEL " + label_do_while + "\n"; //on étiquète le début du do while
    $code += "PUSHG 0\n" + $a.code + "MUL" + "\n" + "STOREG 0" + "\n"; //a*a
    $code += "PUSHG 1\n" + "PUSHI 1" + "\n" + "SUB\n" + "STOREG 1" + "\n"; //b--

    //condition tant que (b>1) (non b <= 1)
    $code += "PUSHG 1" + "\n";
    $code += "PUSHI 1" + "\n"; 
    $code += "INFEQ" + "\n";

    $code += "JUMPF " + label_do_while + "\n";

    $code += "LABEL " + label_fin + "\n";
    $code += "PUSHG 0\n"; //résultat de a^b placé au sommet de la pile
 }
 | a=expr_arithmetique MUL_DIV b=expr_arithmetique {$code = $a.code + $b.code + $MUL_DIV.getText() + "\n";}
 | a=expr_arithmetique '+' b=expr_arithmetique {$code = $a.code + $b.code + "ADD" + "\n";}
 | a=expr_arithmetique '-' b=expr_arithmetique {$code = $a.code + $b.code + "SUB" + "\n";}
 | '-' ENTIER {$code = "PUSHI " + -$ENTIER.int + "\n";} 
 | ENTIER {$code = "PUSHI " + $ENTIER.int + "\n";}
 |id=IDENTIFIANT {$code= "PUSHG " + variable.get($id.text) + "\n";}
// | FLOAT {$code = "  PUSHF " + $FLOAT.text + '\n';}
 ;

//booléens
 bool returns [String code]
 : '(' a=bool ')' {$code = $a.code;}
 //comparaisons d'expressions arithmétiques
 | 'not' a=bool {$code = "PUSHI 1" + '\n' + $a.code + "SUB" + '\n';} //1-a
 | aexp=expr_arithmetique '>' bexp=expr_arithmetique {$code = $aexp.code + $bexp.code + "SUP" + "\n";}
 | aexp=expr_arithmetique '>=' bexp=expr_arithmetique {$code = $aexp.code + $bexp.code + "SUPEQ" + "\n";}
 | aexp=expr_arithmetique '<' bexp=expr_arithmetique {$code = $aexp.code + $bexp.code + "INF" + "\n";}
 | aexp=expr_arithmetique '<=' bexp=expr_arithmetique {$code = $aexp.code + $bexp.code + "INFEQ" + "\n";}
 | aexp=expr_arithmetique '<>' bexp=expr_arithmetique {$code = $aexp.code + $bexp.code + "NEQ" + "\n";}
 | aexp=expr_arithmetique '==' bexp=expr_arithmetique {$code = $aexp.code + $bexp.code + "EQUAL" + "\n";}
 | a=bool 'and' b=bool {$code = $a.code + $b.code + "MUL" + '\n';} //a*b
 | a=bool 'or' b=bool
    {
        $code = $a.code + $b.code + "ADD" + "\n";
        $code += "PUSHI " + "1" + "\n";
        $code += "SUPEQ" + "\n";
    } //(a + b >= 1)
 //ou exclusif
 | a=bool 'xor' b=bool
    {
        $code = $a.code + $b.code + "NEQ" + "\n"; //a != b
    }
 | 'true' {$code = "PUSHI " + "1" + "\n";}
 | 'false' {$code = "PUSHI " + "0" + "\n";}
 |id=IDENTIFIANT {$code= "PUSHG " + variable.get($id.text) + "\n";}

;


// règles du lexer

EXP : '^';

//pour pouvoir gérer des entiers, flottants et booléens
TYPE : 'int' | 'float' | 'bool'; 

//entier ne peut pas commencer par 0 sauf 0
ENTIER : '0' | ('1'..'9')('0'..'9')*;
FLOAT : ('0'..'9')+('.')('0'..'9')+;

//fragment EXPOSANT: ('e' | 'E') ('+' | '-')? ENTIER;

//pour que la multiplication et la division aient le même niveau de priorité
MUL_DIV : '*' {setText("MUL");}
| '/' {setText("DIV");}
;

//condition
SI : 'if' | 'si';
SINON : 'else' | 'sinon';

//boucle
REPETER : 'do' | 'repeter';
TANTQUE : 'while' | 'tantque';

//affichage
AFFICHER : 'print' | 'afficher';

//lecture
LIRE : 'read' | 'lire';

//commence obligatoirement par une lettre puis lettres ou chiffres ou underscore
IDENTIFIANT : ('a' ..'z' | 'A' ..'Z') 
    (
    'a' ..'z'
    | 'A' ..'Z'
    | '_'
    | '0' ..'9'
    )*; 

// Skip pour dire ne rien faire
NEWLINE : '\r'? '\n';
WS : (' '|'\t')+ -> skip;
UNMATCH : . -> skip;