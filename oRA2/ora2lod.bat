@echo off

cd ..
rmdir /s /q oRA2_Participant
rmdir /s /q oRA2_Leader
rmdir /s /q oRA2_Optional

cd oRA2

move Participant ..\oRA2_Participant
move Leader ..\oRA2_Leader
move Optional ..\oRA2_Optional

del /q modules.xml

