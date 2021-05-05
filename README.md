# OverOps_Watcher

Script to monitor overops via an end-to-end test of submitting an application exception and ensuring the increase in hit count for that test application via the API 

This script should be compatible for Nagios/Zenoss as a plugin or at least not too hard to convert to work in those frameworks.

This script will health check OverOps with an end-to-end/transactional/synthetic type of test.  This script basically builds a simple java app to throw exceptions and then checks via the api to ensure the exception count has increased for this app. It assumes the OverOps agent has been already installed locally. It also assumes the jq command is available for parsing JSON results.  Note, that you might have to change the hostnames and/or ports given to the curl commands if using the on-premise version of OverOps as opposed to the SaaS example here.


# Usage
   ./overops_watcher.bash environment_id api_key


# Example 1st run output:

bash-4.4# ./overops_watcher.bash S41149 YOUR_SECRET_API_KEY_GOES_HERE

Writing the source code to a .java file to build the test app
Compiling the source code to build the test app
OK: OverOps health status is OK: hits_before: 188 hits_after: 223 hit_increase: 35

# Example output after the 1st run:

bash-4.4# ./overops_watcher.bash S41149 YOUR_SECRET_API_KEY_GOES_HERE

OK: OverOps health status is OK: hits_before: 223 hits_after: 258 hit_increase: 35

bash-4.4# ./overops_watcher.bash S41149 YOUR_SECRET_API_KEY_GOES_HERE

OK: OverOps health status is OK: hits_before: 258 hits_after: 293 hit_increase: 35

# Example failure output:

bash-4.4# ./overops_watcher.bash S41149 YOUR_SECRET_API_KEY_GOES_HERE

CRITICAL: OverOps health issue: event count failed to increase for monitor script: hits_before: 293 hits_after: 293 hit_increase: 0



