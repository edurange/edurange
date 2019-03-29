script "scene7" do
  interpreter "bash"
  user "root"
  cwd "/tmp"
  code <<-EOH
message=$(cat << "EOF"

  O)) O)                                                       
O))    O))                                           O))))) O))
 O))         O)))   O))    O)) O))     O))                 O)) 
   O))     O))    O)   O))  O))  O)) O)   O))             O))  
      O)) O))    O))))) O)) O))  O))O))))) O))           O))   
O))    O)) O))   O)         O))  O))O)                   O))   
  O)) O)     O)))  O))))   O)))  O))  O))))              O))   
                                                               

                  _|_
               ____|____
      #%@@    /~~~~.~~~~    @@%#
     @%%#%%, /~~~~/ ~~~~ ,%%#%%@
    %%@@%%@%/~~~~/ : ~~~~%@%%@@%%
   `@%%%@#@/____/ (X) ____@%%%@#@`
    @@@%%@`|.`.| ___ |.`.|`@%%@/@@
     `#%/@  |:x:||  .||:x:|  @%#`
       ||   |:x:||   ||:x:|   ||
     -_|| _-|:x:||~ .||:x:|-_ ||_-
  !-!-!-!-!-|___||___||___|-!-!-!-!-!


*******************************************************************************************
You arrive at Rosslyn Chapel, deep in thought as to what a bizarre turn your weekend has 
taken. Suddenly, you are hit from the back by an assailant! The assailant tells you that 
it was he who murdered Jacques! Overwhelmed by anger, you attack the assailant! You barely 
came out on top of the fight, thanks to help from strangers. With the murderer finally in 
police custody, you proceed into the chapel. In the chapel, you are surprised to see people
waiting for you. They tell you that they are the guardians of the Priory, and that you are 
worthy of their secret if you can break the next code...

*******************************************************************************************

