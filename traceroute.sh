#----------------------------TRACEROUTE.SH--------------------------------

	ns=$(nslookup $1 |grep "Address" |tail -n 1 |cut -d" " -f2)
	#Cherche l'adresse sur le DNS par rapport à l'argument.

	if [ $? -eq 1 ]
		then
		ns=$1
	fi
	#Faire en sorte que le code essaye même sans résolution DNS (pour les adresse IP ect..)

#--------------------------------------UDP--------------------------------

	echo "traceroute -n -sport 7-13-57 $1"
	#Débug
	rm -f log7.log
	rm -f log13.log
	rm -f log57.log
	#On supprime les anciens fichiers de logs étant donné que l'on va utiliser ">>".


	#INITIALISATION DE VARIABLES
	etoile=1
	#etoile = 1 si étoile présente dans la boucle précédente; etoile = 0 sinon.
	nFile=0
	#Numéro du fichier de log utilisé.

#----------------------------------UDP-PORT-7------------------------------

	#À chaque nouveau Saut on va recommencer le traceroute avec le TTL ciblé.
	for (( nbSaut=1; nbSaut<=30; nbSaut++ ))
		do
		#Envoie un paquet par un, qui affiche un AS sans faire de requête DNS avec comme premier TTL le nbSaut.
		#La ligne retournée est envoyée dans log7.txt
		traceroute -q 1 -n -w 1 -A -p 7 -f $nbSaut -m $nbSaut $1 > log7.txt
		log7=$(cat log7.txt |tail -n 1|grep -v "ms" |wc -l)
		#On récupère la ligne qui nous intéresse et on vérifie si elle ne contient pas de "ms". (ms = réponse)
		cat log7.txt|tail -n 1 >> log7.log

		#Si il y a eu une etoile au dessus,on sort de la boucle.
		if [ $log7 -eq 1 ]
			then
			nbSaut=50
			etoile=1
		fi

		#Si notre requête arrive au bout, on sort de la boucle.
		if [ "$(cat log7.txt | tail -n 1| sed 's/  /:/'|cut -d":" -f2 |cut -d" " -f1)" = "$ns" ]
			then
			nbSaut=50
			fi

		nFile=1
	done

	#Si il y a eu une étoile, on passe à la suite.
	if [ $etoile -eq 1 ]
		then

#-------------------------------UDP-PORT-13----------------------------------

		#On va réutiliser la même méthode que précédement en l'adaptant un petit peu.
		for (( nbSaut=1; nbSaut<=30; nbSaut++ ))
			do
			#On change uniquement le port de notre traceroute.
			traceroute -q 1 -n -w 1 -A -p 13 -f $nbSaut -m $nbSaut $1 > log13.txt
			log13=$(cat log13.txt |tail -n 1 |grep -v "ms" |wc -l)
			cat log13.txt >> log13.log
			etoile=0

			if [ $log13 -eq 1 ]
				then
				nbSaut=50
				etoile=1
			fi

			if [ "$(cat log13.txt | tail -n 1| sed 's/  /:/'|cut -d":" -f2 |cut -d" " -f1)" = "$ns" ]
				then
				nbSaut=50
			fi

			nFile=2
		done
	fi



	#Si il y a eu une étoile, on passe à la suite.
	if [ $etoile -eq 1 ]
		then

#-----------------------------UDP-PORT-57---------------------------------

		#On réutilise la même méthode en l'adaptant.
		for (( nbSaut=1; nbSaut<=30; nbSaut++ ))
			do
			#On modifie juste pour envoyer sur un port différent.
			traceroute -q 1 -n -w 1 -A -p 57 -f $nbSaut -m $nbSaut $1 > log57.txt
			log57=$(cat log57.txt |tail -n 1|grep -v "ms"|wc -l)
			cat log57.txt >> log57.log
			etoile=0

			if [ $log57 -eq 1 ]
				then
				nbSaut=50
				etoile=1
			fi

			if [ "$(cat log57.txt | tail -n 1| sed 's/  /:/'|cut -d":" -f2 |cut -d" " -f1)" = "$ns" ]
				then
				nbSaut=50
			fi


			nFile=3
		done
	fi


	#Affiche le fichier qui ne contient pas d'étoile

	if [ $etoile -eq 0 ]
		then
		case $nFile in
			1)
			cat log7.log>$1.route
			echo log7
			;;
			2)
			cat log13.log>$1.route
			echo log13
			;;
			3)
			cat log57.log>$1.route
			echo log57
			;;
		esac
	else

