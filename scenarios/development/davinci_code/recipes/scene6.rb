script "scene6" do
  interpreter "bash"
  user "root"
  cwd "/tmp"
  code <<-EOH
message=$(cat << "EOF" 

  .dBBBBP   dBBBP  dBBBP  dBBBBb  dBBBP     dBBBBP
  BP                         dBP           dP     
  `BBBBb  dBP    dBBP   dBP dBP dBBP      dP dBP  
     dBP dBP    dBP    dBP dBP dBP       dP  dP   
dBBBBP' dBBBBP dBBBBP dBP dBP dBBBBP     VBBBP    
                                                  
      |
     _|_
    //_/
  __|  ||____
 ////////////
/////////////
|^^^^^^^^^^||+|
|  # # #   ||||
 ....    ....".
|||||||||||||||||
                       

*******************************************************************************************
You are shocked that Jacques, your friend for many years, is in a secret society protecting
something that he is willing to sacrifice his life for! Bolstering your courage for what 
might be ahead, you follow Jacques’ directions and arrive at Westminster Abbey in London. 
The police unfortunately are not allowed to follow you, so you feel a sense of 
vulnerability. At Westminster Abbey, you look around the sanctuary for clues as Jacques 
asked that you seek refuge...

Helpful commands: sed (sed is an extremely powerful tool and among the most worthwhile 
command line tools to learn, but it can be quite unwieldy. You might get more frustrated 
trying to learn it for this challenge rather than solving by hand!)

*******************************************************************************************

EOF
)
while read player; do
  player=$(echo -n $player)
  cd /home/$player

  mkdir scene6
  chmod 700 scene6
  cd scene6
  echo "$message" > message
  chmod 404 message

  c1=$(cat /dev/urandom | tr -dc 'A-Z' | fold -w 32 | head -n 1 | head --bytes 1)
  c2=$(cat /dev/urandom | tr -dc 'A-Z' | fold -w 32 | head -n 1 | head --bytes 1)
  c3=$(cat /dev/urandom | tr -dc 'A-Z' | fold -w 32 | head -n 1 | head --bytes 1)
  c4=$(cat /dev/urandom | tr -dc 'A-Z' | fold -w 32 | head -n 1 | head --bytes 1)
  c5=$(cat /dev/urandom | tr -dc 'A-Z' | fold -w 32 | head -n 1 | head --bytes 1)
  c6=$(cat /dev/urandom | tr -dc 'A-Z' | fold -w 32 | head -n 1 | head --bytes 1)

  echo "TACPUHRTEREPTL_KLHR${c1}NEEE${c2}IDRM${c3}GGOE${c4}HESM${c5}TTSB${c6}SOLE_TPYR_ERNA_MOCR_PTHT_LEAH_" > note
  chmod 404 note

  echo "In cryptography, this is a transposition cipher which uses a cylinder with a strip of parchment wound around it on which is written a message. Perhaps each letter's position is misplaced in a specific sequence? See hint_two if still stuck..." > hint
  chmod 404 hint

  echo "It is suggested that to decrypt the note, one should write it down and choose letters of every sequence. eg. sequence of 3 (1-4-7-10-...-2-5-8-...) Graph paper is handy." > hint_two
  chmod 404 hint_two

  echo $(edurange-get-var user $player flag6) > flag6
  chmod 400 flag6

  echo "${c1}${c2}${c3}${c4}${c5}${c6}" > .secret
  chmod 400 .secret

  abbey=$(cat << EOF 
#include <stdio.h>
#include <sys/stat.h>
#include <string.h>
#define MAXLEN 80

FILE *flag;

int main() {
    char buffer[MAXLEN];    
    char pass[MAXLEN];
    
    flag = fopen("/home/$player/scene6/.secret", "r"); 
    fgets(pass, MAXLEN, flag);
    pass[strcspn(pass, "\\n")] = 0;
    printf("What are the 6 characters at the end of the note? ");
    fgets(buffer, MAXLEN, stdin);
    buffer[strcspn(buffer, "\\n")] = 0;    
    if(strcmp(buffer, pass) != 0) {
        printf("Incorrect.\\n");
        return 1;
    }

    int number;
    number = chmod("/home/$player/scene6/flag6", S_IRUSR | S_IROTH);
    if(number == 0) {
        printf("Permissions of 'flag6' changed\\n");
    }
    return 0;
}
EOF
)

  echo "$abbey" > abbey.c
  gcc -o abbey abbey.c
  chmod 4501 abbey
  rm abbey.c

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
    
    flag = fopen("/flags/$player/flag5", "r"); 
    fscanf(flag, "%s", pass);
    printf("Enter flag5: ");
    fgets(buffer, MAXLEN, stdin);
    buffer[strcspn(buffer, "\\n")] = 0;    
    if(strcmp(buffer, pass) != 0) {
        printf("Incorrect.\\n");
        return 1;
    }

    int number;
    number = chmod("/home/$player/scene6", S_IRWXU | S_IRWXG | S_IROTH | S_IXOTH);
    if(number == 0) {
        printf("Permissions of directory 'scene6' changed\\n");
        char *argv[] = { "/bin/cat", "/home/$player/scene6/message", NULL };
        execve(argv[0], &argv[0], NULL);
    }
    return 0;
}   
EOF
)
  echo "$unlock" > unlock6.c
  gcc -o unlock_scene6 unlock6.c
  chmod 4501 unlock_scene6
  rm unlock6.c

done </root/edurange/players
  EOH
end
