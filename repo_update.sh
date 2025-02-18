if [ ! "$TI_ROOT" ]; then
    echo "\$TI_ROOT not defined. Exiting."
    exit 1
fi

JSDUCK_DIR=$TI_ROOT/jsduck
TI_DIR=$TI_ROOT/titanium_mobile
ALLOY_DIR=$TI_ROOT/alloy
APM_DIR=$TI_ROOT/appc_modules/appcelerator.apm
CORE_MOTION_DIR=$TI_ROOT/appc_modules/ti.coremotion
FB_DIR=$TI_ROOT/appc_modules/ti.facebook
GEOFENCE_DIR=$TI_ROOT/appc_modules/ti.geofence
HTTPS_DIR=$TI_ROOT/appc_modules/appcelerator.https
MAP_DIR=$TI_ROOT/appc_modules/ti.map
NFC_DIR=$TI_ROOT/appc_modules/ti.nfc
NEWSSTAND_DIR=$TI_ROOT/appc_modules/ti.newsstand
TIZEN_DIR=$TI_ROOT/titanium_mobile_tizen
TOUCHID_DIR=$TI_ROOT/appc_modules/ti.touchid
URL_DIR=$TI_ROOT/appc_modules/ti.urlsession
TIID_DIR=$TI_ROOT/appc_modules/titanium-identity
TI_PLAY_DIR=$TI_ROOT/appc_modules/ti.playservices


## Error handling
fail_on_error() {
    if [ $# -ne 2 ] ; then
        echo "Wrong number of arguments."
        exit 1
    fi
    if [ $1 -ne 0 ] ; then
        echo "Error: " $2
        exit 1
    fi
}


## $1 - repo name
## $2 - repo dir
## $3 - repo remote name / upstream project
## $4 - repo branch
function repo_update {
    if [ -d $2 ]; then
        echo "\nAttempting to update the $1 repo on $3/$4..."
        cd $2
        git checkout $4
        fail_on_error $? "Could not checkout $3/$4 for the $1 repo"
        git pull $3 $4
        fail_on_error $? "Pull failed for $1 repo"
    else
        echo "Warning: Cannot locate the $1 repo at $2"
    fi
}

#repo_update jsduck $JSDUCK_DIR upstream master
repo_update titanium_mobile $TI_DIR #upstream master ## update the target stream whenever this is a new major or minor version
repo_update alloy $ALLOY_DIR #upstream master
repo_update appcelerator.apm $APM_DIR origin master
repo_update ti.coremotion $CORE_MOTION_DIR #upstream master
repo_update ti.facebook $FB_DIR #upstream master
repo_update ti.geofence $GEOFENCE_DIR origin master
repo_update appcelerator.https $HTTPS_DIR #upstream master
repo_update ti.map $MAP_DIR #upstream master
repo_update ti.nfc $NFC_DIR origin master
repo_update ti.newsstand $NEWSSTAND_DIR origin master
repo_update ti.touchid $TOUCHID_DIR origin master
repo_update ti.urlsession $URL_DIR origin master
repo_update titanium-identity $TIID_DIR origin master
repo_update ti.playservices $TI_PLAY_DIR origin master

echo "Repo updates completed"
