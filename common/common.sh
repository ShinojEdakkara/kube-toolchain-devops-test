#   Licensed Materials - Property of IBM 
#   5725-I43 (C) Copyright IBM Corp. 2011, 2015. All Rights Reserved.
#   US Government Users Restricted Rights - Use, duplication or
#   disclosure restricted by GSA ADP Schedule Contract with IBM Corp.  
   
#!/usr/bin/bash

validateArg() 
{
   if [ -z "$1" ]
   then
      echo Mandatory argument must be specified. Exiting...
      exit 0
   fi
}

verifyCFICCLI()
{
    echo ""
    echo "Checking if cf ic plugin is installed ..."
    echo ""

    result="$(cf plugins 2>/dev/null | grep "IBM-Containers" )"
    if [ -z "$result" ]
    then 
    	echo cf ic plugin is not installed
    	echo Install cf tool and cf ic plugin 
    	exit 1
    else
        echo $(cf -v)
        echo ""
    fi
}

verifyBXCSCLI()
{
    echo ""
    echo "Checking if bx cs plugin is installed ..."

    result="$(bx plugin list 2>/dev/null | grep "container-service" )"
    if [ -z "$result" ]
    then 
    	echo bx cs plugin is not installed
    	echo Install bx cli tool and bx cs plugin 
    	exit 1
    fi
}

verifyBXCRCLI()
{
    echo "Checking if bx cr plugin is installed ..."
    echo ""

    result="$(bx plugin list 2>/dev/null | grep "container-registry" )"
    if [ -z "$result" ]
    then 
    	echo bx cr plugin is not installed
    	echo Install bx cli tool and bx cr plugin 
    	exit 1
    fi
}

verifyCF()
{
    echo ""
    echo "Checking if cf CLI is installed ..."
    echo ""

    result="$(cf -v 2>/dev/null | grep "version" )"
    if [ -z "$result" ]
    then 
    	echo cf ic plugin is not installed
    	echo Install cf tool and cf ic plugin 
    	exit 1
    else
        echo $(cf -v)
        echo ""
    fi
}

validateURL()
{
        regex='(https|http)://[-A-Za-z0-9\+&@#/%?=~_|!:,.;]*[-A-Za-z0-9\+&@#/%=~_|]'
		if echo "$1"|grep -Eq "$regex";then
			echo "0"
		else
		    echo "1"
		fi
}

fnReadURL()
{
		trap - SIGINT

        ErrorMsg=$2
        InputMsg=$1
        defaultURL=$3

        while read -p "$InputMsg" READ_URL_STRING
        do
                
		if [ -z "$READ_URL_STRING" ]
                then
                        READ_URL_STRING="$defaultURL"
                        break
                fi

                if [ "$(validateURL $READ_URL_STRING)" = "0" ]
                then
                        break
                fi
                InputMsg="$ErrorMsg"
        done
        echo $READ_URL_STRING
}

fnReadInput()
{
		trap - SIGINT
        
		ErrorMsg=$2
        InputMsg=$1

        while read -p "$InputMsg" READ_INPUT_STRING
        do
                if [ ! -z "$READ_INPUT_STRING" ]
                then
                        break
                fi
                InputMsg="$ErrorMsg"
        done
        echo $READ_INPUT_STRING
}

fnReadPassword(){
        trap "stty echo" 0 1 2 3 15

        ErrorMsg=$2
        InputMsg=$1

        while read -s -p "$InputMsg" READ_INPUT_STRING
        do
                if [ ! -z "$READ_INPUT_STRING" ]
                then
                        break
                fi
                InputMsg="$ErrorMsg"
        done
        echo $READ_INPUT_STRING
}

readDBTypeInputAsOptions()
{
        trap - SIGINT
	
		ErrorMsg=$2
        InputMsg=$1

        while read -p "$InputMsg" READ_INPUT_STRING
        do
            	if [ -z "$READ_INPUT_STRING" ]
                then
                       READ_INPUT_STRING="3"
                fi

                if [ "$READ_INPUT_STRING" = "1" ]
                then
                        OUTPUT_STRING="dashDB"
                        break
                elif [ "$READ_INPUT_STRING" = "2" ]
                then
                        OUTPUT_STRING="DB2"
                        break
                fi

                InputMsg="$ErrorMsg"
        done
        echo $OUTPUT_STRING
}

