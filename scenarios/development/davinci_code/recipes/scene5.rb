script "scene5" do
  interpreter "bash"
  user "root"
  cwd "/tmp"
  code <<-EOH
message=$(cat << "EOF" 
                                                            
 .M"""bgd                                                   
,MI    "Y                                                   
`MMb.      ,p6"bo   .gP"Ya `7MMpMMMb.  .gP"Ya       M****** 
  `YMMNq. 6M'  OO  ,M'   Yb  MM    MM ,M'   Yb     .M       
.     `MM 8M       8M""""""  MM    MM 8M""""""     |bMMAg.  
Mb     dM YM.    , YM.    ,  MM    MM YM.    ,          `Mb 
P"Ybmmd"   YMbmd'   `Mbmmd'.JMML  JMML.`Mbmmd'           jM 
                                                   (O)  ,M9 
                                                    6mmm9  

                               ____
                  _           |---||            _
                  ||__________|SSt||___________||
                 /_ _ _ _ _ _ |:._|'_ _ _ _ _ _ _`.
                /_ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _:`.
               /_ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _::`.
              /:.___________________________________:::`-._
          _.-'_ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _`::::::`-.._
      _.-' _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ `:::::::::`-._
    ,'_:._________________________________________________`:_.::::-';`
     `.'/ || |:::::`.'/::::::::`.'/::::::::`.'/::::::|.`.'/.|     :|
      ||  || |::::::||::::::::::||::::::::::||:::::::|..||..|     ||
      ||  || |  __  || ::  ___  || ::  __   || ::    |..||;||     ||
      ||  || | |::| || :: |:::| || :: |::|  || ::    |.|||:||_____||__
      ||  || | |::| || :: |:::| || :: |::|  || ::    |.|||:||_|_|_||,(
      ||_.|| | |::| || :: |:::| || :: |::|  || ::    |.'||..|    _||,|
   .-'::_.:'.:-.--.-::--.-:.--:-::--.--.--.-::--.--.-:.-::,'.--.'_|| |
    );||_|__||_|__|_||__|_||::|_||__|__|__|_||__|__|_|;-'|__|_(,' || '-
    ||||  || |. . . ||. . . . . ||. . . . . ||. . . .|::||;''||   ||:'
    ||||.;  _|._._._||._._._._._||._._._._._||._._._.|:'||,, ||,,
    '''''           ''-         ''-         ''-         '''  '''

*******************************************************************************************
You arrive at Sir Leigh Teabing’s mansion, a retired cryptographer who worked for MI6. 
While the police were taking a break in one of the mansion’s living rooms, you and Teabing
proceeded to find a way to solve the cryptex.

Helpful commands: grep, find

*******************************************************************************************

EOF
)
while read player; do
  player=$(echo -n $player)
  cd /home/$player

  mkdir scene5
  chmod 700 scene5
  cd scene5
  echo "$message" > message
  chmod 404 message

  echo $(edurange-get-var user $player flag5) > flag5
  chmod 400 flag5

  directory=$(shuf -i 11-99 -n 1)
  code=$(echo "The secret message is in dir$directory." | base64)
  echo "“$code”" > note
  chmod 404 note

  echo "The text in clue and hint uses binary-to-text encoding schemes that represent binary data in an ASCII string format by translating it into a radix-64 representation." > hint
  chown $player:$player hint
  chmod 400 hint

  string=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 4 | head -n 1)
  echo "$string" > .secret
  chmod 400 .secret

  cryptex=$(cat << EOF 
#include <stdio.h>
#include <sys/stat.h>
#include <string.h>
#define MAXLEN 80

FILE *flag;

int main() {
    char buffer[MAXLEN];    
    char pass[MAXLEN];
    
    flag = fopen("/home/$player/scene5/.secret", "r"); 
    fgets(pass, MAXLEN, flag);
    pass[strcspn(pass, "\\n")] = 0;
    printf("What are the 4 characters at the end of the message? ");
    fgets(buffer, MAXLEN, stdin);
    buffer[strcspn(buffer, "\\n")] = 0;    
    if(strcmp(buffer, pass) != 0) {
        printf("Incorrect.\\n");
        return 1;
    }

    int number;
    number = chmod("/home/$player/scene5/flag5", S_IRUSR | S_IROTH);
    if(number == 0) {
        printf("Permissions of 'flag5' changed\\n");
    }
    return 0;
}
EOF
)

  echo "$cryptex" > cryptex.c
  gcc -o cryptex cryptex.c
  chmod 4501 cryptex
  rm cryptex.c

  # do directories
  for i in {1..100}; do
    mkdir dir$i
    cd dir$i
    mySeedNumber=$$`date +%N` # seed will be the pid + nanoseconds
    myRandomString=$( echo $mySeedNumber | md5sum | md5sum )
    # create our actual random string
    myRandomResult="${myRandomString:2:100}"
    echo $myRandomResult > file.txt
    cd ..
    chown -R $player:$player dir$i
  done
  cd dir$directory
  passcode=$(echo "Hello, if you are reading this then I have been murdered. My assailant wants to find the secret that the secret society (Priory of Sion) has been hiding for centuries. I am Jacques, the grandmaster of the Priory, and I urge you to protect it! Please go to Westminster Abbey and seek refuge! $string" | base64 )
  echo "$passcode" > file.txt
  chmod 404 file.txt

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
    
    flag = fopen("/flags/$player/flag4", "r"); 
    fscanf(flag, "%s", pass);
    printf("Enter flag4: ");
    fgets(buffer, MAXLEN, stdin);
    buffer[strcspn(buffer, "\\n")] = 0;    
    if(strcmp(buffer, pass) != 0) {
        printf("Incorrect.\\n");
        return 1;
    }

    int number;
    number = chmod("/home/$player/scene5", S_IRWXU | S_IRWXG | S_IROTH | S_IXOTH);
    if(number == 0) {
        printf("Permissions of directory 'scene5' changed\\n");
        char *argv[] = { "/bin/cat", "/home/$player/scene5/message", NULL };
        execve(argv[0], &argv[0], NULL);
    }
    return 0;
}   
EOF
)
  echo "$unlock" > unlock5.c
  gcc -o unlock_scene5 unlock5.c
  chmod 4501 unlock_scene5
  rm unlock5.c

done </root/edurange/players
  EOH
end
