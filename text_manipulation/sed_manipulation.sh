######referenced this from https://linuxhint.com/bash_tr_command/
######
echo 'using sed to change a word'
sed -i.bak 's/text/sed/g' inital.txt
echo 'now going to change the file using tr'
tr [:space:] '\n' < inital.txt >> manipulated.txt
