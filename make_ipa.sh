if [ $# -eq 0 ]
  then
    echo "need version number"
    exit 0
fi

mkdir Payload
cp -r "./build/ios/iphoneos/Runner.app" Payload
zip -r StreamingRadio.zip Payload
mv StreamingRadio.zip StreamingRadio-$1.ipa
rm -rf Payload 
