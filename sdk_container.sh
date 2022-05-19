#/bin/bash

#
# Star by providing all input values
#

PROJECT_DIR=""
BUILD_TARGET=""
SDK_CONTAINER_NEW=""
BUILD_DIR=""

SDK_ENV=/home/wrlbuild/sdk/environment-setup-core2-64-wrs-linux
SDK_CONTAINER_BASE=th-sdk2
SDK_CONTAINER_REPO=device.registry.aws-training.wrstudio.cloud/th-sdk-container

# parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    -p)
        PROJECT_DIR="$2"
        shift
        ;;
    -t)
        BUILD_TARGET="$2"
        shift
        ;;
    -s)
        SDK_CONTAINER_BASE="$2"
        shift
        ;;
    -n)
        SDK_CONTAINER_NEW="$2"
        shift
        ;;
    -r)
        SDK_CONTAINER_REPO="$2"
        shift
        ;;
    -b)
        BUILD_DIR="$2"
        shift
        ;;
    -v)
        set -x
        ;;
    *)
        echo "Unknown option"
        help
        exit 1
        ;;
  esac
  shift
done

if [ -z "$PROJECT_DIR" ]
then
    echo "-p <project_dir> required"
    exit 1
fi

if [ -z "$BUILD_TARGET" ]
then
    echo "-t <build_target> required"
    exit 1
fi

#
# Now start the work to setup containers etc.
#

echo "*** start work ***"
echo "building source from: $PROJECT_DIR"
echo "building target: $BUILD_TARGET"
echo "using SKD base container: $SDK_CONTAINER_REPO/$SDK_CONTAINER_BASE"
echo "creating new SDK container: $SDK_CONTAINER_REPO/$SDK_CONTAINER_NEW"
if [ -z "$BUILD_DIR" ]
then
    BUILD_DIR=/home/tholmber/build
    BUILD_TEMP=true
    echo "building in temp directory: $BUILD_DIR"
else
    BUILD_TEMP=false
    echo "building in local directory: $BUILD_DIR"
fi
echo ""

echo "*** Pull the starting the base SDK container ***"
docker pull $SDK_CONTAINER_REPO/$SDK_CONTAINER_BASE

if [ "$BUILD_TEMP" = true ]
then
    echo "*** Start the container, temp build directory ***"
    SDK_CONT=$(docker run -it -d --rm -v $PROJECT_DIR:$PROJECT_DIR:ro --mount type=tmpfs,destination=$BUILD_DIR $SDK_CONTAINER_REPO/$SDK_CONTAINER_BASE)
else
    echo "*** Start the container, user specifified build directory ***"
    SDK_CONT=$(docker run -it -d --rm -v $PROJECT_DIR:$PROJECT_DIR:ro -v $BUILD_DIR:$BUILD_DIR:rw $SDK_CONTAINER_REPO/$SDK_CONTAINER_BASE)
fi
    
echo "*** Build the project ***"
docker exec \
       -e SDK_ENV=$SDK_ENV \
       -e PROJECT_DIR=$PROJECT_DIR \
       -e BUILD_TARGET=$BUILD_TARGET \
       -e BUILD_DIR=$BUILD_DIR \
       $SDK_CONT /bin/bash -c \
       'source $SDK_ENV; cd $BUILD_DIR; cmake $PROJECT_DIR; cmake --build . --target $BUILD_TARGET'

if [ ! -z "$SDK_CONTAINER_NEW" ]
then
    echo "*** Install the library in the SDK container ***"
    docker exec \
	   -e SDK_ENV=$SDK_ENV \
	   -e PROJECT_DIR=$PROJECT_DIR \
	   -e BUILD_TARGET=$BUILD_TARGET \
	   -e BUILD_DIR=$BUILD_DIR \
	   $SDK_CONT /bin/bash -c \
	   'source $SDK_ENV; cd $BUILD_DIR; cmake $PROJECT_DIR; cmake --install . --prefix $SDKTARGETSYSROOT/usr'

    echo "*** Create new SDK container ***"
    SDK_CONT_NEW=$(docker commit $SDK_CONT $SDK_CONTAINER_REPO/$SDK_CONTAINER_NEW)

    echo "*** Login to Studio registry ***"
    docker login --username=tholmber --password=`studio-cli devreg secret --raw` $SDK_CONTAINER_REPO

    echo "*** Push lib container to Studio registry ***"
    docker push $SDK_CONTAINER_REPO/$SDK_CONTAINER_NEW

fi

echo "*** Clean up base container ***"
docker stop $SDK_CONT

