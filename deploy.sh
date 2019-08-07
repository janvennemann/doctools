DEBUG_TEMPLATE=template
PROD_TEMPLATE=template-min
VIDEO_LIST="videos.json"
PROCESSED_VIDEO_LIST="build/videos.json"
config="./jsduck.config"
guidesdir="./htmlguides"
outdir="./dist/platform/latest"
title="Appcelerator Platform - Appcelerator Docs"

progname=$0

usage() {
    echo "Usage: $progname [options] [debug|prod]"
    echo ""
    echo "  Options:"
    echo "  -c <config_file> (i.e., jsduck_21.config for 2.1 docs build)."
    echo "  -o <optional_project> (currently 'alloy', 'modules', 'arrow' are supported)"
    echo "  -g <guides_dir> (defaults to htmlguides)."
    echo "  -a <addon_guides_dir> Specified add-on guides."
    echo "  -d <output_dir> (defaults to dist/titanium/3.0)."
    echo "  -s  Enable --seo flag to jsduck."
    echo "  -t <title> Specify title for doc site."
    echo ""
}

while getopts ":so:a:c:d:g:t:j:" opt; do
    case $opt in
        a)
            if [ "$OPTARG" ]; then
                addon_guidesdir=$OPTARG
            fi
            ;;
        c)
            if [ "$OPTARG" ]; then
                config=$OPTARG
            fi
            ;;
        d)
            if [ "$OPTARG" ]; then
                outdir=$OPTARG
            fi
            ;;
        o)
            if [ $OPTARG == "alloy" ]; then
                include_alloy="include_alloy"
            elif [ $OPTARG = "arrow" ]; then
                include_arrow="include_arrow"
            elif [ $OPTARG = "modules" ]; then
                include_modules="include_modules"
            else
                echo "Unknown optional project, $OPTARG">&2
                usage
                exit 1
            fi
            ;;
        g)
            if [ "$OPTARG" ]; then
                guidesdir=$OPTARG
            fi
            ;;
        s)
            seo="--seo"
            ;;
        t)
            if [ "$OPTARG" ]; then
                title="$OPTARG"
            fi
            ;;
        j)
            jenkins="jenkins"
            ;;
        \?)
             echo "Invalid option: -$OPTARG">&2
             usage
             exit 1
             ;;
        :)
             echo "Option -$OPTARG requires an argument." >&2
             usage
             exit 1
             ;;
    esac
done

# Skip the options and move on to the positional parameters
shift $((OPTIND-1))


while [ "$1" ]; do
    if [ "$1" == "prod" ]; then
        production_build="production"
        seo="--seo"
        no_thumbnails=""
    elif [ "$1" == "debug" ]; then
        debug_build="debug"
    fi
    shift
done

if [ ! "$JSDUCK" ]; then
    if [ "$TI_ROOT" ]; then
        JSDUCK=${TI_ROOT}/jsduck
    else
        echo "No JSDuck dir \$JSDUCK and \$TI_ROOT not defined. Exiting."
        exit 1
    fi
fi

if [ ! "$DOCTOOLS" ]; then
    if [ "$TI_ROOT" ]; then
        DOCTOOLS=${TI_ROOT}/doctools
    else
        echo "No doctools dir \$DOCTOOLS and \$TI_ROOT not defined. Exiting."
        exit 1
    fi
fi

if [ ! "$ALLOY" ]; then
    if [ "$TI_ROOT" ]; then
        ALLOY=${TI_ROOT}/alloy
    else
        echo "No alloy dir \$ALLOY and \$TI_ROOT not defined. Exiting."
        exit 1
    fi
fi

if [ ! "$ARROW" ]; then
    if [ "$TI_ROOT" ]; then
        ARROW=${TI_ROOT}
    else
        echo "No arrow dir \$ARROW and \$TI_ROOT not defined. Exiting."
        exit 1
    fi
fi

if [ $include_alloy ]; then
	echo "**** alloy files will be parsed"
	echo "**** ${ALLOY}/..."
    alloyDirs="${ALLOY}/Alloy/lib
    		       ${ALLOY}/docs/apidoc
    		       ${DOCTOOLS}/add-ons
               $(find $ALLOY/Alloy/builtins -maxdepth 1 -type f ! -name moment.js)"
fi

if [ $include_arrow ]; then
	echo "**** arrow files will be parsed"
	echo "**** ${ARROW}/..."
    arrowDirs="${ARROW}/arrow-orm/apidoc
               ${ARROW}/arrow-orm/lib/connector/capabilities/index.js
               ${ARROW}/arrow-orm/lib/collection.js
               ${ARROW}/arrow-orm/lib/connector.js
               ${ARROW}/arrow-orm/lib/error.js
               ${ARROW}/arrow-orm/lib/instance.js
               ${ARROW}/arrow-orm/lib/model.js
               ${ARROW}/arrow/apidoc
               ${ARROW}/arrow/lib/engines
               ${ARROW}/arrow/lib/api.js
               ${ARROW}/arrow/lib/arrow.js
               ${ARROW}/arrow/lib/block.js
               ${ARROW}/arrow/lib/middleware.js
               ${ARROW}/arrow/lib/router.js"
fi

