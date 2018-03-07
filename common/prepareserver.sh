#   Licensed Materials - Property of IBM
#   5725-I43 (C) Copyright IBM Corp. 2015, 2016. All Rights Reserved.
#   US Government Users Restricted Rights - Use, duplication or
#   disclosure restricted by GSA ADP Schedule Contract with IBM Corp.

#!/usr/bin/bash


dockerBuild()
{

    trap clean_up 0 1 2 3 15

    mv ../../dependencies ../dependencies
    mv ../../mfpf-libs ../mfpf-libs
    cp -rf ../../licenses ../licenses
    echo "Building the MobileFirst image : " $IMAGE_TAG
    docker build -t $1 ../
    if (( $? != 0 ))
    then
        echo "The command docker build -t $IMAGE_TAG ../ failed."
        exit 1
    fi

    mv ../dependencies ../../dependencies
    mv ../mfpf-libs ../../mfpf-libs
    rm -rf ../licenses
    rm ../Dockerfile

}

clean_up() {
# Perform clean up before exiting

    if [ -d ../dependencies ]
    then
        mv ../dependencies ../../dependencies
    fi
    if [ -d ../mfpf-libs ]
    then
        mv ../mfpf-libs ../../mfpf-libs
    fi

    if [ -d ../licenses ]
    then
        rm -rf ../licenses
    fi
}
