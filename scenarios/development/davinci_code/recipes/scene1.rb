script "scene1" do
  interpreter "bash"
  user "root"
  cwd "/tmp"
  code <<-EOH
message=$(cat << "EOF"

  /$$$$$$                                                  /$$  
 /$$__  $$                                               /$$$$  
| $$  \\__/  /$$$$$$$  /$$$$$$  /$$$$$$$   /$$$$$$       |_  $$  
|  $$$$$$  /$$_____/ /$$__  $$| $$__  $$ /$$__  $$        | $$  
 \\____  $$| $$      | $$$$$$$$| $$  \\ $$| $$$$$$$$        | $$  
 /$$ \\  $$| $$      | $$_____/| $$  | $$| $$_____/        | $$  
|  $$$$$$/|  $$$$$$$|  $$$$$$$| $$  | $$|  $$$$$$$       /$$$$$$
 \\______/  \\_______/ \\_______/|__/  |__/ \\_______/      |______/
                                                                
                                                                
*******************************************************************************************
You are Robert Langdon, the world renowned Cryptology professor at King’s College London.
On a quiet Friday evening after a series of lectures, you retreat back to your office, 
finally able to do the daily crossword puzzle uninterrupted.

Oddly, some of the clues in the 'Down' column are labeled in binary.


Helpful commands: cd, ls, cat, less

*******************************************************************************************

EOF
)
while read player; do
  player=$(echo -n $player)
  cd /home/$player

  mkdir scene1
  chmod 700 scene1
  cd scene1
  echo "$message" > message
  chmod 404 message
 
  echo $(edurange-get-var user $player flag1) > flag1
  chmod 400 flag1

  num1=$(cat /dev/urandom | tr -dc '0-9' | fold -w 256 | head -n 1 | sed -e 's/^[6-90]*//' | head --bytes 2)
  num1b=$(echo "obase=2;$num1" | bc | awk '{printf "%06d", $0}')
  num2=$(cat /dev/urandom | tr -dc '0-9' | fold -w 256 | head -n 1 | sed -e 's/^[6-90]*//' | head --bytes 2)
  num2b=$(echo "obase=2;$num2" | bc | awk '{printf "%06d", $0}')
  num3=$(cat /dev/urandom | tr -dc '0-9' | fold -w 256 | head -n 1 | sed -e 's/^[6-90]*//' | head --bytes 2)
  num3b=$(echo "obase=2;$num3" | bc | awk '{printf "%06d", $0}')

  clues=$(cat << EOF
$num1b Study of integers and their properties
$num2b Computer science pioneer
$num3b Inverted bits
EOF
)
  echo "$clues" > clues
  chmod 404 clues

crossword=$(cat << EOF
#include <stdio.h>
#include <stdlib.h>
#include <sys/stat.h>
#define MAXLEN 80

int main() {
    char buffer[MAXLEN];
    int number;
    printf("In what column will you write 'AlanTuring'? ");
    fgets(buffer, MAXLEN, stdin);
    number = atoi(buffer);
    if(number != $num2) {
        printf("Incorrect. Answer in decimal format.\\n");
        return 1;
    }
    printf("In what column will you write 'NumberTheory'? ");
    fgets(buffer, MAXLEN, stdin);
    number = atoi(buffer);
    if(number != $num1) {
        printf("Incorrect. Answer in decimal format.\\n");
        return 1;
    }
    printf("In what column will you write 'OnesComplement'? ");
    fgets(buffer, MAXLEN, stdin);
    number = atoi(buffer);
    if(number != $num3) {
        printf("Incorrect. Answer in decimal format.\\n");
        return 1;
    }
    number = chmod("/home/$player/scene1/flag1", S_IRUSR | S_IROTH);
    if(number == 0) {
        printf("Permissions of 'flag1' changed\\n");
    }
    return 0;
}
EOF
)

  echo "$crossword" > crossword.c
  gcc -o crossword crossword.c
  chmod 4501 crossword
  rm crossword.c

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
    
    flag = fopen("/home/$player/flag0", "r"); 
    fscanf(flag, "%s", pass);
    printf("Enter flag0: ");
    fgets(buffer, MAXLEN, stdin);
    buffer[strcspn(buffer, "\\n")] = 0;    
    if(strcmp(buffer, pass) != 0) {
        printf("Incorrect.\\n");
        return 1;
    }

    int number;
    number = chmod("/home/$player/scene1", S_IRWXU | S_IRWXG | S_IROTH | S_IXOTH);
    if(number == 0) {
        printf("Permissions of directory 'scene1' changed\\n");
        char *argv[] = { "/bin/cat", "/home/$player/scene1/message", NULL };
        execve(argv[0], &argv[0], NULL);
    }
    return 0;
}   
EOF
)
  echo "$unlock" > unlock1.c
  gcc -o unlock_scene1 unlock1.c
  chmod 4501 unlock_scene1
  rm unlock1.c

done </root/edurange/players
  EOH
end
