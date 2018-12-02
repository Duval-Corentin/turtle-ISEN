%lex

%%

\s+                   /* skip whitespace */
[0-9]+("."[0-9]+)?\b  return 'NUMBER'
"#"[A-Fa-f0-9]{6}     return 'COLOR'
"degree"|"Degree"     return 'ANGLE_UNIT'
"radian"|"Radian"     return 'ANGLE_UNIT'
"*"                   return '*'
"/"                   return '/'
"-"                   return '-'
"+"                   return '+'
"^"                   return '^'
"!"                   return '!'
"%"                   return '%'
"("                   return '('
")"                   return ')'
">"                   return '>'
"<"                   return '<'
"PI"                  return 'PI'
"E"                   return 'E'
<<EOF>>               return 'EOF'
"="                   return 'EQUAL'
";"                   return 'SEMICOLON'
":"                   return 'COLON'

"var"|"Var"|"VAR"     return 'VAR'

"c:"                  return 'C_OPT'
"l:"                  return 'L_OPT'
"a:"                  return 'A_OPT'
"u:"                  return 'U_OPT'
"r:"                  return 'R_OPT'

"tracer"|"Tracer"                           return 'DRAW'
"tourner"|"Tourner"                         return 'TURN'
"déplacer"|"deplacer"|"Déplacer"|"Deplacer" return 'MOVE'
"rectangle"|"Rectangle"                     return 'RECTANGLE'
"cercle"|"Cercle"                           return 'CIRCLE'
"couleur_fond"|"Couleur_fond"               return 'BACKGROUND_COLOR'
"ellipse"|"Ellipse"                           return 'ELLIPSE'
"repeter"|"Repeter"                         return 'FOR'
"fin_repeter"                               return 'END_FOR'
"si"|"Si"                                   return 'IF'
"alors"|"Alors"                             return 'THEN'
"sinon"|"Sinon"                             return 'ELSE'

[A-Za-z_]+[A-Za-z0-9_]*                     return 'IDENTIFIER'
/lex

%{
    turtle_x = 0;
    turtle_y = 0;
    turtle_angle = 0;

    var instructions = []
    var variables = new Map();

    const base_options = {
        draw: {
            color: "#000000",
            width: 1,
            rounded: 0
        },
        rectangle: {
            color: "#000000",
            width: 1,
            rounded: 0,
            fill: 0
        },
        circle: {
            color: "#000000",
            width: 1,
            fill: 0
        }
    };
%}

/* operator associations and precedence */

%left '+' '-'
%left '*' '/'
%left '^'
%right '!'
%right '%'
%left UMINUS

%start pgm

%% /* language grammar */

pgm
    : elements EOF
        {
            return {
                instructions: instructions,
                variables: variables,
                turtle_pos: {
                    x: turtle_x,
                    y: turtle_y,
                    angle: turtle_angle
                }
            };
        }
    ;

elements
    : commande elements
    | commande
    ;

