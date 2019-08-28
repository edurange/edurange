script "commands" do
interpreter "bash"
user "root"
code <<-EOH
DIRS=()

for FILE in /home/*; do
      if [[ -d $FILE ]]; then
            DIRS+=( "$FILE" )
      fi
done

for studentDIR in "${DIRS[@]}"; do
     player=$(basename "$studentDIR")
     frust="Thank you! You are helping to create a better educational experience for future players."
     hooray="Congratulations!!! You are helping to create a better educational experience for future players."

     echo "echo $frust" > "$studentDIR"/iamfrustrated.sh
     echo "echo $hooray" > "$studentDIR"/success.sh
     
     cd "$studentDIR" || exit

     chown "$player":"$player" iamfrustrated.sh
     chown "$player":"$player" success.sh

    chmod 700 iamfrustrated.sh
    chmod 700 success.sh

done
EOH
end