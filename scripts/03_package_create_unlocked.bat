REM *****************************
REM        PACKAGE CREATION   
REM *****************************

REM Package Create Config
SET devHub=devHubAlias
SET packageName=Lightweight - SOAP Util (Unlocked)
SET packageDescription=A lightweight utility to call the synchronous methods of the SOAP APIs for any Org using the WSDLs. Included are the Metadata, Partner and Apex API.
SET packageType=Unlocked
SET packagePath=force-app/package

REM Package Config
SET packageId=0HoP300000000o1KAA
SET packageVersionId=04tP3000001HJAXIA4

REM Create package
sf package create --name "%packageName%" --description "%packageDescription%" --package-type "%packageType%" --path "%packagePath%" --target-dev-hub %devHub%

REM Create package version
sf package version create --package "%packageName%"  --target-dev-hub %devHub% --code-coverage --installation-key-bypass --wait 30

REM Delete package
sf package:delete -p %packageId% --target-dev-hub %devHub% --no-prompt

REM Delete package version
sf package:version:delete -p %packageVersionId% --target-dev-hub %devHub% --no-prompt

REM Promote package version
sf package:version:promote -p %packageVersionId% --target-dev-hub %devHub% --no-prompt

rem Install the package for testing
sf package install -p %packageVersionId% -w 30