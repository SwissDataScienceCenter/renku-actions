#!/bin/sh
set -e

YAML_FILES_LOC=${YAML_FILES_LOC:-".github/workflows"}
YAML_FILES=$(find $YAML_FILES_LOC -name '*.yaml' -o -name '*.yml')

if test -z "$NEW_VERSION" ; then
    echo 'Please set the new version that should be applied, as "vX.X.X"'
    exit 1
fi

if test -z "$YAML_FILES" ; then
    echo "Found no .yaml or .yml files to update."
fi

for FILE in $YAML_FILES
do
    OLD_ACTIONS=$(yq eval '.jobs.*.steps.[] | select(.uses == "SwissDataScienceCenter/renku-actions*") | .uses' $FILE)
    
    if test -z "$OLD_ACTIONS" ; then
        echo "Found no renku actions in $FILE."
    fi

    for OLD_ACTION in $OLD_ACTIONS
    do
        NEW_ACTION=$(echo $OLD_ACTION | sed -e "s/v[0-9]*\.[0-9]*\.[0-9]*$/$NEW_VERSION/")
        if [ ! "$OLD_ACTION" = "$NEW_ACTION" ]; then
            echo "Updating $FILE: $OLD_ACTION --> $NEW_ACTION"
            sed -i "s|$OLD_ACTION|$NEW_ACTION|g" $FILE
        else
            echo "No need to update $OLD_ACTION in $FILE"
        fi
    done
done