#/bin/bash

cd ..
rm -rf oRA2_Participant
rm -rf oRA2_Leader
rm -rf oRA2_Optional

cd oRA2

mv Participant ../oRA2_Participant
mv Leader ../oRA2_Leader
mv Optional ../oRA2_Optional

rm -rf modules.xml

