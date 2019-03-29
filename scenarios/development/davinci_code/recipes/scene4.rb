script "scene4" do
  interpreter "bash"
  user "root"
  cwd "/tmp"
  code <<-EOH
message=$(cat << "EOF"
        
.d8888.  .o88b. d88888b d8b   db d88888b        j88D  
88'  YP d8P  Y8 88'     888o  88 88'           j8~88  
`8bo.   8P      88ooooo 88V8o 88 88ooooo      j8' 88  
  `Y8b. 8b      88~~~~~ 88 V8o88 88~~~~~      V88888D 
db   8D Y8b  d8 88.     88  V888 88.              88  
`8888Y'  `Y88P' Y88888P VP   V8P Y88888P          VP  
                                                            
                                                   
        _._._                       _._._
        _|   |_                     _|   |_
        | ... |_._._._._._._._._._._| ... |
        | ||| |   o ZURICH BANK o   | ||| |
        | """ |  """    """    """  | """ |
   ())  |[-|-]| [-|-]  [-|-]  [-|-] |[-|-]|  ())
  (())) |     |---------------------|     | (()))
 (())())| """ |  """    """    """  | """ |(())())
 (()))()|[-|-]|  :::   .-"-.   :::  |[-|-]|(()))()
 ()))(()|     | |~|~|  |_|_|  |~|~| |     |()))(()
    ||  |_____|_|_|_|__|_|_|__|_|_|_|_____|  ||
 ~ ~^^ @@@@@@@@@@@@@@/=======@@@@@@@@@@@@@@ ^^~ ~
      ^~^~                                ~^~^
                  
*******************************************************************************************
You head to the Depository Bank of Zurich with the escort of the police. At the bank, 
you alone are allowed into a room where a box is ready for you on the table. 
You open the security box with the key to find a cryptex and another key inside! 
Unfortunately you are not sure how to open it, but you know an old friend who might be 
able to help. He gives you a cryptic message of his address.

Helpful commands: echo

*******************************************************************************************

EOF
)
while read player; do
  player=$(echo -n $player)
  cd /home/$player

  mkdir scene4
  chmod 700 scene4
  cd scene4
  echo "$message" > message
  chmod 404 message

  echo $(edurange-get-var user $player flag4) > flag4
  chmod 400 flag4

  num1=$(cat /dev/urandom | tr -dc '0-9' | fold -w 256 | head -n 1 | head --bytes 1)
  ((num2=$(cat /dev/urandom | tr -dc '1-9' | fold -w 256 | head -n 1 | head --bytes 1)))
  ((num2h=9450 + $num2))
  num2h=$(echo "obase=16;$num2h" | bc )

  echo "5${num1}1$num2 Bedford Gardens" > .secret
  chmod 400 .secret

  address=$(cat << EOF
\\u1bd \\u208${num1} \\u${num2h} \\u20 \\u392 \\u435 \\u1e0b \\u3dd \\u2218 \\uae \\u2146 \\u20 \\u193 \\u24d0 \\u211b \\u217e \\u3f5 \\u2115 \\ua7
EOF
)
  echo "$address" > address
  chmod 404 address

  echo "The house number is 4 digits. Street name consists of 2 words, each 7 letters long.
Submit your response in plain letters, with only each first letter capitalized and a single space between.
For example '1234 Seventh Parkway'" > hint
  chmod 404 hint

  map=$(cat << EOF
#include <stdio.h>
#include <sys/stat.h>
#include <string.h>
#define MAXLEN 220

FILE *flag;

int main() {
    char buffer[MAXLEN];    
    char pass[MAXLEN];
    
    flag = fopen("/home/$player/scene4/.secret", "r"); 
    fgets(pass, MAXLEN, flag);
    pass[strcspn(pass, "\\n")] = 0;
    printf("What is your friend's address? ");
    fgets(buffer, MAXLEN, stdin);
    buffer[strcspn(buffer, "\\n")] = 0;    
    if(strcmp(buffer, pass) != 0) {
        printf("Incorrect.\\n");
        return 1;
    }

    int number;
    number = chmod("/home/$player/scene4/flag4", S_IRUSR | S_IROTH);
    if(number == 0) {
        printf("Permissions of 'flag4' changed\\n");
    }
    return 0;
}
EOF
)

  echo "$map" > map.c
  gcc -o map map.c
  chmod 4501 map
  rm map.c

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
    
    flag = fopen("/flags/$player/flag3", "r"); 
    fscanf(flag, "%s", pass);
    printf("Enter flag3: ");
    fgets(buffer, MAXLEN, stdin);
    buffer[strcspn(buffer, "\\n")] = 0;    
    if(strcmp(buffer, pass) != 0) {
        printf("Incorrect.\\n");
        return 1;
    }

    int number;
    number = chmod("/home/$player/scene4", S_IRWXU | S_IRWXG | S_IROTH | S_IXOTH);
    if(number == 0) {
        printf("Permissions of directory 'scene4' changed\\n");
        char *argv[] = { "/bin/cat", "/home/$player/scene4/message", NULL };
        execve(argv[0], &argv[0], NULL);
    }
    return 0;
}   
EOF
)
  echo "$unlock" > unlock4.c
  gcc -o unlock_scene4 unlock4.c
  chmod 4501 unlock_scene4
  rm unlock4.c

done </root/edurange/players
  EOH
end
