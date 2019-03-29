script "scene2" do
  interpreter "bash"
  user "root"
  cwd "/tmp"
  code <<-EOH
message=$(cat << "EOF"

 S)ssss                                      2)AAA  
S)    ss                                    2)   AA 
 S)ss     c)CCCC e)EEEEE n)NNNN  e)EEEEE        2)  
     S)  c)      e)EEEE  n)   NN e)EEEE        2)   
S)    ss c)      e)      n)   NN e)           2)    
 S)ssss   c)CCCC  e)EEEE n)   NN  e)EEEE    2)AAAAA 
                                                    
L)                                                
L)                                                
L)        o)OOO  u)   UU v)    VV  r)RRR  e)EEEEE 
L)       o)   OO u)   UU  v)  VV  r)   RR e)EEEE  
L)       o)   OO u)   UU   v)VV   r)      e)      
L)llllll  o)OOO   u)UUU     v)    r)       e)EEEE 
                                                  
                                     
*******************************************************************************************
20 minutes into your guilty pleasure, you receive an unexpected knock on your door. 
It is the police and they need you for a murder case! 

"Hello Dr. Langdon. We are the French police. The Louvre curator Jacques Sauniere was 
murdered by an unknown assailant. Before he died, he left a cryptic note and we require 
your assistance in cracking the message. Please follow us to Paris immediately."

You arrive at the Louvre, sad and angry that your close friend Jacques was murdered. At 
the crime scene, the police hand you a bloodied note, allegedly found in the clutches of 
Jacques. You begin to decode the note.

*******************************************************************************************

EOF
)
while read player; do
  player=$(echo -n $player)
  cd /home/$player

  mkdir scene2
  chmod 700 scene2
  cd scene2
  echo "$message" > message
  chmod 404 message

  echo $(edurange-get-var user $player flag2) > flag2
  chmod 400 flag2

  num1h=$(cat /dev/urandom | tr -dc 'A-F' | fold -w 256 | head -n 1 | head --bytes 1)
  num1=$(echo "ibase=16;$num1h" | bc )

  num2=$(cat /dev/urandom | tr -dc '0-9' | fold -w 256 | head -n 1 | sed -e 's/^[0]*//' | head --bytes 2)
  num2h=$(echo "obase=16;$num2" | bc )
  num3=$(cat /dev/urandom | tr -dc '0-9' | fold -w 256 | head -n 1 | sed -e 's/^[0]*//' | head --bytes 2)
  num3h=$(echo "obase=16;$num3" | bc )
  num4=$(cat /dev/urandom | tr -dc '0-9' | fold -w 256 | head -n 1 | sed -e 's/^[0]*//' | head --bytes 2)
  num4h=$(echo "obase=16;$num4" | bc )

  num5=$(cat /dev/urandom | tr -dc '0-9' | fold -w 256 | head -n 1 | sed -e 's/^[6-90]*//' | head --bytes 2)
  num5b=$(echo "obase=2;$num5" | bc )
  num5h=$(echo "obase=16;$num5" | bc )
  num6=$(cat /dev/urandom | tr -dc '0-9' | fold -w 256 | head -n 1 | sed -e 's/^[6-90]*//' | head --bytes 2)
  num6b=$(echo "obase=2;$num6" | bc )
  num6h=$(echo "obase=16;$num6" | bc )
  num7=$(cat /dev/urandom | tr -dc '0-9' | fold -w 256 | head -n 1 | sed -e 's/^[6-90]*//' | head --bytes 2)
  num7b=$(echo "obase=2;$num7" | bc )
  num7h=$(echo "obase=16;$num7" | bc )

clue=$(cat << EOF
   $num1h-$num2h-$num3h-$num4h
    $num5h-$num6h-$num7h
Oh, Draconian devil.
   Oh, lame saint.
EOF
)
  echo "$clue" > note
  chmod 404 note

  louve=$(cat << EOF
#include <stdio.h>
#include <stdlib.h>
#include <sys/stat.h>
#define MAXLEN 80

int main() {
    char buffer[MAXLEN];
    int number;
    printf("First Row\\n");
    printf("  Enter the 1st number: ");
    fgets(buffer, MAXLEN, stdin);
    number = atoi(buffer);
    if(number != $num1) {
        printf("Incorrect. Answer in decimal format.\\n");
        return 1;
    }
    printf("  Enter the 2nd number: ");
    fgets(buffer, MAXLEN, stdin);
    number = atoi(buffer);
    if(number != $num2) {
        printf("Incorrect. Answer in decimal format.\\n");
        return 1;
    }
    printf("  Enter the 3rd number: ");
    fgets(buffer, MAXLEN, stdin);
    number = atoi(buffer);
    if(number != $num3) {
        printf("Incorrect. Answer in decimal format.\\n");
        return 1;
    }
    printf("  Enter the 4th number: ");
    fgets(buffer, MAXLEN, stdin);
    number = atoi(buffer);
    if(number != $num4) {
        printf("Incorrect. Answer in decimal format.\\n");
        return 1;
    }
    printf("Second Row - Convert to Binary\\n");
    printf("  Enter the 1st number: ");
    fgets(buffer, MAXLEN, stdin);
    buffer[strcspn(buffer, "\\n")] = 0;
    if(strcmp(buffer, "$num5b") != 0) {
        printf("Incorrect. Answer in binary format.\\n");
        return 1;
    }
    printf("  Enter the 2nd number: ");
    fgets(buffer, MAXLEN, stdin);
    buffer[strcspn(buffer, "\\n")] = 0;
    if(strcmp(buffer, "$num6b") != 0) {
        printf("Incorrect. Answer in binary format.\\n");
        return 1;
    }
    printf("  Enter the 3rd number: ");
    fgets(buffer, MAXLEN, stdin);
    buffer[strcspn(buffer, "\\n")] = 0;
    if(strcmp(buffer, "$num7b") != 0) {
        printf("Incorrect. Answer in binary format.\\n");
        return 1;
    }
    number = chmod("/home/$player/scene2/flag2", S_IRUSR | S_IROTH);
    if(number == 0) {
        printf("Permissions of 'flag2' changed\\n");
    }
    return 0;
}
EOF
)

  echo "$louve" > louve.c
  gcc -o louve louve.c
  chmod 4501 louve
  rm louve.c

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
    
    flag = fopen("/flags/$player/flag1", "r"); 
    fscanf(flag, "%s", pass);
    printf("Enter flag1: ");
    fgets(buffer, MAXLEN, stdin);
    buffer[strcspn(buffer, "\\n")] = 0;    
    if(strcmp(buffer, pass) != 0) {
        printf("Incorrect.\\n");
        return 1;
    }

    int number;
    number = chmod("/home/$player/scene2", S_IRWXU | S_IRWXG | S_IROTH | S_IXOTH);
    if(number == 0) {
        printf("Permissions of directory 'scene2' changed\\n");
        char *argv[] = { "/bin/cat", "/home/$player/scene2/message", NULL };
        execve(argv[0], &argv[0], NULL);
    }
    return 0;
}   
EOF
)
  echo "$unlock" > unlock2.c
  gcc -o unlock_scene2 unlock2.c
  chmod 4501 unlock_scene2
  rm unlock2.c

done </root/edurange/players
  EOH
end
