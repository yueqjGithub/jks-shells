BUILD_ID=dontKillMe

ftpPath=''
ftpUser=webuser
ftpPassword=vy6Ks348a7s88

arr=(`echo ${CD_AND_CHANNELS} | tr ',' ' '` )

for var in ${arr[@]}
do
  echo $var
done

arr=(`echo ${CD_AND_PLUGINS} | tr ',' ' '` )

for var in ${arr[@]}
do
  echo $var
done

arr=(`echo ${CD_IOS_CHANNELS} | tr ',' ' '` )

for var in ${arr[@]}
do
  echo $var
done

arr=(`echo ${CD_IOS_PLUGINS} | tr ',' ' '` )

for var in ${arr[@]}
do
  echo $var
done
