#!/bin/sh
set -eu
YES_VAL="yes"
PUSH_TO_BRANCH="$INPUT_PUSH_TO_BRANCH"
BEFORE_CMD="$INPUT_BEFORE_CMD"
AFTER_CMD="$INPUT_AFTER_CMD"
AUTO_PUSH="$INPUT_AUTO_PUSH"
OUTPUT_FOLDER="$INPUT_OUTPUT_FOLDER"
SOURCE_FOLDER="$INPUT_SOURCE_FOLDER"

echo "
"

if [[ -z "$GITHUB_TOKEN" ]]; then
  echo "🚩 Set the GITHUB_TOKEN env variable"
  exit 1
fi

if [[ -z "$PUSH_TO_BRANCH" ]]; then
  echo "🚩 Set the PUSH_TO_BRANCH Variable"
  exit 1
fi

if [ -z "$SOURCE_FOLDER" ]; then
  SOURCE_FOLDER=""
fi

FULL_SOURCE_FOLDER="$GITHUB_WORKSPACE/$SOURCE_FOLDER"
COMPOSER_LOG_FILE="composer_installer_log.txt"
#echo "
#👽   Global Variable
#✏️   PUSH_TO_BRANCH : $PUSH_TO_BRANCH
#✏️   BEFORE_CMD : $BEFORE_CMD
#✏️   AFTER_CMD : $AFTER_CMD
#✏️   AUTO_PUSH : $AUTO_PUSH
#✏️   OUTPUT_FOLDER : $OUTPUT_FOLDER
#✏️   SOURCE_FOLDER : $SOURCE_FOLDER
#"

# Custom Command Option
if [[ ! -z "$BEFORE_CMD" ]]; then
  echo "⚡️ Running BEFORE_CMD"
  eval "$BEFORE_CMD"
fi

cd ../
echo " "
echo "------------------------------------"
echo "🏗 Doing Groud Work"
mkdir apigen
mkdir apigen_ouput
cd apigen
echo "✨ Installing Composer"
curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer >> /dev/null 2>&1
echo "✨ Installing ApiGen"
echo '{ "require" : { "apigen/apigen" : "4.1.2" } }' >>composer.json
composer update >> $COMPOSER_LOG_FILE
chmod +x ./vendor/bin/apigen

echo "----------------------"
echo "📈 ApiGen Install Log"
echo "//////////////////////////////"
cat $COMPOSER_LOG_FILE
rm -rf $COMPOSER_LOG_FILE
echo "//////////////////////////////"

echo " "
echo "------------------------------------"
echo "🚀 Running ApiGen"
echo "--- 📈 Source Folder : $FULL_SOURCE_FOLDER"
echo "------------------------------------"
echo " "

./vendor/bin/apigen generate -s $FULL_SOURCE_FOLDER --destination ../apigen_ouput

cd $GITHUB_WORKSPACE
# Custom Command Option
if [[ ! -z "$AFTER_CMD" ]]; then
  echo "⚡️Running AFTER_CMD"
  echo " "
  eval "$AFTER_CMD"
fi

echo "✅ Validating Output"
echo " "

cd ../apigen_ouput/ && ls -la

echo " "
echo " "

if [ "$AUTO_PUSH" == "$YES_VAL" ]; then
  echo "🚚 Pushing To Github"
  echo " "
  git config --global user.email "githubactionbot+apigen@gmail.com" && git config --global user.name "ApiGen Github Bot"
  cd ../
  git clone -b $PUSH_TO_BRANCH https://x-access-token:$GITHUB_TOKEN@github.com/$GITHUB_REPOSITORY liverepo
  cp -r apigen_ouput/* liverepo/
  cd liverepo/
  git add .
  git commit -m "#$GITHUB_RUN_NUMBER 📖 ApiGen Code Docs Regenerated | ⚡️Trigged By $GITHUB_SHA"
  git push origin $PUSH_TO_BRANCH

  #git init
  #git remote add origin "https://x-access-token:$GITHUB_TOKEN@github.com/$GITHUB_REPOSITORY"
  #git add .
  #git commit -m "📖 ApiGen Code Docs Regenerated"
  #git push origin "master:${PUSH_TO_BRANCH}" -f
else
  cd $GITHUB_WORKSPACE
  cp -r ../apigen_ouput/* $OUTPUT_FOLDER
  cd $OUTPUT_FOLDER
  ls -lah
  rm -rf ../apigen_ouput
fi
