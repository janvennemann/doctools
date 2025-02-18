#####################################################################
## Purpose: semi-automate the documentation build process locally  ##
## for public documentation build	                                 ##
##                                                                 ##
## For more information visit                                      ##
## https://wiki.appcelerator.org/x/uMHBAg                          ##
#####################################################################

## variables
DOCTOOLS=$TI_ROOT/doctools
PLATFORM=$DOCTOOLS/dist/platform
ARROWDB=$DOCTOOLS/dist/arrowdb
APPCWEBDOCS=$TI_ROOT/appc_web_docs

bold=$(tput bold) # bold formatting
normal=$(tput sgr0) #normal formatting

SECONDS=0
## empty ../platform directory
if [ -d $PLATFORM ]; then
	echo "Emptying $PLATFORM directory."
	cd $PLATFORM
	rm -r *
fi

## empty ../arrowdb directory
if [ -d $ARROWDB ]; then
	echo "Emptying $ARROWDB directory."
	cd $ARROWDB
	rm -r *
fi

cd $DOCTOOLS
rm messages.txt
touch messages.txt

# update all the required npm modules
npm i

## because the user is updating which branch to pull titanium_mobile from, this causes branch switching in other processes.
## This should only be used for generating API changes. **** change the generateAPIChanges.sh script accordingly
## ask if the repos should be updated. If not, check on the npm modules anyway
printf "update repos? [y]es?"
read -r input1
cd $DOCTOOLS
if [ $input1 == "y" ] || [ $input2 == "yes" ]; then
	echo "Updating repos.\n"
	#sh update_modules.sh ## update various modules needed by the API docs portion of the stripFooter
	#sh build_htmlguide.sh ## rebuild the htmlguide directory and it's content
else
	echo "Skipping updating the repos."
fi

# echo "Checking status of NPM modules.\n"
# sudo sh updateNPMModules.sh ## confirm that npm modules are installed in titanium_mobile and titanium_mobile_windows

## ask user if this is an SDK major or minor change. If it is, the repo_update.sh script must be updated to ensure we are pulling from the correct stream
printf "Is this a SDK major or minor change? [y]es?"
read -r input3
if [ $input3 == "y" ] || [ $input3 == "yes" ]; then
	echo "You will need to update the upstream for the git pull for the SDK in the repo_update.sh file"
	code $DOCTOOLS/repo_update.sh
else
	echo "Invalid option. If the SDK version isn't a major or minor change, then there is nothing to change in the repo_update.sh file"
fi

## run through the basic scripts to build the docs locally
cd $DOCTOOLS
sh deploy.sh prod 2> messages.txt
sh clouddeploy.sh 2>> messages.txt
sh deploy.sh -o arrow -o alloy -o modules -s prod 2>> messages.txt
node stripFooter.js 2>> messages.txt
node redirects.js 2>> messages.txt
node appendTitles.js 2>> messages.txt
#node banner.js >> messages.txt ## add banners to each HTML doc; see TIDOC-3015
sh clouddeploy.sh -s prod 2>> messages.txt
bash clouddeploy.sh prod 2>> messages.txt
bash build_platform.sh 2>> messages.txt
sh copyFavicon.sh >> messages.txt ## copy Griffin favicon.ico from ../doctools to various directories
cd $APPCWEBDOCS

## open the messages.txt file and you need to manually search for error messages
# code ./messages.txt
bash ../doctools/copy_platform.sh 2>> messages.txt
bash ../doctools/copy_cloud.sh 2>> messages.txt
cd $DOCTOOLS
sh css_fix.sh ## See TIDOC-2739
sh js_fix.sh ## See TIDOC-3141

## open localhost and manually review the pages
# open http://localhost
open http://localhost/platform/latest/
open http://localhost/platform/latest/#!/api
open http://localhost/arrowdb/latest/
open http://localhost/arrowdb/latest/#!/api
open http://localhost/platform/latest/#!/guide
echo "Manually check the page(s) you updated.\nIf everything looks good, check in the appc_web_docs directory."

## open the Jenkins job pages so you can publish the docs (as needed)
open http://devops-jenkins.appcelerator.org/job/appc_web_docs/
open http://devops-jenkins.appcelerator.org/job/server_package_deployment/

## open the messages.txt file and you need to manually search for error messages
# code ./messages.txt
rm messages.txt

duration=$SECONDS
echo "$(($duration / 60)) minutes and $(($duration % 60)) seconds elapsed."

say "public build done"

printf "Do you need to gather SDK Module version information [y]es? "
read -r input4
if [ $input4 == "y" ] || [ $input4 == "yes" ]; then
	printf "Which branch of Titanium SDK do you need to gather SDK Module info from? (i.e. #_#): "
	read -r input6
	if [ $input6 ]; then
        node gather_sdk_module_versions.js -r $input6
		say 'SDK module version data gathered'
	else
		echo "You need to enter a SDK Module version number (i.e. #_#). Skipping SDK Module data gathering step."
	fi
else
	echo "Invalid option. Skipping the step to gather SDK Module version info."
fi

printf "Do you need to gather Android SDK information for https://wiki.appcelerator.org/display/guides2/Installing+the+Android+SDK? [y]es?"
read -r input5
if [ $input5 == "y" ] || [ $input5 == "yes" ]; then
    printf "Which branch of Titanium SDK do you need to gather SDK Module info from?  (i.e. #_#): "
	read -r input7
	if [ $input7 ]; then
        node get_android_sdk_versions.js -r $input7
        say 'Android SDK data gathered'
		open https://wiki.appcelerator.org/display/guides2/Installing+the+Android+SDK
    else
        echo "You need to enter a SDK Module version number (i.e. #_#). Skipping Android SDK data gathering step."
    fi
else
	echo "Invalid option. Skipping the step to gather Android SDK version info."
fi

printf "Generate an HTML version of the release not (if this is for a SDK release)? [y]es?"
read -r input2
if [ $input2 == "y" ] || [ $input2 == "yes" ]; then
	printf "What is the Wiki page ID number?"
	read -r pageIDNumber
	if [ $pageIDNumber ]; then
		sh processSDKWikiPage.sh $pageIDNumber
	else
		echo "You must enter a page id number to generate the HTML version of the SDK release note.\nIf you still need to generate one, manually run processSDKWikiPage.sh."
	fi
fi

#### consider adding a git commit for appc_web_docs step here

printf "update solr index? [y]es?"
read -r input3
if [ $input3 == "y" ] || [ $input3 == "yes" ]; then
	SECONDS=0
	echo "Executing update_solr.sh from the appc_web_docs directory"
	cd $APPCWEBDOCS
	sh update_solr.sh
	duration=$SECONDS
	echo "$(($duration / 60)) minutes and $(($duration % 60)) seconds elapsed."
	say "solr index update done"
else
	echo "Make sure you run the update_solr.sh script after Jenkins is done:\ncd $APPCWEBDOCS; sh update_solr.sh"
fi
