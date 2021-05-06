#!/bin/bash
#NAME: Michael Mastrogiacomo
#DATE: 5-5-2021
#PURPOSE: Script to health check OverOps with an end-to-end/transactional/synthetic type of test.  This script basically builds a simple java app to throw exceptions and then checks via the api to ensure the exception count
#         has increased for this app. It assumes the OverOps agent has been already installed locally. It also assumes the jq command is available for parsing JSON results.   
#         Note also that you might have to change the hostnames and/or ports given to the curl commands if using the on-premise version of OverOps as opposed to the SaaS example here.


ENVID=$1
APIKEY=$2

if [[ -z $2 ]]; then
   echo Usage:  $0 environment_id api_key
   exit 1
fi

# these may be set in agent.properties or here to match your environment
#export TAKIPI_COLLECTOR_HOST="172.17.0.1"                            
#export TAKIPI_COLLECTOR_PORT="6060"                                                                        
#export JAVA_HOME=/usr/lib/jvm/java-1.8-openjdk/  #you'll want to set this to match the java home of your system                                                                                                                                              
#export LD_LIBRARY_PATH="/opt/takipi/lib"                                                                                                                                                       
#export TAKIPI_SHUTDOWN_GRACETIME="20000"       

export TAKIPI_APPLICATION_NAME="overops_watcher"                                
export TAKIPI_DEPLOYMENT_NAME="overops_watcher"    

#echo installing the OverOps agent  -- commented out here; see OverOps documentation on how to install the agent
#mkdir -p /opt
#cd /opt
#curl -sL https://s3.amazonaws.com/app-takipi-com/deploy/linux/takipi-agent-latest.tar.gz | tar -xvzf -  # for redhat
#curl -sL "https://s3.amazonaws.com/app-takipi-com/deploy/alpine/takipi-agent-4.59.0.tar.gz" | tar -xvzf -   # for alpine linux
#touch /opt/takipi/agent.properties
#echo now installing a test app
#yum -y install java-1.8.0-openjdk-devel

if [[ ! -d /opt/overops_watcher ]]; then
   mkdir -p /opt/overops_watcher
fi
cd /opt/overops_watcher

if [[ ! -f OverOpsWatcher.java ]]; then
   echo Writing the source code to a .java file to build the test app
   echo -e "import java.util.*; import java.io.*; public class OverOpsWatcher { public static void main(String args[]) { int i=0; while (i < 35) { int j = 35 - i; System.out.println(j); try{Thread.sleep(1000);}catch(InterruptedException e){System.out.println(e);} try {throw new EmptyStackException();}catch( EmptyStackException e){}; i = i + 1; } } }" > OverOpsWatcher.java
fi

if [[ ! -f OverOpsWatcher.class ]]; then
   echo Compiling the source code to build the test app
   $JAVA_HOME/bin/javac OverOpsWatcher.java
fi


D=$(date '+%Y-%m-%d')
FROM="${D}T00:00:00.000Z" 
TO="${D}T23:59:59.000Z"
AUTH_HEADER="x-api-key:$APIKEY"


# Fetch the view ID for the test app
VIEWID=$(curl -H $AUTH_HEADER --request GET --url https://api.overops.com/api/v1/services/$ENVID/views 2> /dev/null | jq '.views[] | select(.name == "overops_watcher") | .id' | sed 's/\"//g')

# Fetch the hit count before the test app runs and generates exceptions
HITS_BEFORE=$(curl -H $AUTH_HEADER -H "Content-Type:application/json" --request GET "https://api.overops.com/api/v1/services/$ENVID/views/$VIEWID/events?from=${FROM}&to=${TO}&stacktrace=true" 2> /dev/null | jq '.events[] .stats .hits')

# Running the test app
$JAVA_HOME/bin/java -agentpath:/opt/takipi/lib/libTakipiAgent.so OverOpsWatcher > /dev/null

# sleep to give OverOps sometime to process the events
sleep 5

# Fetch the hit count after the test app ran for comparison
HITS_AFTER=$(curl -H $AUTH_HEADER -H "Content-Type:application/json" --request GET "https://api.overops.com/api/v1/services/$ENVID/views/$VIEWID/events?from=${FROM}&to=${TO}&stacktrace=true" 2> /dev/null | jq '.events[] .stats .hits')

let HIT_INCREASE="HITS_AFTER - HITS_BEFORE"

STATS="hits_before: $HITS_BEFORE hits_after: $HITS_AFTER hit_increase: $HIT_INCREASE"

if (( $HIT_INCREASE < 1 )); then
   echo "CRITICAL: OverOps health issue: event count failed to increase for monitor script: $STATS"
   exit 2
fi

echo "OK: OverOps health status is OK: $STATS"




