script "starting_line_script" do
  interpreter "bash"
  user "root"
  cwd "/tmp"
  code <<-EOH
message=$(cat << "EOF" 

██╗      █████╗     ██████╗ ██╗   ██╗██████╗  █████╗ ███╗   ███╗██╗██████╗ ███████╗
██║     ██╔══██╗    ██╔══██╗╚██╗ ██╔╝██╔══██╗██╔══██╗████╗ ████║██║██╔══██╗██╔════╝
██║     ███████║    ██████╔╝ ╚████╔╝ ██████╔╝███████║██╔████╔██║██║██║  ██║█████╗  
██║     ██╔══██║    ██╔═══╝   ╚██╔╝  ██╔══██╗██╔══██║██║╚██╔╝██║██║██║  ██║██╔══╝  
███████╗██║  ██║    ██║        ██║   ██║  ██║██║  ██║██║ ╚═╝ ██║██║██████╔╝███████╗
╚══════╝╚═╝  ╚═╝    ╚═╝        ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝     ╚═╝╚═╝╚═════╝ ╚══════╝
                                                                                   
██╗███╗   ██╗██╗   ██╗███████╗██████╗ ███████╗███████╗███████╗                     
██║████╗  ██║██║   ██║██╔════╝██╔══██╗██╔════╝██╔════╝██╔════╝                     
██║██╔██╗ ██║██║   ██║█████╗  ██████╔╝███████╗█████╗  █████╗                       
██║██║╚██╗██║╚██╗ ██╔╝██╔══╝  ██╔══██╗╚════██║██╔══╝  ██╔══╝                       
██║██║ ╚████║ ╚████╔╝ ███████╗██║  ██║███████║███████╗███████╗                     
╚═╝╚═╝  ╚═══╝  ╚═══╝  ╚══════╝╚═╝  ╚═╝╚══════╝╚══════╝╚══════╝                     
                                                                        
                                         
*******************************************************************************************
You arrive at La Pyramide Inversee. You can’t believe that for all these years, the Holy 
Grail existed and it has been kept hidden from the world. You agree that it should be kept 
secret as the world is not ready for the truth yet. With this key, you wish to get a 
glimpse of the Holy Grail, before keeping it a secret...FOREVER! 

Useful commands: openssl, man

*******************************************************************************************

EOF
)
while read player; do
  player=$(echo -n $player)
  cd /home/$player
  
  mkdir scene8
  chmod 700 scene8
  cd scene8
  echo "$message" > message
  chmod 404 message

  echo $(edurange-get-var user $player flag8) > flag8
  chmod 400 flag8

  openssl genrsa -out key.pem 1024
  openssl rsa -in key.pem -out public_key.pem -outform PEM -pubout
  chmod 404 key.pem
  openssl rsautl -encrypt -inkey public_key.pem -pubin -in flag8 -out flag8.encrypt
  openssl aes-256-cbc -e -pass pass:ARTHUR -in flag8.encrypt -out flag8.encrypt.twice
  chmod 404 flag.encrypt.twice
  rm flag8.encrypt
  rm public_key.pem
  rm flag8

  echo "openssl rsautl -encrypt -inkey public_key.pem -in flag8 -out flag.encrypt
openssl aes-256-cbc -e -pass pass:****** -in flag8.encrypt -out flag8.encrypt.twice" > encryption.txt
  chmod 404 encryption.txt

  mkdir /home/$player/scene4
  mv key.pem /home/$player/scene4

  echo "Perhaps there was a word you were asked to remember?" > hint
  chmod 404 hint

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
    
    flag = fopen("/flags/$player/flag7", "r"); 
    fscanf(flag, "%s", pass);
    printf("Enter flag7: ");
    fgets(buffer, MAXLEN, stdin);
    buffer[strcspn(buffer, "\\n")] = 0;    
    if(strcmp(buffer, pass) != 0) {
        printf("Incorrect.\\n");
        return 1;
    }

    int number;
    number = chmod("/home/$player/scene8", S_IRWXU | S_IRWXG | S_IROTH | S_IXOTH);
    if(number == 0) {
        printf("Permissions of directory 'scene8' changed\\n");
        char *argv[] = { "/bin/cat", "/home/$player/scene8/message", NULL };
        execve(argv[0], &argv[0], NULL);
    }
    return 0;
}   
EOF
)
  echo "$unlock" > unlock8.c
  gcc -o unlock_scene8 unlock8.c
  chmod 4501 unlock_scene8
  rm unlock8.c

done </root/edurange/players
  EOH
end