#---------------------------------------------ICMP----------------------------------------------

		#On effectue le traceroute sur de l'ICMP.
		echo "traceroute -I -n $1"
		traceroute -I -n -A $1 > log.txt
		icmp=$(cat log.txt | grep "* * *" |wc -l)

		if [ $icmp -eq 0 ]
			then
			cat log.txt > $1.route
		else

#--------------------------------------------TCP-------------------------------------------------

			#On reset les fichiers de log.
			echo "traceroute -T -n -p 7-53-443 $1"
			rm -f log7.log
			rm -f log53.log
			rm -f log443.log

#---------------------------------------TCP-PORT-7------------------------------------------------

			#même principe qu'au dessus, mais cette fois avec du TCP.
			echo "tcp"
			for (( nbSaut=1; nbSaut<=30; nbSaut++ ))
				do
				traceroute -T -q 2 -n -w 1 -A -p 7 -f $nbSaut -m $nbSaut $1 > log7.txt
				log7=$(cat log7.txt |tail -n 1 |grep -v "ms" |wc -l)
				cat log7.txt >> log7.log
				etoile=0

				if [ $log7 -eq 1 ]
					then
					nbSaut=50
					etoile=1
				fi

				if [ "$(cat log13.txt | tail -n 1| sed 's/  /:/'|cut -d":" -f2 |cut -d" " -f1)" = "$ns" ]
					then
					nbSaut=50
				fi

				nFile=4
			done


			if [ $etoile -eq 1 ]
				then

#--------------------------------------TCP-PORT-53-------------------------------------------------

				#Toujours la même méthode, on va juste tester un port différent.
				for (( nbSaut=1; nbSaut<=30; nbSaut++ ))
					do
					traceroute -T -q 2 -n -w 1 -A -p 53 -f $nbSaut -m $nbSaut $1 > log53.txt
					log53=$(cat log53.txt |tail -n 1 |grep -v "ms" |wc -l)
					cat log53.txt >> log53.log
					etoile=0

					if [ $log53 -eq 1 ]
						then
						nbSaut=50
						etoile=1
					fi

					if [ "$(cat log53.txt | tail -n 1| sed 's/  /:/'|cut -d":" -f2 |cut -d" " -f1)" = "$ns" ]
						then
						nbSaut=50
					fi

					nFile=5
				done
			fi

			if [ $etoile -eq 1 ]
				then

#------------------------------------TCP-PORT-443-----------------------------------

				#On teste encore un autre port.
				for (( nbSaut=1; nbSaut<=30; nbSaut++ ))
					do
					traceroute -T -q 2 -n -w 1 -A -p 443 -f $nbSaut -m $nbSaut $1 > log443.txt
					log443=$(cat log443.txt |tail -n 1 |grep -v "ms" |wc -l)
					cat log443.txt >> log443.log
					etoile=0

					if [ "$(cat log443.txt | tail -n 1| sed 's/  /:/'|cut -d":" -f2 |cut -d" " -f1)" = "$ns" ]
						then
						nbSaut=50
					fi

					nFile=6
				done
			fi

#----------------------------------------------------------------------------

			#On affiche le fichier qui ne contient pas d'étoiles (ou le 443).
			case $nFile in
				4)
				cat log7.log>$1.route
				echo log7
				;;
				5)
				cat log53.log>$1.route
				echo log53
				;;
				6)
				cat log443.log>$1.route
				echo log443
				;;
			esac

		fi
	fi

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

echo done

#------------------------------FIN--------------------------------------------------
