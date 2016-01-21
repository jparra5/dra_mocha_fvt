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
npm install grunt-idra2



function dra_commands {
    echo -e "${no_color}"
    dra_grunt_command=""
    
    if [ -n "$1" ] && [ "$1" != " " ]; then
        #echo "Event: '$1' is defined and not empty"
        
        dra_grunt_command="grunt --gruntfile=node_modules/grunt-idra2/idra.js -eventType=$1"
        
        #echo -e "\tdra_grunt_command: $dra_grunt_command"
        
        if [ -n "$2" ] && [ "$2" != " " ]; then
            #echo -e "\tFile: '$2' is defined and not empty"
            
            dra_grunt_command="$dra_grunt_command -file=$2"
        
            #echo -e "\t\tdra_grunt_command: $dra_grunt_command"
            
        #else
            #echo -e "File: '$2' is not defined or is empty"
            #echo -e "${no_color}"
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
        
        #echo -e "FINAL dra_grunt_command: $dra_grunt_command"
        #echo -e "${no_color}"
        
        eval $dra_grunt_command
        GRUNT_RESULT=$?
        
        if [ $GRUNT_RESULT -ne 0 ]; then
            exit 1
        fi
    #else
        #echo "Event: '$1' is not defined or is empty"
    fi
    
    echo -e "${no_color}"
}


#echo -e "${no_color}"
#echo "DRA_TEST_TOOL_SELECT: ${DRA_TEST_TOOL_SELECT}"
#echo "DRA_TEST_LOG_FILE: ${DRA_TEST_LOG_FILE}"
#echo "DRA_MINIMUM_SUCCESS_RATE: ${DRA_MINIMUM_SUCCESS_RATE}"
#echo "DRA_CHECK_TEST_REGRESSION: ${DRA_CHECK_TEST_REGRESSION}"

#echo "DRA_CRITICAL_TESTCASES: ${DRA_CRITICAL_TESTCASES}"
#echo -e "${no_color}"


export CF_TOKEN=$(sed -e 's/^.*"AccessToken":"\([^"]*\)".*$/\1/' ~/.cf/config.json)

custom_cmd

echo -e "${no_color}"





${EXT_DIR}/dra-check.py ${PIPELINE_TOOLCHAIN_ID} "${CF_TOKEN}" "${IDS_PROJECT_NAME}"
RESULT=$?

#0 = DRA is present
#1 = DRA not present or there was an error with the http call (err msg will show)
#echo $RESULT

if [ $RESULT -eq 0 ]; then
    #echo "DRA is present";
    
    criteriaList=()


    if [ -n "${DRA_TEST_TOOL_SELECT}" ] && [ "${DRA_TEST_TOOL_SELECT}" != "none" ] && \
        [ -n "${DRA_TEST_LOG_FILE}" ] && [ "${DRA_TEST_LOG_FILE}" != " " ]; then

        dra_commands "${DRA_TEST_TOOL_SELECT}FunctionalTest" "${DRA_TEST_LOG_FILE}"

        if [ -n "${DRA_MINIMUM_SUCCESS_RATE}" ] && [ "${DRA_MINIMUM_SUCCESS_RATE}" != " " ]; then
            name="At least ${DRA_MINIMUM_SUCCESS_RATE}% success in functional tests (${DRA_TEST_TOOL_SELECT})"
            criteria="{ \"name\": \"$name\", \"conditions\": [ { \"eval\": \"_mochaTestSuccessPercentage\", \"op\": \">=\", \"value\": ${DRA_MINIMUM_SUCCESS_RATE}, \"forEventType\": \"${DRA_TEST_TOOL_SELECT}FunctionalTest\" } ] }"

    #        if [ "${DRA_TEST_TOOL_SELECT}" == "mochaKarma" ]; then
    #            criteria="{ \"name\": \"$name\", \"conditions\": [ { \"eval\": \"_karmaMochaTestSuccessPercentage\", \"op\": \">=\", \"value\": ${DRA_MINIMUM_SUCCESS_RATE} } ] }"
    #        fi

            #echo "criteria:  $criteria"
            criteriaList=("${criteriaList[@]}" "$criteria")
        fi

        if [ -n "${DRA_CHECK_TEST_REGRESSION}" ] && [ "${DRA_CHECK_TEST_REGRESSION}" == "true" ]; then
            name="No regression in functional tests (${DRA_TEST_TOOL_SELECT})"
            criteria="{ \"name\": \"$name\", \"conditions\": [ { \"eval\": \"_hasMochaTestRegressed\", \"op\": \"=\", \"value\": false, \"forEventType\": \"${DRA_TEST_TOOL_SELECT}FunctionalTest\" } ] }"

            if [ "${DRA_TEST_TOOL_SELECT}" == "mochaKarma" ]; then
                criteria="{ \"name\": \"$name\", \"conditions\": [ { \"eval\": \"_hasKarmaMochaTestRegressed\", \"op\": \"=\", \"value\": false, \"forEventType\": \"${DRA_TEST_TOOL_SELECT}FunctionalTest\" } ] }"
            fi

            #echo "criteria:  $criteria"
            criteriaList=("${criteriaList[@]}" "$criteria")
        fi

        if [ -n "${DRA_CRITICAL_TESTCASES}" ] && [ "${DRA_CRITICAL_TESTCASES}" != " " ]; then
            name="No critical functional test failures (${DRA_TEST_TOOL_SELECT})"
            criteria="{ \"name\": \"$name\", \"conditions\": [ { \"eval\": \"_hasMochaCriticalTestsPassed(${DRA_CRITICAL_TESTCASES})\", \"op\": \"=\", \"value\": true, \"forEventType\": \"${DRA_TEST_TOOL_SELECT}FunctionalTest\" } ] }"

            #echo "criteria:  $criteria"
            criteriaList=("${criteriaList[@]}" "$criteria")
        fi
    fi









    if [ ${#criteriaList[@]} -gt 0 ]; then
        criteria="{ \"name\": \"DynamicCriteria\", \"revision\": 2, \"project\": \"key\", \"mode\": \"decision\", \"rules\": [ "

        for i in "${criteriaList[@]}"
        do
            criteria="$criteria $i,"
        done


        criteria="${criteria%?}"
        criteria="$criteria ] }"


        echo $criteria > dynamicCriteria.json

        #echo "Dynamic Criteria:"
        #cat dynamicCriteria.json

        echo -e "${no_color}"
        grunt --gruntfile=node_modules/grunt-idra2/idra.js -decision=dynamic -criteriafile=dynamicCriteria.json 
        DECISION_RESULT=$?
        echo -e "${no_color}"
        
        return $DECISION_RESULT
    fi
#else
    #echo "DRA is not present";
fi    