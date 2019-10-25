truc=( "abc" "def" "35" "99 zzz" )
for i in $(seq 0 3)
do
echo ${truc[$i]}
done