commande 
    /* Rules for variables management */
    : 'VAR' 'IDENTIFIER' 'EQUAL' expr 'SEMICOLON'
        {
            if(!variables[String($2)]){
                variables[String($2)] = Number($4);
            }else{
                throw new Error("variable " + String($2) + " allready defined before");
            }
        }
    | 'IDENTIFIER' 'EQUAL' expr 'SEMICOLON'
        {
            if(variables[String($1)]){
                variables[String($1)] = $3;
            }else{
                throw new Error("Variable " + String($1) + " must be declared before assignation");
            }
        }
    /* Rules for draw command*/
    | 'DRAW' expr opts_draw 'SEMICOLON'
        {
            var x = turtle_x + Math.round(Number($2) * Math.cos(turtle_angle));
            var y = turtle_y + Math.round(Number($2) * Math.sin(turtle_angle));
            instructions.push({
                command: "DRAW",
                from: {
                    x: turtle_x,
                    y: turtle_y
                },
                to: {
                    x: x,
                    y: y
                },
                options: $3
            });
            turtle_x = x;
            turtle_y = y;
        }
    | 'DRAW' expr 'SEMICOLON'
        {
            var x = turtle_x + Math.round(Number($2) * Math.cos(turtle_angle));
            var y = turtle_y + Math.round(Number($2) * Math.sin(turtle_angle));
            instructions.push({
                command: "DRAW",
                from: {
                    x: turtle_x,
                    y: turtle_y
                },
                to: {
                    x: x,
                    y: y
                },
                options: Object.assign({}, base_options.draw)
            });
            turtle_x = x;
            turtle_y = y;
        }
    | 'DRAW' expr 'COLON' expr opts_draw 'SEMICOLON'
        {
            var x = turtle_x + Number($2);
            var y = turtle_y + Number($4);
            instructions.push({
                command: "DRAW",
                from: {
                    x: turtle_x,
                    y: turtle_y
                },
                to: {
                    x : x,
                    y : y
                },
                options: $5
            });
            turtle_x = x;
            turtle_y = y;
        }
    | 'DRAW' expr 'COLON' expr 'SEMICOLON'
        {
            var x = turtle_x + Number($2);
            var y = turtle_y + Number($4);
            instructions.push({
                command: "DRAW",
                from: {
                    x: turtle_x,
                    y: turtle_y
                },
                to: {
                    x : x,
                    y : y
                },
                options: Object.assign({}, base_options.draw)
            });
            turtle_x = x;
            turtle_y = y;
        }
    /* Rules for turn command*/
    | 'TURN' expr 'U_OPT' 'ANGLE_UNIT' 'SEMICOLON'
        {
            var angle = Number($2);
            if(String($4) === "radian"){
                angle = angle * (Math.PI/180);
            }
            turtle_angle += angle;
        }
    | 'TURN' expr 'SEMICOLON'
        {
            turtle_angle += Number($2);
        }
    | 'MOVE' expr 'SEMICOLON'
        {
            turtle_x += Math.round(Number($2) * Math.cos(turtle_angle));
            turtle_y += Math.round(Number($2) * Math.sin(turtle_angle));
        }
    | 'MOVE' expr 'COLON' expr 'SEMICOLON'
        {
            turtle_x += Number($2);
            turtle_y += Number($4);
        }
    | 'RECTANGLE' expr expr opts_rect 'SEMICOLON'
        {
            instructions.push({
                command: "RECTANGLE",
                pos: {
                    x: turtle_x,
                    y: turtle_y
                },
                angle: turtle_angle, 
                width: Math.abs(Number($2)),
                height: Math.abs(Number($3)),
                options: $4
            });
        }
    | 'RECTANGLE' expr expr 'SEMICOLON'
        {
            instructions.push({
                command: "RECTANGLE",
                pos: {
                    x: turtle_x,
                    y: turtle_y
                },
                angle: turtle_angle, 
                width: Math.abs(Number($2)),
                height: Math.abs(Number($3)),
                options: base_options.rectangle
            });
        }
    | 'CIRCLE' expr opts_circle 'SEMICOLON'
        {
            instructions.push({
                command: "CIRCLE",
                pos: {
                    x: turtle_x,
                    y: turtle_y
                },
                angle: turtle_angle,
                radius: Number($2),
                options: $3
            });
        }
    | 'CIRCLE' expr 'SEMICOLON'
        {
            instructions.push({
                command: "CIRCLE",
                pos: {
                    x: turtle_x,
                    y: turtle_y
                },
                angle: turtle_angle,
                radius: Number($2),
                options: Object.assign({}, base_options.circle)
            });
        }
    | 'ELLIPSE' expr expr opts_circle 'SEMICOLON'
        {
            instructions.push({
                command: "ELLIPSE",
                pos: {
                    x: turtle_x,
                    y: turtle_y
                },
                angle: turtle_angle,
                radius_x: Number($2),
                raduis_y: Number($3),
                options: $4
            });
        }
    | 'ELLIPSE' expr expr 'SEMICOLON'
        {
            instructions.push({
                command: "ELLIPSE",
                pos: {
                    x: turtle_x,
                    y: turtle_y
                },
                angle: turtle_angle,
                radius_x: Number($2),
                radius_y: Number($3),
                options: Object.assign({}, base_options.circle)
            });
        }
    | 'BACKGROUND_COLOR' 'COLOR' 'SEMICOLON'
        {
            instructions.push({
                command: "BACKGROUND_COLOR",
                color: String($2)
            });
        }
    | 'FOR' '(' expr ')' ':'
        {
            this.begin('for_loop');
        }
    ;

