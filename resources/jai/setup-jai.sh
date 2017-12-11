#!/bin/bash
set +x

# -----------------------------------------------------------------------------
# Setup JAI for the World Wind Server Kit (WWSK) - Linux 
# -----------------------------------------------------------------------------

# File and paths
PWD=$(pwd)
JAVA_HOME=${PWD}"/java"
GEOSERVER_LIB_PATH=${PWD}"/webapps/geoserver/WEB-INF/lib"
GEOSERVER_SAVE_PATH=${PWD}"/webapps/geoserver/WEB-INF/save"
JAI_ZIP="jai-1_1_3-lib-linux-amd64.tar.gz"
JAI_IMAGEIO_ZIP="jai_imageio-1_1-lib-linux-amd64.tar.gz"

## Usage instructions
usage() { 
    echo "Usage:"
    echo "  $0            Interactive install"
    echo "  $0 reinstall  Interactive install; removes previous JAI installation"
    echo "  $0 <options>  Headless install"
    echo "Options:"
    echo "  -j  install JAI support"
    echo "  -r  removes previous JAI installation"
    echo "  -h  display this help text and exit"
}

# Validate command line options.
# Each time getopts is invoked, it will place the next option in the shell variable $opt.
# If the first character of OPTSTRING is a colon, getopts uses silent error reporting.
# If an invalid option is seen, getopts places the option character found into $OPTARG.
while getopts :jrh opt; do
    case $opt in
    j)  # Install JAI support
        INSTALL_JAI=yes
        ;;
    r)  # Reinstall; removes previous install
        REINSTALL=yes
        ;;
    h)  # Help!
        echo "Installs Java Advanced Imaging (JAI) in the WWSK JRE"
        usage 
        exit 0
        ;;
    \?) # Invalid syntax
        echo "Invalid option: -${OPTARG}" >&2
        usage
        exit 1
        ;;
    :)  # If no command line args
        echo "Option: -${OPTARG} requires an argument." >$2
        ;;
    esac
done

# Place in interactive mode if no command line arguments
if [[ ! "$*" ]]; then
    INTERACTIVE=yes
fi

# Check if "reinstall" is contained in the command line arguments
if [[ "$*" =~ "reinstall"  ]]; then
    REINSTALL=yes
    INTERACTIVE=yes
fi

# -----------------------------
# Handle previous installation
# -----------------------------
if [[ -f $GEOSERVER_SAVE_PATH/jai_core-1.1.3.jar ]]; then 
    if [[ $REINSTALL ]]; then
        # Remove previous installation
        echo "Removing previous GDAL installation"
        # Remove jars
        rm $JAVA_HOME/lib/ext/jai_codec.jar
        rm $JAVA_HOME/lib/ext/jai_core.jar
        rm $JAVA_HOME/lib/ext/jai_imageio.jar    
        rm $JAVA_HOME/lib/ext/mlibwrapper_jai.jar
        rm $JAVA_HOME/lib/ext/clibwrapper_jiio.jar
        # Remove natives
        rm $JAVA_HOME/lib/amd64/libmlib_jai.so
        rm $JAVA_HOME/lib/amd64/libclib_jiio.so
        
        # Restore original JAI jars
        if [[ -d $GEOSERVER_SAVE_PATH  ]]; then
            mv $GEOSERVER_SAVE_PATH/jai_core-1.1.3.jar $GEOSERVER_LIB_PATH
            mv $GEOSERVER_SAVE_PATH/jai_codec-1.1.3.jar $GEOSERVER_LIB_PATH
            mv $GEOSERVER_SAVE_PATH/jai_imageio-1.1.jar $GEOSERVER_LIB_PATH
        fi
    else     
        # Early exit if JAI is already installed 
        echo "JAI already setup!"
        exit 0
    fi
fi
    
# ----------------------------
# Display interactive menus
# ---------------------------- 
if [[ $INTERACTIVE ]]; then  

    # Display a simple menu to install or skip JAI
    echo
    echo "Java Advanced Imaging (JAI):"
    PS3="Install JAI? "
    select JAI_CHOICE in Install Skip Help
    do 
        case "$JAI_CHOICE" in
        (Install) 
            INSTALL_JAI=yes
            break 
            ;;
        (Skip) 
            echo "Skipping JAI installation"
            break 
            ;;
        (Help) 
            echo "Java Advanced Imaging (JAI) Help"
            echo "================================"
            echo "JAI is perported to improve the performance of GeoServer in may instances."
            echo "Warning: installing JAI may cause errors with JPEG/WorldImage data stores."
            echo "To remove JAI, run './setup reinstall' and then skip the JAI installation"
            echo "or run './setup-jai.sh -r'"
            ;;
        (*) 
            echo "Invalid selection. Try again (1..3)!" 
            ;;
        esac
    done
fi  

# -----------------------------
# Perform the JAI installation
# -----------------------------
if [[ $INSTALL_JAI ]]; then
        # Install JAI and natives
        gunzip -c jai-1_1_3-lib-linux-amd64.tar.gz | tar xf - && \
        mv jai-1_1_3/lib/*.jar $JAVA_HOME/lib/ext/ && \
        mv jai-1_1_3/lib/*.so $JAVA_HOME/lib/amd64/ 
        rm -r jai-1_1_3

        # Install JAI ImageIO and natives
        gunzip -c jai_imageio-1_1-lib-linux-amd64.tar.gz | tar xf - && \
        mv jai_imageio-1_1/lib/*.jar $JAVA_HOME/lib/ext/ && \
        mv jai_imageio-1_1/lib/*.so $JAVA_HOME/lib/amd64/ 
        rm -r jai_imageio-1_1

        # Save original pure-java JAI jars
        mkdir -p ${GEOSERVER_LIB_PATH}/../save
        mv ${GEOSERVER_LIB_PATH}/jai_core-1.1.3.jar ${GEOSERVER_SAVE_PATH}
        mv ${GEOSERVER_LIB_PATH}/jai_codec-1.1.3.jar ${GEOSERVER_SAVE_PATH}
        mv ${GEOSERVER_LIB_PATH}/jai_imageio-1.1.jar ${GEOSERVER_SAVE_PATH}

    echo  "JAI setup complete"
else 
    echo  "JAI setup skipped"
fi
