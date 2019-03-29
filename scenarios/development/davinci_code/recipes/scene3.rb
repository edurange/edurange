script "scene3" do
  interpreter "bash"
  user "root"
  cwd "/tmp"
  code <<-EOH
message=$(cat << "EOF"
 _______  _______  _______  __    _  _______    _______ 
|       ||       ||       ||  |  | ||       |  |       |
|  _____||       ||    ___||   |_| ||    ___|  |___    |
| |_____ |       ||   |___ |       ||   |___    ___|   |
|_____  ||      _||    ___||  _    ||    ___|  |___    |
 _____| ||     |_ |   |___ | | |   ||   |___    ___|   |
|_______||_______||_______||_|  |__||_______|  |_______|


*******************************************************************************************
The clue brings you to the Mona Lisa in the Louvre. 
You think to yourself: why Mona Lisa, the most famous painting in the world? 
You begin looking around for clues, to successfully find a key and note hidden above the
painting’s bulletproof case!

*******************************************************************************************

EOF
)

while read player; do
  player=$(echo -n $player)
  cd /home/$player
  
  mkdir scene3
  chmod 700 scene3
  cd scene3
  echo "$message" > message
  chmod 404 message

  echo $(edurange-get-var user $player flag3) > flag3
  chmod 400 flag3

  ((num1a=$(cat /dev/urandom | tr -dc '0-9' | fold -w 256 | head -n 1 | head --bytes 1)))
  ((num1d=$num1a + 48))
  num1h=$(echo "obase=16;$num1d" | bc )
  ((num2a=$(cat /dev/urandom | tr -dc '0-9' | fold -w 256 | head -n 1 | head --bytes 1)))
  ((num2d=$num2a + 48))
  num2h=$(echo "obase=16;$num2d" | bc )
  ((num3a=$(cat /dev/urandom | tr -dc '0-9' | fold -w 256 | head -n 1 | head --bytes 1)))
  ((num3d=$num3a + 48))
  num3h=$(echo "obase=16;$num3d" | bc )
  boxnum="$num1a$num2a$num3a"

  echo “47 6f 20 74 6f 20 74 68 65 20 42 61 6e 6b 20 6f 66 20 5a fc 72 69 63 68 2e 20 53 61 66 65 74 79 20 44 65 70 6f 73 69 74 20 42 6f 78 20 23 $num1h $num2h $num3h” > note
  chmod 404 note

  echo "Hint: The American Standard Code for Information Interchange might help..." > hint
  chown $player:$player hint
  chmod 400 hint

  key=$(cat << "EOF"
                   __
                  /o \\_____
                  \\__/-=^=^`
                __
               / o\\ 
               \\_ /
                <|
                <|
                <|
                `
EOF
)
  echo "$key" > key
  chown $player:$player key
  chmod 400 key

  box=$(cat << EOF
#include <stdio.h>
#include <stdlib.h>
#include <sys/stat.h>
#define MAXLEN 80

int main() {
    char buffer[MAXLEN];
    int number;
    printf("What is the safety deposit box number? ");
    fgets(buffer, MAXLEN, stdin);
    number = atoi(buffer);
    if(number != $boxnum) {
        printf("Incorrect. Answer in decimal format.\\n");
        return 1;
    }
    number = chmod("/home/$player/scene3/flag3", S_IRUSR | S_IROTH);
    if(number == 0) {
        printf("Permissions of 'flag3' changed\\n");
    }
    return 0;
}
EOF
)

  echo "$box" > safetybox.c
  gcc -o safetybox safetybox.c
  chmod 4501 safetybox
  rm safetybox.c

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
    
    flag = fopen("/flags/$player/flag2", "r"); 
    fscanf(flag, "%s", pass);
    printf("Enter flag2: ");
    fgets(buffer, MAXLEN, stdin);
    buffer[strcspn(buffer, "\\n")] = 0;    
    if(strcmp(buffer, pass) != 0) {
        printf("Incorrect.\\n");
        return 1;
    }

    int number;
    number = chmod("/home/$player/scene3", S_IRWXU | S_IRWXG | S_IROTH | S_IXOTH);
    if(number == 0) {
        printf("Permissions of directory 'scene3' changed\\n");
        char *argv[] = { "/bin/cat", "/home/$player/scene3/message", NULL };
        execve(argv[0], &argv[0], NULL);
    }
    return 0;
}   
EOF
)
  echo "$unlock" > unlock3.c
  gcc -o unlock_scene3 unlock3.c
  chmod 4501 unlock_scene3
  rm unlock3.c

done </root/edurange/players
  EOH
end




