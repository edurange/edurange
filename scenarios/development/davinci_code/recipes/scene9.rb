script "scene9" do
  interpreter "bash"
  user "root"
  cwd "/tmp"
  code <<-EOH
message=$(cat << "EOF"
                                                                                                            
                                                                                                            
HHHHHHHHH     HHHHHHHHH     OOOOOOOOO     LLLLLLLLLLL         YYYYYYY       YYYYYYY                         
H:::::::H     H:::::::H   OO:::::::::OO   L:::::::::L         Y:::::Y       Y:::::Y                         
H:::::::H     H:::::::H OO:::::::::::::OO L:::::::::L         Y:::::Y       Y:::::Y                         
HH::::::H     H::::::HHO:::::::OOO:::::::OLL:::::::LL         Y::::::Y     Y::::::Y                         
  H:::::H     H:::::H  O::::::O   O::::::O  L:::::L           YYY:::::Y   Y:::::YYY                         
  H:::::H     H:::::H  O:::::O     O:::::O  L:::::L              Y:::::Y Y:::::Y                            
  H::::::HHHHH::::::H  O:::::O     O:::::O  L:::::L               Y:::::Y:::::Y                             
  H:::::::::::::::::H  O:::::O     O:::::O  L:::::L                Y:::::::::Y                              
  H:::::::::::::::::H  O:::::O     O:::::O  L:::::L                 Y:::::::Y                               
  H::::::HHHHH::::::H  O:::::O     O:::::O  L:::::L                  Y:::::Y                                
  H:::::H     H:::::H  O:::::O     O:::::O  L:::::L                  Y:::::Y                                
  H:::::H     H:::::H  O::::::O   O::::::O  L:::::L         LLLLLL   Y:::::Y                                
HH::::::H     H::::::HHO:::::::OOO:::::::OLL:::::::LLLLLLLLL:::::L   Y:::::Y                                
H:::::::H     H:::::::H OO:::::::::::::OO L::::::::::::::::::::::LYYYY:::::YYYY                             
H:::::::H     H:::::::H   OO:::::::::OO   L::::::::::::::::::::::LY:::::::::::Y                             
HHHHHHHHH     HHHHHHHHH     OOOOOOOOO     LLLLLLLLLLLLLLLLLLLLLLLLYYYYYYYYYYYYY                             
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
        GGGGGGGGGGGGGRRRRRRRRRRRRRRRRR                  AAA               IIIIIIIIIILLLLLLLLLLL             
     GGG::::::::::::GR::::::::::::::::R                A:::A              I::::::::IL:::::::::L             
   GG:::::::::::::::GR::::::RRRRRR:::::R              A:::::A             I::::::::IL:::::::::L             
  G:::::GGGGGGGG::::GRR:::::R     R:::::R            A:::::::A            II::::::IILL:::::::LL             
 G:::::G       GGGGGG  R::::R     R:::::R           A:::::::::A             I::::I    L:::::L               
G:::::G                R::::R     R:::::R          A:::::A:::::A            I::::I    L:::::L               
G:::::G                R::::RRRRRR:::::R          A:::::A A:::::A           I::::I    L:::::L               
G:::::G    GGGGGGGGGG  R:::::::::::::RR          A:::::A   A:::::A          I::::I    L:::::L               
G:::::G    G::::::::G  R::::RRRRRR:::::R        A:::::A     A:::::A         I::::I    L:::::L               
G:::::G    GGGGG::::G  R::::R     R:::::R      A:::::AAAAAAAAA:::::A        I::::I    L:::::L               
G:::::G        G::::G  R::::R     R:::::R     A:::::::::::::::::::::A       I::::I    L:::::L               
 G:::::G       G::::G  R::::R     R:::::R    A:::::AAAAAAAAAAAAA:::::A      I::::I    L:::::L         LLLLLL
  G:::::GGGGGGGG::::GRR:::::R     R:::::R   A:::::A             A:::::A   II::::::IILL:::::::LLLLLLLLL:::::L
   GG:::::::::::::::GR::::::R     R:::::R  A:::::A               A:::::A  I::::::::IL::::::::::::::::::::::L
     GGG::::::GGG:::GR::::::R     R:::::R A:::::A                 A:::::A I::::::::IL::::::::::::::::::::::L
        GGGGGG   GGGGRRRRRRRR     RRRRRRRAAAAAAA                   AAAAAAAIIIIIIIIIILLLLLLLLLLLLLLLLLLLLLLLL
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                            
*******************************************************************************************
Thank you for playing! For more exercises, go to cloud.edurange.org

*******************************************************************************************

EOF
)
while read player; do
  player=$(echo -n $player)
  cd /home/$player

  mkdir scene9
  chmod 700 scene9
  cd scene9
  echo "$message" > message
  chmod 404 message 

  echo $(edurange-get-var user $player flag9) > flag9
  chmod 404 flag9

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
    
    flag = fopen("/flags/$player/flag8", "r"); 
    fscanf(flag, "%s", pass);
    printf("Enter flag8: ");
    fgets(buffer, MAXLEN, stdin);
    buffer[strcspn(buffer, "\\n")] = 0;    
    if(strcmp(buffer, pass) != 0) {
        printf("Incorrect.\\n");
        return 1;
    }

    int number;
    number = chmod("/home/$player/scene9", S_IRWXU | S_IRWXG | S_IROTH | S_IXOTH);
    if(number == 0) {
        printf("Permissions of directory 'scene9' changed\\n");
        char *argv[] = { "/bin/cat", "/home/$player/scene9/message", NULL };
        execve(argv[0], &argv[0], NULL);
    }
    return 0;
}   
EOF
)
  echo "$unlock" > unlock9.c
  gcc -o unlock_scene9 unlock9.c
  chmod 4501 unlock_scene9
  rm unlock9.c

done </root/edurange/players
  EOH
end
