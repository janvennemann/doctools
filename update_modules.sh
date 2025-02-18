##########################################################################################
##########################################################################################
## 									Purpose of Script                                                   ##
##                                                                                      ##
## Confirm that all necessary repos are accounted for and are current.                  ##
##                                                                                      ##
## Note: This script needs to be executed before the retrieval and update of the        ##
## wiki guide2 space as it will update and wipe out the doctools/htmlguides directory.  ##
##                                                                                      ##
## For more information visit                                                           ##
## https://wiki.appcelerator.org/x/dZzBAg                                               ##
##########################################################################################
##########################################################################################

SECONDS=0
DATE=$(date +%Y-%m-%d)

## create the appc_modules directory if it is missing
if [ ! -d $TI_ROOT/appc_modules ]; then
	echo "appc_modules directory is missing. Creating that directory."
	mkdir $TI_ROOT/appc_modules
fi

## back up the doctools directory to Github before updating it
echo "backing up doctools directory"
cd $TI_ROOT/doctools
git add * -f
git commit * -m "updated /doctools for $DATE commit" ## add auto-commit message
git push

## back up the appc_web_docs directory to Github before any updates
echo "backing up appc_web_docs directory"
cd $TI_ROOT/appc_web_docs
git add * -f
git commit * -m "updated /appc_web_docs for $DATE commit" ## add auto-commit message
git push

## cd into the modules directory
cd $TI_ROOT/appc_modules

updateModules () { ## check to see if a module exists and update it
	echo "${blue}Updating/Retrieving ${green}$2${white}"
	if [ $1 == "apidoc" ]; then ## if the first parameter is a module
		ACTIVE=$TI_ROOT/appc_modules/$2
		GITPATH=git@github.com:appcelerator-modules
	elif [ $1 == "misc" ]; then ## if the first parameter is a repo
		ACTIVE=$TI_ROOT/$2
		GITPATH=git@github.com:appcelerator
	elif [ $1 == "forked" ]; then ## if the first parameter is a forked repo
		ACTIVE=$TI_ROOT/$2
		GITHPATH=https://github.com/jawa9000/
		#https://github.com/appcelerator/alloy.git
	fi
	echo "Setting active directory to $ACTIVE"
	if [ ! -d "$ACTIVE" ]; then ## if the repo doesn't exist, clone it
		echo "Cloning $2"
		if [ $1 == "apidoc" ]; then
			cd $ACTIVE
		elif [ $1 == "misc" ]; then
			cd $TI_ROOT
		fi
		pwd
		git clone $GITPATH/$2.git
	else ## if the repo exists, update it
		echo "$2 exists; updating"
		cd $ACTIVE
		git clean -dfx
		git reset --hard HEAD
		git pull origin master
	fi
}

## array of apidoc modules to update from their respective repos
moduleArray=( appcelerator.apm appcelerator.https ti.cloud ti.coremotion ti.facebook ti.geofence ti.map ti.newsstand ti.nfc Ti.SafariDialog ti.touchid ti.urlsession titanium-identity ti.playservices )

## array of misc repos to update
repoArray=( appc-docs appc_web_docs arrow arrow-orm cloud_docs doctools titanium_mobile titanium_mobile_windows )

## forked repos to update
forkedArray=( alloy )

## loop through all arrays and update/clone as necessary
for i in "${moduleArray[@]}"
do
	echo "\nUpdating $i module"
	updateModules apidoc $i
done

for i in "${repoArray[@]}"
do
	echo "Updating $i repo"
	updateModules misc $i
done

for i in "${forkedArray[@]}"
do
	echo "Updating $i repo"
	updateModules forked $i
	echo "Make sure you put in a PR for $i"
done

## confirm that npm modules are installed in titanium_mobile and titanium_mobile_windows
sh updateNPMModules.sh

duration=$SECONDS
echo "$(($duration / 60)) minutes and $(($duration % 60)) seconds elapsed."

say "Modules update complete"
