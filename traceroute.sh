#!/bin/bash

#On vérifie que l'argument soit valable et qu'il y en ai uniquement un.
if [ $# -eq 0 ]
	then
	echo "traceroute.sh host [ -w TIME_TO_WAIT ]"
	echo "'traceroute.sh --help' for help"
	exit
fi
if [ $1 = '--help' ]
	then
        echo "traceroute.sh host [ -w TIME_TO_WAIT ]"
fi
if [ $# -eq 3 ]
then
	if [ $2 = "-w" ]
	then
	waiting=$3
	fi
	else
	waiting=2
fi

if [ -f $1.route ]
	then
	while true
		do
		read -p "Le fichier $1.route existe déjà, voulez vous le déplacer ? (oui/non)" var
		if [ "$var" = "oui" ]
			then
			read -p "Quel est le nom du fichier a changer (attention si il existe déjà il sera supprimé, il doit contenir .route " var2
			cp $1.route $var2
			break
		else
			if [ "$var" = "non" ]
				then
				break
			fi
		fi
	done
fi
#On vérifie si l'argument est une adresse IP, une URL et si elle est valide.
ns=$(host $1|grep "has address")
nbField=$(echo $ns | wc -w)
if [ $? -eq 1 ]
then
	echo "Erreur pas de résolution DNS"
	exit
else
	if [ $nbField -eq 5 ]
	then
		ns=$1
	else
		ns=$(echo $ns |cut -d" " -f4)
	fi
fi
#echo $ns

#On initialise la boucle géante.
etoile=1
protoport=( "-I" "-U -p 53" "-U -p 123" "-T -p 80" "-T -p 22" "-T -p 443" )
nbProto=6
rm -f traceroute*.log
> traceroute.$ns.log
for (( nbSaut=1;nbSaut<=30;nbSaut++))
	do
		for ((proto=0;proto<$nbProto;proto++))
			do
	                #echo "On commence le port : $port avec le protocole ${protoport[$proto]}"
				#Boucle Standard
				echo "traceroute ${protoport[$proto]} -q 1 -n -A -w $waiting -f $nbSaut -m $nbSaut $ns"
				res=$(traceroute ${protoport[$proto]} -q 1 -n -A -w $waiting -f $nbSaut -m $nbSaut $ns |sed 's/*/inconnu/g' |tail -n 1)
				isEtoile=$(echo $res | grep -v "ms" |wc -l)
				echo $res
				ipRouteur=$(echo $res | sed 's/ /:/g' |cut -d":" -f2)
				if [ "$ipRouteur" = "$ns" ]
					then
					nbSaut=50
					echo "Fini c'est gagné"
					echo $res| cut -d" " -f2,3 >> traceroute.$ns.log
					cp traceroute.$ns.log $1.route
					break 4
				fi
                                if [ $proto -eq $((($nbProto-1))) ]
                                        then
                                        echo $res| cut -d" " -f2,3 >> traceroute.$ns.log
                                else

				if [ $isEtoile -eq 0 ]
					then
					echo $res| cut -d" " -f2,3 >> traceroute.$ns.log
					break
				else
					etoile=1
				fi
			fi

		done
#		echo "On a fini le port : $port avec le protocole ${protoport[$proto]}"
done
cat traceroute.$ns.log |sed 's/\[inconnu\]/\[AS-connu\]/g'|sed 's/inconnu/inconnu \[AS-connu\]/g'|sed 's/AS-connu/AS-pas-connu/g' >$1.route
#cp $1.route $1.route.old
rm traceroute.$ns.log
#--------------------------Mise en forme du fichier.route--------------
        #On ne sélectionne que les résultats de traceroute, puis on les met en forme avec "IP;[AS]".
        cat $1.route |grep -v "traceroute" |sed 's/  /;/'|cut -d";" -f2 | sed 's/ /;/g'|cut -d";" -f 1,2|sed 's/*/inconnu/'|sed 's/*/[inconnu]/'|uniq >test.log
        #On Affiche sur la ligne "IP;[AS]" l'ip du routeur d'avant et celle du routeur d'après. (pour la première ligne)
        echo "$(cat test.log|head -n 1);nous;$(cat test.log|head -n 2|tail -n1|cut -d";" -f1)" >$1.route
        #On fait une boucle qui va passer toutes les lignes de notre fichier test.log.
        for (( lg=2; lg<=$(cat test.log|wc -l); lg++))
                do
                #Afficher IP + AS du routeur. (Sans retour à la ligne)
                echo -n $(cat test.log|head -n $lg|tail -n 1)>>$1.route
                #Afficher l'IP du routeur d'avant. (Sans retour à la ligne)
                echo -n ";$(cat test.log|head -n $(((lg-1)))|tail -n 1|cut -d";" -f1);">>$1.route

                #Affiche l'IP du routeur d'après si il existe, sinon affiche l'adresse cible.
                if [ $lg -ne $(cat test.log|wc -l) ]
                        then
                        echo $(cat test.log|head -n $(((lg+1)))|tail -n 1)>>$1.route
                else
                        echo $1>>$1.route
                fi
        done



echo "Fini"
