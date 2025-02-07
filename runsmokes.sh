#!/bin/bash

TESTURL="localhost:8080/samplewar"

log()
{
  echo -e "[`date '+%Y-%m-%d %T'`]:" $1
}

test_container()
{
 log "INFO: Begin Docker Sanity check"

 TESTCASES=("HttpCheck" "DBCheck")
 TURL=$1
 RETVAR=0

 for TC in "${TESTCASES[@]}"
 do
   log "INFO: Running TestCase: $TC"

   if [ ${TC} == "HttpCheck" ]; then
     curl -is --max-redirs 10 http://$TURL -L | grep -w "200 OK"
   else
     docker exec mydevdb redis-cli --version
   fi

   if [ $? -ne "0" ]; then
     log "ERROR: TESTCASE: $TC FAILED"
     RETVAR=$((RETVAR + 1))
   else
     log "INFO: TESTCASE: $TC PASSED"
   fi
 done

 log "INFO: Completed Docker Sanity check"
 return ${RETVAR}
}


#MAIN#
test_container ${TESTURL}
TRET=$?
if [ ${TRET} -ne "0" ]; then
  exit 1
fi