readSQLDBServPlanOptions()
{
        trap - SIGINT 
        
		ErrorMsg=$2
        InputMsg=$1

        while read -p "$InputMsg" READ_INPUT_STRING
        do
                if [ -z "$READ_INPUT_STRING" ]
                then
                       READ_INPUT_STRING="4"
                fi

                if [ "$READ_INPUT_STRING" = "1" ]
                then
                        OUTPUT_STRING="sqldb_free"
                        break
                elif [ "$READ_INPUT_STRING" = "2" ]
                then
                        OUTPUT_STRING="sqldb_premium"
                        break
                fi

                InputMsg="$ErrorMsg"
        done
        echo $OUTPUT_STRING

}

validateDBType()
{
    input=$1
    if [ "$input" = "sqldb" ] || [ "$input" = "cloudantNoSQLDB" ]
    then
        echo "0"
    else
        echo "1"
    fi
}

validateDBServiceOption()
{
	input=$2
	dbtype=$1
	
	if [ "$dbtype" = "sqldb" ]
	then
		if [ "$input" = "sqldb_premium" ] || [ "$input" = "sqldb_free" ]
		then
			echo "0"
		else
			echo "1"
		fi
	elif [ "$dbtype" = "cloudantNoSQLDB" ]
	then
		if [ "$input" = "Shared" ]
		then
			echo "0"
		else
			echo "1"
		fi
	fi
}

valid_ip()
{
      IP=$1	
      TEST=`echo "${IP}." | grep -E "([0-9]{1,3}\.){4}"`

      if [ "$TEST" ]
      then
         echo "$IP" | awk -F. '{
            if ( (($1>=0) && ($1<=255)) &&
                 (($2>=0) && ($2<=255)) &&
                 (($3>=0) && ($3<=255)) &&
                 (($4>=0) && ($4<=255)) ) {
               print("0");
            } else {
               print("1");
            }
         }'
      else
         echo "1"
      fi
}

fnReadIP()
{
		trap - SIGINT
	
		ErrorMsg=$2
        InputMsg=$1

        while read -p "$InputMsg" READ_IP_STRING
        do
            if [ "$(valid_ip $READ_IP_STRING)" = "0" ]
                then
                        break
                fi
                InputMsg="$ErrorMsg"
		done
		echo "$READ_IP_STRING"
		
}

fnReadNumericInput()
{
		trap - SIGINT

    	ErrorMsg=$2
        InputMsg=$1
        defaultCount=$3

        while read -p "$InputMsg" READ_NUMBER_STRING
        do
                if [ -z "$READ_NUMBER_STRING" ]
                then
                        READ_NUMBER_STRING="$defaultCount"
                        break
                fi

                if [ "$(isNumber $READ_NUMBER_STRING)" = "0" ]
                then
                    break
                fi
                InputMsg="$ErrorMsg"
        done
        echo $READ_NUMBER_STRING
 
}

fnReadPort()
{
		trap - SIGINT

    	ErrorMsg=$2
        InputMsg=$1

        while read -p "$InputMsg" READ_NUMBER_STRING
        do
                if [ "$(isNumber $READ_NUMBER_STRING)" = "0" ]
                then
                    break
                fi
                InputMsg="$ErrorMsg"
        done
        echo $READ_NUMBER_STRING
 
}

isNumber()
{
    input=$1
    if [ $input -eq $input 2>/dev/null ]
    then
        echo "0"
    else
        echo "1"
    fi

}

readBoolean(){
        trap - SIGINT

        ErrorMsg=$2
        InputMsg=$1
        defaultValue=$3

        while read -p "$InputMsg" READ_INPUT_OPTION
        do
                if [ -z "$READ_INPUT_OPTION" ]
                then
                        READ_INPUT_OPTION="$defaultValue"
                        break
                fi

                if [ "$(validateBoolean $READ_INPUT_OPTION)" = "0" ]
                then
                    if [ "$READ_INPUT_OPTION" = "y" ]
                    then
                           READ_INPUT_OPTION="Y"
                    fi
                    break
                fi
                InputMsg="$ErrorMsg"
        done
        echo $READ_INPUT_OPTION
}

validateBoolean()
{
        input=$1

        if [ "$input" = "Y" ] || [ "$input" = "y" ] || [ "$input" = "N" ] || [ "$input" = "n" ]
        then
                echo "0"
        else
                echo "1"
        fi

}

