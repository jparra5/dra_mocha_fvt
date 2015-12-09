#!/bin/bash

#********************************************************************************
# Copyright 2014 IBM
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#********************************************************************************

#############
# Colors    #
#############
export green='\e[0;32m'
export red='\e[0;31m'
export label_color='\e[0;33m'
export no_color='\e[0m' # No Color

##################################################
# Simple function to only run command if DEBUG=1 # 
### ###############################################
debugme() {
  [[ $DEBUG = 1 ]] && "$@" || :
}

set +e
set +x 

npm install grunt
npm install grunt-cli
npm install grunt-idra



function dra_commands {
    dra_grunt_command=""
    
    if [ -n "$1" ] && [ "$1" != " " ]; then
        echo "Event: '$1' is defined and not empty"
        
        dra_grunt_command="grunt --gruntfile=node_modules/grunt-idra/idra.js -eventType=$1"
        
        echo -e "\tdra_grunt_command: $dra_grunt_command"
        
        if [ -n "$2" ] && [ "$2" != " " ]; then
            echo -e "\tFile: '$2' is defined and not empty"
            
            dra_grunt_command="$dra_grunt_command -file=$2"
        
            echo -e "\t\tdra_grunt_command: $dra_grunt_command"
            
        else
            echo -e "\tFile: '$2' is not defined or is empty"
        fi
        #if [ -n "$3" ] && [ "$3" != " " ]; then
        #    echo -e "\tServer: '$3' is defined and not empty"
        #
        #    dra_grunt_command="$dra_grunt_command -deployAnalyticsServer=$3"
        #
        #    echo -e "\t\tdra_grunt_command: $dra_grunt_command"
        #
        #else
        #    echo -e "\tServer: '$3' is not defined or is empty"
        #fi
        
        echo -e "\tFINAL dra_grunt_command: $dra_grunt_command"
        echo ""
        
        eval $dra_grunt_command
    else
        echo "Event: '$1' is not defined or is empty"
    fi
}

function criteria_for_ut {
    dra_grunt_command=""
    
    if [ -n "$1" ] && [ "$1" != " " ]; then
        echo "Event: '$1' is defined and not empty"
        
        dra_grunt_command="grunt --gruntfile=node_modules/grunt-idra/idra.js -eventType=$1"
        
        echo -e "\tdra_grunt_command: $dra_grunt_command"
        
        if [ -n "$2" ] && [ "$2" != " " ]; then
            echo -e "\tFile: '$2' is defined and not empty"
            
            dra_grunt_command="$dra_grunt_command -file=$2"
        
            echo -e "\t\tdra_grunt_command: $dra_grunt_command"
            
        else
            echo -e "\tFile: '$2' is not defined or is empty"
        fi
        #if [ -n "$3" ] && [ "$3" != " " ]; then
        #    echo -e "\tServer: '$3' is defined and not empty"
        #
        #    dra_grunt_command="$dra_grunt_command -deployAnalyticsServer=$3"
        #
        #    echo -e "\t\tdra_grunt_command: $dra_grunt_command"
        #
        #else
        #    echo -e "\tServer: '$3' is not defined or is empty"
        #fi
        
        echo -e "\tFINAL dra_grunt_command: $dra_grunt_command"
        echo ""
        
        eval $dra_grunt_command
    else
        echo "Event: '$1' is not defined or is empty"
    fi
}



echo "DRA_PROJECT_KEY: ${DRA_PROJECT_KEY}"

echo "DRA_TEST_TOOL_SELECT: ${DRA_TEST_TOOL_SELECT}"
echo "DRA_TEST_LOG_FILE: ${DRA_TEST_LOG_FILE}"
echo "DRA_MINIMUM_SUCCESS_RATE: ${DRA_MINIMUM_SUCCESS_RATE}"
echo "DRA_CHECK_TEST_REGRESSION: ${DRA_CHECK_TEST_REGRESSION}"

echo "DRA_CRITICAL_TESTCASES: ${DRA_CRITICAL_TESTCASES}"



custom_cmd



criteriaList=()


if [ -n "${DRA_TEST_TOOL_SELECT}" ] && [ "${DRA_TEST_TOOL_SELECT}" != "none" ] && \
    [ -n "${DRA_TEST_LOG_FILE}" ] && [ "${DRA_TEST_LOG_FILE}" != " " ]; then

    dra_commands "${DRA_TEST_TOOL_SELECT}UnitTest" "${DRA_TEST_LOG_FILE}"
    
    if [ -n "${DRA_MINIMUM_SUCCESS_RATE}" ] && [ "${DRA_MINIMUM_SUCCESS_RATE}" != " " ]; then
        name="At least ${DRA_MINIMUM_SUCCESS_RATE}% success in unit tests (${DRA_TEST_TOOL_SELECT})"
        criteria="{ \"name\": \"$name\", \"conditions\": [ { \"eval\": \"_mochaTestSuccessPercentage\", \"op\": \">=\", \"value\": ${DRA_MINIMUM_SUCCESS_RATE} } ] }"
        
#        if [ "${DRA_TEST_TOOL_SELECT}" == "mochaKarma" ]; then
#            criteria="{ \"name\": \"$name\", \"conditions\": [ { \"eval\": \"_karmaMochaTestSuccessPercentage\", \"op\": \">=\", \"value\": ${DRA_MINIMUM_SUCCESS_RATE} } ] }"
#        fi
        
        echo "criteria:  $criteria"
        criteriaList=("${criteriaList[@]}" "$criteria")
    fi

    if [ -n "${DRA_CHECK_TEST_REGRESSION}" ] && [ "${DRA_CHECK_TEST_REGRESSION}" == "true" ]; then
        name="No Regression in Unit Tests (${DRA_TEST_TOOL_SELECT})"
        criteria="{ \"name\": \"$name\", \"conditions\": [ { \"eval\": \"_hasMochaTestRegressed\", \"op\": \"=\", \"value\": false } ] }"
        
        if [ "${DRA_TEST_TOOL_SELECT}" == "mochaKarma" ]; then
            criteria="{ \"name\": \"$name\", \"conditions\": [ { \"eval\": \"_hasKarmaMochaTestRegressed\", \"op\": \"=\", \"value\": false } ] }"
        fi
        
        echo "criteria:  $criteria"
        criteriaList=("${criteriaList[@]}" "$criteria")
    fi
    
    if [ -n "${DRA_CRITICAL_TESTCASES}" ] && [ "${DRA_CRITICAL_TESTCASES}" != " " ]; then
        name="No critical functional test failures (${DRA_TEST_TOOL_SELECT})"
        criteria="{ \"name\": \"$name\", \"conditions\": [ { \"eval\": \"_hasSaucelabCriticalTestPassed(${DRA_CRITICAL_TESTCASES})\", \"op\": \"=\", \"value\": true } ] }"
        
        echo "criteria:  $criteria"
        criteriaList=("${criteriaList[@]}" "$criteria")
    fi
fi









echo ${criteriaList[@]}

criteria="{ \"name\": \"DynamicCriteria\", \"revision\": 2, \"project\": \"key\", \"mode\": \"decision\", \"rules\": [ "

for i in "${criteriaList[@]}"
do
	criteria="$criteria $i,"
done


criteria="${criteria%?}"
criteria="$criteria ] }"


echo $criteria > dynamicCriteria.json


cat dynamicCriteria.json

grunt --gruntfile=node_modules/grunt-idra/idra.js -decision=dynamic -criteriafile=dynamicCriteria.json 