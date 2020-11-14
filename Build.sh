#! /bin/bash

if [ -z "${1}" ]
then 
   echo "$0 app name \"(node-red --help | head -1 | cut -d 'v' -f2 )\""
   echo "$0 needs app name [version]"
   exit
else
   APP=${1}
   echo "Bulding image for app ${APP}"
fi

DEF="(apk list ${APP}) | cut -d ' ' -f 1 | cut -d '-' -f 2"
GET_VERSION=${2:-$DEF}    

function Del_None {
 docker rmi -f `docker images | grep "none" | awk '{ print $3 }'` > /dev/null  2>&1
}

function RUN {
  echo -en "\033[36m"  ## blue
  $@ 2> >(while read line; do echo -e "\e[01;31m$line\e[0m" >&2; done) 
  STAT=$? 
  echo -en "\033[0m"  ## reset color
}

Del_None

docker kill ${APP}_new > /dev/null 2>&1
docker rmi -f ${APP}_new > /dev/null 2>&1
RUN  docker build --squash-all --quiet  --rm --tag ${APP}_new -f Dockerfile_${APP} 

if [ ${STAT} -ne 0 ]
then
   echo "I cannot create ${APP}_tmp image"
   exit
fi

VAR_NEW=$(docker run  --pull=never --rm ${APP}_new /bin/sh -c "${GET_VERSION}" ) 
VAR_OLD=$(docker run  --pull=never --rm ${APP} /bin/sh -c "${GET_VERSION}"  )


echo "New ${APP} $VAR_NEW"
echo "Old ${APP} $VAR_OLD"

if [ ! "${VAR_NEW}" == "${VAR_OLD}" ]
then
   docker kill ${APP}  > /dev/null 2>&1
   docker rmi  -f ${APP}  > /dev/null 2>&1
   docker tag ${APP}_new   ${APP} 
   rm ${APP}.tar   > /dev/null 2>&1
   docker save -o ${APP}.tar  ${APP} 
   echo "New version tar-ed ${VAR_OLD}" 
else
   echo "Nothing to do ..."
fi
  docker rmi -f ${APP}_new > /dev/null 2>&1