createVolumes() 
{
  echo "Creating volumes"
  
  sysvol_exist="False"
  libertyvol_exist="False"
  
  volumes="$(cf ic volume list)"

  if [ ! -z "${volumes}" ]
   then
      for mVar in ${volumes}
      do
		 if [[ "$mVar" = "$SYSVOL_NAME" ]]
         then
            sysvol_exist="True"
            continue
         elif [[ "$mVar" = "$LIBERTYVOL_NAME" ]]
         then
           libertyvol_exist="True"
         fi
      done
   fi

   if [[ "$sysvol_exist" = "True" ]]
   then
      echo "Volume already exists: $SYSVOL_NAME. This volume will be used to store sys logs."
   else
      echo "The volume $SYSVOL_NAME will be created to store sys logs."
      eval "cf ic volume create $SYSVOL_NAME"
   fi
   
   if [[ "$libertyvol_exist" = "True" ]]
   then
      echo "Volume already exists: $LIBERTYVOL_NAME. This volume will be used to store Liberty logs."
   else
      echo "The volume $LIBERTYVOL_NAME will be created to store Liberty logs."
      eval "cf ic volume create $LIBERTYVOL_NAME"
   fi
}

recordInputParams()
{

    if [ -z $ARGS_PROPS_FILE ]
    then
        echo "Cannot record the input parameters into a properties file. PROPS_FILE is an empty variable. "
        return;
    fi 
    
    if [ ! -d ./recorded-args/ ]
    then
        mkdir ./recorded-args/
    fi 
    export NEW_PROPS_FILE="./recorded-args/${ARGS_PROPS_FILE}"

    if [ -z $NEW_PROPS_FILE ]
    then
        echo "Cannot record the input parameters into a properties file. PROPS_FILE is an empty variable. "
        return;
    fi 
    
    if [ -f $NEW_PROPS_FILE ]
    then
        rm $NEW_PROPS_FILE
    fi
    all_args=`echo $* | tr '#' '\n'`
    
    if [ ! -f ./args/${ARGS_PROPS_FILE} ]
    then
        echo "Unable to read the original args/propeties file at ./args/${ARGS_PROPS_FILE}. Creating the new properties file ${NEW_PROPS_FILE} with just input parameters. "
        echo "${all_args}" >> ${NEW_PROPS_FILE}
    else
        echo "Saving a copy of the input parameters into the file: ${NEW_PROPS_FILE}."
        cp ./args/${ARGS_PROPS_FILE} ${NEW_PROPS_FILE}
        echo "${all_args}" | while read oneLine
        do
                oneParamName=$(echo ${oneLine} | cut -d"=" -f1 )
                oneParamValue=$(echo ${oneLine} | cut -d"=" -f2 )
                if [ "${oneParamValue}" = "" ]
                then
                        sed -i.bak "s#^.*${oneParamName}=.*\$#${oneParamName}=${oneParamValue}#g" ${NEW_PROPS_FILE} 
                else
                        sed -i.bak "s#^.*${oneParamName}=.*\$#${oneParamName}=\"${oneParamValue}\"#g" ${NEW_PROPS_FILE} 
                fi
        done
    fi


}

getDetails()
{
        export CF_TARGET=$(cf target | tr '\n' '#' )
        export CF_API=$(echo $(echo $CF_TARGET | cut -d'#' -f2  | cut -d'.' -f2))
        export CF_USER=$(echo $(echo $CF_TARGET | cut -d'#' -f3  | cut -d':' -f2))
        export CF_ORG=$(echo $(echo $CF_TARGET | cut -d'#' -f4  | cut -d':' -f2))
        export CF_SPACE=$(echo $(echo $CF_TARGET | cut -d'#' -f5  | cut -d':' -f2))
        export CF_NAME=$1
        export DETAILS_STRING=${CF_API}_${CF_ORG}_${CF_SPACE}_${CF_USER}_${CF_NAME}
        echo MFBYOL_80_${DETAILS_STRING}
}

unset CF_TRACE

# The volume name and the path in the container that the volume will be mounted
SYSVOL_NAME=sysvol
LIBERTYVOL_NAME=libertyvol
SYSVOL_PATH=/var/log/rsyslog
LIBERTYVOL_PATH=/opt/ibm/wlp/usr/servers/mfp/logs
