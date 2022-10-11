BUILD_ID=dontKillMe

ftpPath=''
ftpUser=webuser
ftpPassword=vy6Ks348a7s88

arr=(`echo ${CD_AND_CHANNELS} | tr ',' ' '` )
cd ${WORKSPACE}/and_channel
for var in ${arr[@]}
do
  # echo $var
  version=${$var##*-}
  name=${var%*-}
  echo $version
  echo $name
done

arr=(`echo ${CD_AND_PLUGINS} | tr ',' ' '` )
cd ${WORKSPACE}/and_plugin
for var in ${arr[@]}
do
  version=${$var##*-}
  name=${var%*-}
  echo $version
  echo $name
done

arr=(`echo ${CD_IOS_CHANNELS} | tr ',' ' '` )
cd ${WORKSPACE}/ios_channel
for var in ${arr[@]}
do
  version=${$var##*-}
  name=${var%*-}
  echo $version
  echo $name
done

arr=(`echo ${CD_IOS_PLUGINS} | tr ',' ' '` )
cd ${WORKSPACE}/ios_plugin
for var in ${arr[@]}
do
  version=${$var##*-}
  name=${var%*-}
  echo $version
  echo $name
done
