@echo off
set /p iday=Enter Day Of Month (01-31):
set /p imonth=Enter Month (01-12):
@echo C000003 = CLIA > ~JSSCheck%iday%.txt
@echo C000004 = IAP2 >> ~JSSCheck%iday%.txt
@echo C000005 = IES >> ~JSSCheck%iday%.txt
@echo C000006 = AICVIC >> ~JSSCheck%iday%.txt
@echo C000009 = AICNSW >> ~JSSCheck%iday%.txt
@echo C000010 = TEL >> ~JSSCheck%iday%.txt
@echo C000011 = QBS Test (not a client) >> ~JSSCheck%iday%.txt
@echo C000012 = AAMT >> ~JSSCheck%iday%.txt
@echo C000013 = AUD >> ~JSSCheck%iday%.txt
@echo C000014 = AID >> ~JSSCheck%iday%.txt
@echo C000016 = SAP (Implementation) >> ~JSSCheck%iday%.txt
@echo C000017 = ADE (Implementation) >> ~JSSCheck%iday%.txt
@echo C000018 = PPA (Implementation) >> ~JSSCheck%iday%.txt
@echo C000019 = MAV >> ~JSSCheck%iday%.txt
@echo C000020 = ACP (Implementation) >> ~JSSCheck%iday%.txt
@echo C000022 = ASM (Implementation) >> ~JSSCheck%iday%.txt
@echo T000007 = QJA >> ~JSSCheck%iday%.txt
@echo Look for tenants C 3/4/5/6/9/10/12/13/14/19 and T 7 >> ~JSSCheck%iday%.txt
@echo --------------------------------------------------- >> ~JSSCheck%iday%.txt
forfiles  /m C*JSSLog*%iday%*%imonth%* /d +0 >> ~JSSCheck%iday%.txt
forfiles  /m T*JSSLog*%iday%*%imonth%* /d +0 >> ~JSSCheck%iday%.txt
echo File generated ~JSSCheck%iday%.txt
pause