EOF
)
while read player; do
  player=$(echo -n $player)
  cd /home/$player
  
  mkdir scene7
  chmod 700 scene7
  cd scene7
  echo "$message" > message
  chmod 404 message

  c1=$(cat /dev/urandom | tr -dc 'A-Z' | fold -w 32 | head -n 1 | head --bytes 1)
  ((c1d=(((($(echo "ibase=16;$(echo $(printf "%x" "'$c1") | tr a-z A-z)" | bc ) - 65) + 15) % 26)+65)))
  c1n=$(printf "\\x$(echo "obase=16;$c1d" | bc )")
  c2=$(cat /dev/urandom | tr -dc 'a-z' | fold -w 32 | head -n 1 | head --bytes 1)
  ((c2d=(((($(echo "ibase=16;$(echo $(printf "%x" "'$c2") | tr a-z A-z)" | bc ) - 97) + 14) % 26)+97)))
  c2n=$(printf "\\x$(echo "obase=16;$c2d" | bc )")
  c3=$(cat /dev/urandom | tr -dc 'a-z' | fold -w 32 | head -n 1 | head --bytes 1)
  ((c3d=(((($(echo "ibase=16;$(echo $(printf "%x" "'$c3") | tr a-z A-z)" | bc ) - 97) + 18) % 26)+97)))
  c3n=$(printf "\\x$(echo "obase=16;$c3d" | bc )")
  c4=$(cat /dev/urandom | tr -dc 'a-z' | fold -w 32 | head -n 1 | head --bytes 1)
  ((c4d=(((($(echo "ibase=16;$(echo $(printf "%x" "'$c4") | tr a-z A-z)" | bc ) - 97) + 15) % 26)+97)))
  c4n=$(printf "\\x$(echo "obase=16;$c4d" | bc )")
  c5=$(cat /dev/urandom | tr -dc 'a-z' | fold -w 32 | head -n 1 | head --bytes 1)
  ((c5d=(((($(echo "ibase=16;$(echo $(printf "%x" "'$c5") | tr a-z A-z)" | bc ) - 97) + 14) % 26)+97)))
  c5n=$(printf "\\x$(echo "obase=16;$c5d" | bc )")
  c6=$(cat /dev/urandom | tr -dc 'a-z' | fold -w 32 | head -n 1 | head --bytes 1)
  ((c6d=(((($(echo "ibase=16;$(echo $(printf "%x" "'$c6") | tr a-z A-z)" | bc ) - 97) + 18) % 26)+97)))
  c6n=$(printf "\\x$(echo "obase=16;$c6d" | bc )")

  c1l=$(echo $c1 | tr A-Z a-z)

  echo "${c1l}${c2}${c3}${c4}${c5}${c6}" > .secret
  chmod 400 .secret

  echo "Lsdrcet hg ivw Efadfq dt Kxcf. Ls sgs s hsugsl hcuxsln godff ic hgcltql ivw dzvtgl ifwpgmgs ac hzt kggzv: ivw wcdn ujpwd. Ls vtse xh ldc hdkwgtma tgg cft dwgggc cj vcntffbsfi hg rcfifga wl, hc ai kaaz tt yweh zxrvtb xdfwksj... ${c1n}${c2n}${c3n}${c4n}${c5n}${c6n}" > note
  chmod 404 note

  echo "Have you heard of the Caesar cipher? Well, this is more advanced. 
This cipher is a method of encrypting alphabetic text by using a series of interwoven Caesar ciphers based on the letters of a keyword. It is a form of polyalphabetic substitution.
Using the Tabula Recta to encrypt a message, select the column with the associated letter from the keyword and the row for the letter you are trying to encrypt to determine the encrypted character.
The keyword repeats itself to the length of the message.
Example: 'The cat' with keyword 'key' turns into 'Dlc mer'

Use the Tabula Recta, key, and note to decrypt this message!" > instructions
  chmod 404 instructions
  echo "POS" > key
  chmod 404 key

echo "    A | B | C | D | E | F | G | H | I | J | K | L | M | N | O | P | Q | R | S | T | U | V | W | X | Y | Z 
---------------------------------------------------------------------------------------------------------
A : A | B | C | D | E | F | G | H | I | J | K | L | M | N | O | P | Q | R | S | T | U | V | W | X | Y | Z 
B : B | C | D | E | F | G | H | I | J | K | L | M | N | O | P | Q | R | S | T | U | V | W | X | Y | Z | A
C : C | D | E | F | G | H | I | J | K | L | M | N | O | P | Q | R | S | T | U | V | W | X | Y | Z | A | B
D : D | E | F | G | H | I | J | K | L | M | N | O | P | Q | R | S | T | U | V | W | X | Y | Z | A | B | C
E : E | F | G | H | I | J | K | L | M | N | O | P | Q | R | S | T | U | V | W | X | Y | Z | A | B | C | D
F : F | G | H | I | J | K | L | M | N | O | P | Q | R | S | T | U | V | W | X | Y | Z | A | B | C | D | E
G : G | H | I | J | K | L | M | N | O | P | Q | R | S | T | U | V | W | X | Y | Z | A | B | C | D | E | F
H : H | I | J | K | L | M | N | O | P | Q | R | S | T | U | V | W | X | Y | Z | A | B | C | D | E | F | G
I : I | J | K | L | M | N | O | P | Q | R | S | T | U | V | W | X | Y | Z | A | B | C | D | E | F | G | H
J : J | K | L | M | N | O | P | Q | R | S | T | U | V | W | X | Y | Z | A | B | C | D | E | F | G | H | I
K : K | L | M | N | O | P | Q | R | S | T | U | V | W | X | Y | Z | A | B | C | D | E | F | G | H | I | J
L : L | M | N | O | P | Q | R | S | T | U | V | W | X | Y | Z | A | B | C | D | E | F | G | H | I | J | K
M : M | N | O | P | Q | R | S | T | U | V | W | X | Y | Z | A | B | C | D | E | F | G | H | I | J | K | L
N : N | O | P | Q | R | S | T | U | V | W | X | Y | Z | A | B | C | D | E | F | G | H | I | J | K | L | M
O : O | P | Q | R | S | T | U | V | W | X | Y | Z | A | B | C | D | E | F | G | H | I | J | K | L | M | N
P : P | Q | R | S | T | U | V | W | X | Y | Z | A | B | C | D | E | F | G | H | I | J | K | L | M | N | O
Q : Q | R | S | T | U | V | W | X | Y | Z | A | B | C | D | E | F | G | H | I | J | K | L | M | N | O | P
R : R | S | T | U | V | W | X | Y | Z | A | B | C | D | E | F | G | H | I | J | K | L | M | N | O | P | Q
S : S | T | U | V | W | X | Y | Z | A | B | C | D | E | F | G | H | I | J | K | L | M | N | O | P | Q | R
T : T | U | V | W | X | Y | Z | A | B | C | D | E | F | G | H | I | J | K | L | M | N | O | P | Q | R | S
U : U | V | W | X | Y | Z | A | B | C | D | E | F | G | H | I | J | K | L | M | N | O | P | Q | R | S | T
V : V | W | X | Y | Z | A | B | C | D | E | F | G | H | I | J | K | L | M | N | O | P | Q | R | S | T | U
W : W | X | Y | Z | A | B | C | D | E | F | G | H | I | J | K | L | M | N | O | P | Q | R | S | T | U | V
X : X | Y | Z | A | B | C | D | E | F | G | H | I | J | K | L | M | N | O | P | Q | R | S | T | U | V | W
Y : Y | Z | A | B | C | D | E | F | G | H | I | J | K | L | M | N | O | P | Q | R | S | T | U | V | W | X
Z : Z | A | B | C | D | E | F | G | H | I | J | K | L | M | N | O | P | Q | R | S | T | U | V | W | X | Y
" > tabula_recta
  chmod 404 tabula_recta

  echo $(edurange-get-var user $player flag7) > flag7
  chmod 400 flag7

  chapel=$(cat << EOF 
#include <stdio.h>
#include <sys/stat.h>
#include <string.h>
#include <ctype.h>
#define MAXLEN 80

FILE *flag;

int main() {
    char buffer[MAXLEN];    
    char pass[MAXLEN];
    char* p = &buffer[0];

    flag = fopen("/home/$player/scene7/.secret", "r"); 
    fgets(pass, MAXLEN, flag);
    pass[strcspn(pass, "\\n")] = 0;
    printf("What are the 6 characters at the end of the note? ");
    fgets(buffer, MAXLEN, stdin);
    for ( ; *p; ++p) *p = tolower(*p); /* makes string lowercase */

    buffer[strcspn(buffer, "\\n")] = 0;    
    if(strcmp(buffer, pass) != 0) {
        printf("Incorrect.\\n");
        return 1;
    }

    int number;
    number = chmod("/home/$player/scene7/flag7", S_IRUSR | S_IROTH);
    if(number == 0) {
        printf("Permissions of 'flag7' changed\\n");
    }
    return 0;
}
EOF
)

  echo "$chapel" > chapel.c
  gcc -o chapel chapel.c
  chmod 4501 chapel
  rm chapel.c

  cd /home/$player

  unlock=$(cat << EOF
#include <stdio.h>
#include <sys/stat.h>
#include <string.h>
#define MAXLEN 80

FILE *flag; 

int main() {
    char buffer[MAXLEN];
    char pass[MAXLEN];
    
    flag = fopen("/flags/$player/flag6", "r"); 
    fscanf(flag, "%s", pass);
    printf("Enter flag6: ");
    fgets(buffer, MAXLEN, stdin);
    buffer[strcspn(buffer, "\\n")] = 0;    
    if(strcmp(buffer, pass) != 0) {
        printf("Incorrect.\\n");
        return 1;
    }

    int number;
    number = chmod("/home/$player/scene7", S_IRWXU | S_IRWXG | S_IROTH | S_IXOTH);
    if(number == 0) {
        printf("Permissions of directory 'scene7' changed\\n");
        char *argv[] = { "/bin/cat", "/home/$player/scene7/message", NULL };
        execve(argv[0], &argv[0], NULL);
    }
    return 0;
}   
EOF
)
  echo "$unlock" > unlock7.c
  gcc -o unlock_scene7 unlock7.c
  chmod 4501 unlock_scene7
  rm unlock7.c

done </root/edurange/players
  EOH
end
