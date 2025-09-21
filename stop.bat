@echo off
wmic process where "commandline like '%%simple_ui.ahk%%'" delete
