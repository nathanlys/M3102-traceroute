echo "digraph GraphDuLaInternet{" > final2.dot
echo "\"Nous [Maison]\" [shape=house]">>final2.dot
for i in $(ls *.route)
	do
	color=$(echo $RANDOM|md5sum|cut -c 1-6)
	echo -n "\"Nous [Maison]\" -> " >>final2.dot
	for (( lg=1; lg<=$(cat $i|wc -l); lg++))
	do
		if [ -z $(echo $(cat $i|head -n $lg|tail -n1|cut -d";" -f1|grep -v "inconnu")) ]
		then
		echo -n "\"$(cat $i|head -n $lg|tail -n1|cut -d";" -f1,3,4| sed 's/;/ entre /'|sed 's/;/ et /')\" -> " >>final2.dot
		else
		echo -n "\"$(cat $i|head -n $lg|tail -n1|cut -d";" -f1,2|sed 's/;/ /')\" -> ">>final2.dot
		fi
	done
echo "\"$(cat $i|tail -n1|cut -d";" -f4)\" [color=\"#$color\"]">>final2.dot
done


for i in $(ls *.route)
        do
        for (( lg=1; lg<=$(cat $i|wc -l); lg++))
        do
                if [ -z $(echo $(cat $i|head -n $lg|tail -n1|cut -d";" -f1|grep -v "inconnu")) ]
                then
		echo "On a trouvé un inconnu, on affiche donc $(cat $i|head -n $lg|tail -n1)"
                echo -n "\"$(cat $i|head -n $lg|tail -n1|cut -d";" -f1,3,4| sed 's/;/ entre /'|sed 's/;/ et /')\"" >>final2.dot
                else
                echo -n "\"$(cat $i|head -n $lg|tail -n1|cut -d";" -f1,2|sed 's/;/ /')\" [shape=box]">>final2.dot
                fi
        done
echo "\"$(cat $i|tail -n1|cut -d";" -f4)\" [shape=invhouse]">>final2.dot
done


echo "}" >>final2.dot