expr
    : expr '+' expr
        {$$ = $1+$3;}
    | expr '-' expr
        {$$ = $1-$3;}
    | expr '*' expr
        {$$ = $1*$3;}
    | expr '/' expr
        {$$ = $1/$3;}
    | expr '^' expr
        {$$ = Math.pow($1, $3);}
    | expr '!'
        {{
          $$ = (function fact (n) { return n==0 ? 1 : fact(n-1) * n })($1);
        }}
    | expr '%'
        {$$ = $1/100;}
    | '-' expr %prec UMINUS
        {$$ = -$2;}
    | '(' expr ')'
        {$$ = $2;}
    | expr '<' 'EQUAL' expr
        {
            $$ = ($1 <= $3) ? 1 : 0;
        }
    | expr '>' 'EQUAL' expr
        {
            $$ = ($1 >= $4) ? 1 : 0;
        }
    | expr '<' expr
        {
            $$ = ($1 < $4) ? 1 : 0;
        }
    | expr '>' expr
        {
            $$ = ($1 > $3) ? 1 : 0;
        }
    | expr '!' 'EQUAL' expr
        {
            $$ = ($1 != $4) ? 1 : 0;
        }
    | expr 'EQUAL' 'EQUAL' expr
        {
            console.log(($1 == $4) ? 1 : 0)
            $$ = ($1 == $4) ? 1 : 0;
        }
    | NUMBER
        {$$ = Number(yytext);}
    | IDENTIFIER 
        {
            if(variables[String($1)] != undefined){
                $$ = Number(variables[String($1)])
            }else{
                throw new Error("variable " + String($1) + " must be declared before");
            }
        }
    | E
        {$$ = Math.E;}
    | PI
        {$$ = Math.PI;}
    ; 

opts_draw
    : opt_draw opt_draw opt_draw
        {
            var options = Object.assign({}, base_options.draw);
            [$1, $2, $3].forEach(opt => {
                if(opt.type){
                    options[opt.type] = opt.value;
                }
            });
            $$ = options;
        }
    | opt_draw opt_draw
        {
            var options = Object.assign({}, base_options.draw);
            [$1, $2].forEach(opt => {
                if(opt.type){
                    options[opt.type] = opt.value;
                }
            });
            $$ = options;
        }
    | opt_draw
        {
            var options = Object.assign({}, base_options.draw);
            [$1].forEach(opt => {
                if(opt.type){
                    options[opt.type] = opt.value;
                }
            });
            $$ = options;
        }
    ;

opt_draw
    : 'C_OPT' 'COLOR'
        {
            $$ = {type: "color", value: String($2)}
        }
    | 'L_OPT' expr
        {
            $$ = {type: "width", value: Math.abs(Number($2))}
        }
    | 'A_OPT' expr
        {
            $$ = {type: "rounded", value: Boolean($2) ? 1 : 0 }
        }
    ;

opts_rect 
    : opt_rect opt_rect opt_rect opt_rect
        {
            var options = Object.assign({}, base_options.rectangle);
            [$1, $2, $3, $4].forEach(opt => {
                if(opt.type){
                    options[opt.type] = opt.value;
                }
            });
            $$ = options;
        }
    | opt_rect opt_rect opt_rect
        {
            var options = Object.assign({}, base_options.rectangle);
            [$1, $2, $3].forEach(opt => {
                if(opt.type){
                    options[opt.type] = opt.value;
                }
            });
            $$ = options;
        }
    | opt_rect opt_rect
        {
            var options = Object.assign({}, base_options.rectangle);
            [$1, $2].forEach(opt => {
                if(opt.type){
                    options[opt.type] = opt.value;
                }
            });
            $$ = options;
        }
    | opt_rect
        {
            var options = Object.assign({}, base_options.rectangle);
            [$1].forEach(opt => {
                if(opt.type){
                    options[opt.type] = opt.value;
                }
            });
            $$ = options;
        }
    ;
opt_rect
    : 'C_OPT' 'COLOR'
        {
            $$ = {type: "color", value: String($2)}
        }
    | 'R_OPT' expr
        {
            $$ = {type: "fill", value: Boolean($2) ? 1 : 0}
        }
    | 'A_OPT' expr
        {
            $$ = {type: "rounded", value: Boolean($2) ? 1 : 0}
        }
    | 'L_OPT' expr
        {
            $$ = {type: "width", value: Math.abs(Number($2))}
        }
    ;

opts_circle
    : opt_circle opt_circle opt_circle
        {
            var options = Object.assign({}, base_options.circle);
            [$1, $2, $3].forEach(opt => {
                if(opt.type){
                    options[opt.type] = opt.value;
                }
            });
            $$ = options;
        }
    | opt_circle opt_circle
        {
            var options = Object.assign({}, base_options.circle);
            [$1, $2].forEach(opt => {
                if(opt.type){
                    options[opt.type] = opt.value;
                }
            });
            $$ = options;
        }
    | opt_circle
        {
            var options = Object.assign({}, base_options.circle);
            [$1].forEach(opt => {
                if(opt.type){
                    options[opt.type] = opt.value;
                }
            });
            $$ = options;
        }
    ;

opt_circle
    : 'C_OPT' 'COLOR'
        {
            $$ = {type: "color", value: String($2)}
        }
    | 'R_OPT' expr
        {
            $$ = {type: "fill", value: Boolean($2) ? 1 : 0}
        }
    | 'L_OPT' expr
        {
            $$ = {type: "width", value: Math.abs(Number($2))}
        }
    ;

%%