if [ $include_modules ]; then
	echo "**** module files will be parsed"
    if [ ! "$APPC_MODULES" ]; then
        if [ "$TI_ROOT" ]; then
            APPC_MODULES=${TI_ROOT}/appc_modules
            echo "**** ${TI_ROOT}/appc_modules/..."
        else
            echo "No appc_modules dir \$APPC_MODULES and \$TI_ROOT not defined. Exiting."
            exit 1
        fi
    fi
    module_dirs="$APPC_MODULES/ti.map/apidoc
    			       $APPC_MODULES/ti.facebook/apidoc
                 $APPC_MODULES/ti.nfc/apidoc
                 $APPC_MODULES/ti.coremotion/apidoc
                 $APPC_MODULES/ti.urlsession/apidoc
                 $APPC_MODULES/ti.touchid/apidoc
                 $APPC_MODULES/titanium-identity/apidoc
                 $APPC_MODULES/Ti.SafariDialog/apidoc
                 $APPC_MODULES/appcelerator.apm/apidoc
                 $APPC_MODULES/titanium-identity/apidoc
                 $APPC_MODULES/ti.playservices/apidoc"

    module_dirs+=" $APPC_MODULES/ti.geofence/apidoc
      		         $APPC_MODULES/appcelerator.https/apidoc
                   $APPC_MODULES/appcelerator.encrypteddatabase/apidoc
                   $APPC_MODULES/titanium-web-dialog/apidoc
                   $APPC_MODULES/ti.systemalert
                   $APPC_MODULES/appcelerator.aca"
fi
#$APPC_MODULES/com.appcelerator.apm/apidoc

if [ -d "$TI_ROOT/titanium_mobile_windows" ]; then
  pushd $TI_ROOT/titanium_mobile_windows
  npm install .
  pushd $TI_ROOT/titanium_mobile_windows/apidoc
  node ti_win_yaml
  ## Workaround
  rm Titanium/Map.yml
  rm -r Titanium/Map
  addon_win=" -a ${TI_ROOT}/titanium_mobile_windows/apidoc/WindowsOnly "
  addon_win+=" -a ${TI_ROOT}/titanium_mobile_windows/apidoc/Titanium "
  popd
  popd
fi

echo "starting npm run docgen -- -f jsduck $module_dirs $addon_win\n"
npm run docgen -- -f jsduck $module_dirs $addon_win

if [ $addon_guidesdir ]; then
    echo "starting $addon_guidesdir\n"
    echo "$addon_guidesdir routine is running."
    python ./guides_merger.py --input "${guidesdir}/toc.xml" --addon "${addon_guidesdir}/toc.xml"  --output "./build/merged_guides"
    if [ -a guides_merger.py ]; then
      echo "guides_merger.py found"
    else
      echo "NOT FOUND"
    fi
    python .guides_merger.py --Help

    ## Workaround for new Confluence plug-in
    #cp -r $guidesdir/attachments_* ./build/merged_guides/.
    #cp -r $guidesdir/images_* ./build/merged_guides/.

    ## Attachments
    cp -r $guidesdir/attachments_* ./build/merged_guides/.
    cp -r $addon_guidesdir/attachments_* ./build/merged_guides/.

    ## Images
    cp -r $guidesdir/images ./build/merged_guides/.
    cp -r $addon_guidesdir/images ./build/merged_guides/.

    guidesdir="./build/merged_guides"
    parseropts=""
else
    parseropts="--show_edit_button"
fi

echo "starting node guides_parser --input "${guidesdir}/toc.xml" --output "./build/guides" $parseropts\n"
node guides_parser --input "${guidesdir}/toc.xml" --output "./build/guides" $parseropts

# Assume video list is pre-processed, with real thumbnails
cp $VIDEO_LIST $PROCESSED_VIDEO_LIST
# After updating video list, add thumbnails manually using the video_thumbs command:
#    python ./video_thumbs.py --input $VIDEO_LIST --output $PROCESSED_VIDEO_LIST

if [ $production_build ] ; then
    echo "starting $production_build\n"
    (cd ${JSDUCK}; rake compress)
    TEMPLATE=${JSDUCK}/${PROD_TEMPLATE}


    ## Generate Solr content
    echo "Generating Solr content for indexing..."
    npm run docgen -- -f solr $module_dirs $addon_win
    mkdir -p $outdir/../data/solr
    cp ./build/api_solr.json $outdir/../data/solr/.
    if [ $include_alloy ]; then
        echo "Generating Solr content for Alloy..."
        bash $DOCTOOLS/jsduck2json.sh alloy solr
        cp ./dist/solr.json $outdir/../data/solr/alloy_api.json
    fi
    if [ $include_arrow ]; then
        echo "Generating Solr content for Arrow..."/
        bash $DOCTOOLS/jsduck2json.sh arrow solr
        cp ./dist/solr.json $outdir/../data/solr/arrow_api.json
    fi
else
    compass compile ${JSDUCK}/template/resources/sass
    TEMPLATE=${JSDUCK}/${DEBUG_TEMPLATE}
fi

echo "starting ruby ${JSDUCK}/bin/jsduck --template ${TEMPLATE} $seo --output $outdir --title "$title" --config $config $alloyDirs $arrowDirs\n"
ruby ${JSDUCK}/bin/jsduck --template ${TEMPLATE} $seo --output $outdir --title "$title" --config $config $alloyDirs $arrowDirs

# TIDOC-1327 Fix server errors
cp -r "$guidesdir/images/icons" "$outdir/resources/images/."

## Copy resources
## Workaround for new Confluence plugin
cp -r $guidesdir/attachments_* $outdir/.
#cp -r $guidesdir/images_* $outdir/.

cp -r $guidesdir/css/common.css "$outdir/resources/css/common.css"
cp -r $guidesdir/images "$outdir/images"
#cp -r $guidesdir/attachments "$outdir/attachments"

cp ./resources/mock_video.png $outdir/resources/images/mock_video.png
cp ./resources/codestrong_logo_short.png $outdir/resources/images/codestrong_logo_short.png

# Copy API images folder to $outdir
cp -r node_modules/titanium-docgen/images $outdir/.
