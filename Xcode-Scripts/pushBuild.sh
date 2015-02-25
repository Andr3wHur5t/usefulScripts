WORKSPACE="Blockparty.xcworkspace/"
NOW_DATE=$(date +'%m-%d-%y %Ih %Mm')
SCHEME="Blockparty"
EXPORT_PATH=~/iOS-IPAs/${SCHEME}/${NOW_DATE}/
EXPORT_FILE_PATH=${EXPORT_PATH}${SCHEME}
PROVISIONING_PROFILE=""

echo "Phone Number For Updates:"
read PHONE_NUMBER

echo "Release Notes:"
read RELEASE_NOTES
#RELEASE_NOTES="First Dev Build."

TESTFLIGHT_API=""
TESTFLIGHT_TEAM=""

echo ${NOW_DATE}
# Make sure we have the directory
mkdir -p "${EXPORT_PATH}"

# Generate Archive
xctool -workspace "${WORKSPACE}" -scheme "${SCHEME}" clean
xctool -workspace "${WORKSPACE}" -scheme "${SCHEME}" -configuration release archive -archivePath "${EXPORT_FILE_PATH}"

# Upload DSYM(s)
# You should upload your dsyms here

# Create IPA
echo "Creating IPA at '${EXPORT_PATH}'"
xcodebuild -exportArchive -archivePath "${EXPORT_FILE_PATH}.xcarchive" -exportPath "${EXPORT_FILE_PATH}" -exportFormat ipa -exportProvisioningProfile "${PROVISIONING_PROFILE}"

#Send Message
if [ "$PHONE_NUMBER" ]; then
curl http://textbelt.com/text --silent -d number=${PHONE_NUMBER} -d message="IPA Generated for ${SCHEME}, uploading to testfilight now."
echo ""
echo "Sent message to $PHONE_NUMBER"
fi

# Upload To TestFlight
echo "Uploading to testflight"
curl "http://testflightapp.com/api/builds.json" -F file="@${EXPORT_FILE_PATH}.ipa" -F api_token="${TESTFLIGHT_API}" -F team_token="${TESTFLIGHT_TEAM}" -F notes="${RELEASE_NOTES}"
echo ""
echo "Uploaded ipa to testflight."

#Send Message
if [ "$PHONE_NUMBER" ]; then
curl http://textbelt.com/text --silent -d number=${PHONE_NUMBER} -d message="Finished uploading ${SCHEME} to testflight."
echo ""
echo "Sent message to $PHONE_NUMBER"
fi
