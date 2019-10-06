*** Settings ***
Library           String
Library           DateTime
Library           smarttender_service.py
Library           op_robot_tests.tests_files.service_keywords
Library           Selenium2Library

*** Variables ***
${number_of_tabs}     ${1}
${locator.auctionID}    jquery=span.info_tendernum
${locator.procuringEntity.name}       jquery=span.info_organization
${locator.tenderPeriod.startDate}    jquery=span.info_d_sch
${locator.tenderPeriod.endDate}    jquery=span.info_d_srok
${locator.enquiryPeriod.endDate}    jquery=span.info_ddm
${locator.auctionPeriod.startDate}      jquery=span.info_dtauction
${locator.questions[0].description}    ${EMPTY}
${locator.questions[0].answer}    ${EMPTY}
${browserAlias}  'our_browser'

*** Keywords ***
####################################
#              COMMON              #
####################################
open button
	[Documentation]   відкривае лінку з локатора у поточному вікні
	[Arguments]  ${selector}
	${href}=  Get Element Attribute  ${selector}@href
	Go To  ${href}
	loading дочекатись закінчення загрузки сторінки

loading дочекатись закінчення загрузки сторінки
    [Arguments]  ${time_to_wait}=120
    #  setup
    ${loadings}  set variable  //div[@class='smt-load']|//*[@class='loading_container']//*[@class='sk-circle']|//*[contains(@class,'skeleton-wrapper')]|//*[@class='ivu-spin']|//div[contains(@style, "loading")]|//div[@class="ivu-loading-bar"]|//*[contains(@class,'disabled-block')]|//*[@class="loading-bar"]|//*[@id="svgLogo"]|//*[contains(@id, 'LoadingPanel')]|//div[contains(@class,'loading-panel')]|//*[@id="adorner"]|//img[contains(@class, "loadingImage")]|//*[@id="adorner"]
	#
	${status}  run keyword and return status  loading дочекатися відображення елемента на сторінці  ${loadings}  1
	return from keyword if  ${status} == ${False}  ${None}
	loading дочекатися зникнення елемента зі сторінки  ${loadings}  ${time_to_wait}
	${is visible}  Run Keyword And Return Status  loading дочекатися відображення елемента на сторінці  ${loadings}  0.5
	Run Keyword If  ${is visible}
		...  loading дочекатись закінчення загрузки сторінки


loading дочекатися відображення елемента на сторінці
	[Documentation]  timeout=...s/...m
	[Arguments]  ${locator}  ${timeout}=10s
	Set Selenium Implicit Wait  .1
	Log  Element Should Be Visible "${locator}" after ${timeout}
	Register Keyword To Run On Failure  No Operation
	Run Keyword And Continue On Failure  Wait Until Keyword Succeeds  ${timeout}  .5  Element Should Be Visible  ${locator}
	Register Keyword To Run On Failure  Capture Page Screenshot
	[Teardown]  Run Keyword If  "${KEYWORD STATUS}" == "FAIL"
			...  run keywords
				...  Element Should Be Visible  ${locator}  Oops!${\n}Element "${locator}" is not visible after ${timeout} (s/m).  AND
				...  Set Selenium Implicit Wait  5


loading дочекатися зникнення елемента зі сторінки
	[Documentation]  timeout=...s/...m
	[Arguments]  ${locator}  ${timeout}=10s
	Set Selenium Implicit Wait  .1
	Log  Element Should Not Be Visible "${locator}" after ${timeout}
	Register Keyword To Run On Failure  No Operation
	Run Keyword And Continue On Failure  Wait Until Keyword Succeeds  ${timeout}  .5  Element Should Not Be Visible  ${locator}
	Register Keyword To Run On Failure  Capture Page Screenshot
	[Teardown]  Run Keyword If  "${KEYWORD STATUS}" == "FAIL"
			...  run keywords
				...  Element Should Not Be Visible  ${locator}  Oops!${\n}Element "${locator}" is visible after ${timeout} (s/m).  AND
				...  Set Selenium Implicit Wait  5


Підготувати клієнт для користувача
    [Arguments]    @{ARGUMENTS}
    [Documentation]      Відкрити браузер, створити об’єкт api wrapper, тощо
    ...    ${ARGUMENTS[0]} == username
    Open Browser    ${USERS.users['${ARGUMENTS[0]}'].homepage}    ${USERS.users['${ARGUMENTS[0]}'].browser}  alias=${browserAlias}
#    Set Window Size    @{USERS.users['${ARGUMENTS[0]}'].size}
    Maximize Browser Window
#    Set Window Position    @{USERS.users['${ARGUMENTS[0]}'].position}
    Login      @{ARGUMENTS}

Login
    [Arguments]     @{ARGUMENTS}
    return from keyword if  '${ARGUMENTS[0]}' == 'SmartTender_Viewer'
    go to  http://test.smarttender.biz/
    loading дочекатись закінчення загрузки сторінки
    Click Element    //*[@data-qa="title-btn-modal-login"]
    loading дочекатися відображення елемента на сторінці  //*[@data-qa="title-modal-login"]
    Input Text    //*[@name="login"]    ${USERS.users['${ARGUMENTS[0]}'].login}
    Input Text    //*[@name="password"]    ${USERS.users['${ARGUMENTS[0]}'].password}
    Click Element    //*[@data-qa="form-login-success"]
    loading дочекатись закінчення загрузки сторінки

Перезапустити браузер
    [Arguments]    @{ARGUMENTS}
    Run Keyword    reset_number_of_tabs
    Close All Browsers
    smarttender.Підготувати клієнт для користувача     @{ARGUMENTS}
    [Return]

Оновити сторінку з тендером
    [Arguments]    @{ARGUMENTS}
    [Documentation]    ${ARGUMENTS[0]} = username
    ...    ${ARGUMENTS[1]} = ${TENDER_UAID}
    Switch Browser    ${browserAlias}
    log  Ждемс синхронизацию на тесте  WARN
    Wait Until Keyword Succeeds  10m  5s  smarttender.Дочекатись синхронізації
    Reload Page
    loading дочекатись закінчення загрузки сторінки
#    smarttender.Пошук тендера по ідентифікатору    ${ARGUMENTS[0]}    ${ARGUMENTS[1]}

Підготуватися до редагування
    [Arguments]     ${USER}     ${TENDER_ID}
    Go To    https://test.smarttender.biz/webclient/?testmode=1&proj=it_uk
    loading дочекатись закінчення загрузки сторінки
    loading дочекатися відображення елемента на сторінці  //*[@title="Аукціони ФГВ(Тестові)"]
    Click Element    //*[@title="Аукціони ФГВ(Тестові)"]
    loading дочекатись закінчення загрузки сторінки
    loading дочекатись закінчення загрузки сторінки
    loading дочекатись закінчення загрузки сторінки
    Wait Until Page Contains        Тестові аукціони на продаж  30
    Focus    jquery=div[data-placeid='TENDER'] table.hdr tr:eq(2) td:eq(3) input:eq(0)
    sleep   1s
    Input Text      jquery=div[data-placeid='TENDER'] table.hdr tr:eq(2) td:eq(3) input:eq(0)    ${TENDER_ID}
    sleep   1s
    Press Key       jquery=div[data-placeid='TENDER'] table.hdr tr:eq(2) td:eq(3) input:eq(0)        \\13
	loading дочекатись закінчення загрузки сторінки

Пошук тендера по ідентифікатору
    [Arguments]    @{ARGUMENTS}
    [Documentation]    ${ARGUMENTS[0]} == username
    ...    ${ARGUMENTS[1]} == ${TENDER_UAID}
    Go To    https://test.smarttender.biz/auktsiony-na-prodazh-aktyviv-bankiv
    loading дочекатись закінчення загрузки сторінки
	input text  //*[@data-qa="search-block-input"]//input  ${ARGUMENTS[1]}
	click element  //*[@data-qa="search-block-input"]//button
	loading дочекатись закінчення загрузки сторінки
    Location Should Contain    ${ARGUMENTS[1]}
    Capture Page Screenshot
    click element  //*[@data-qa="tender-0"]//a[@class]
    loading дочекатись закінчення загрузки сторінки
    ${auction_href}  Get location
    log  ${auction_href}  warn

Focus And Input
    [Arguments]    ${selector}    ${value}    ${method}=SetText
    Click Element At Coordinates     jquery=${selector}    10    5
    sleep     1s
    ${value}=       Convert To String     ${value}
    Input text      jquery=${selector}    ${value}
    sleep     3s

Input Ade
    [Arguments]     ${selector}     ${value}
    Click Element At Coordinates     jquery=${selector}    10    5
    sleep     1s
    Input Text    jquery=${selector}    ${value}
    Sleep    1s
    Press Key     jquery=${selector}       \\09
    Sleep    1s


Отримати текст із поля і показати на сторінці
    [Arguments]    ${fieldname}
    sleep    2s
    ${return_value}=    Get Text    ${locator.${fieldname}}
    [Return]    ${return_value}

Заповнити випадаючий список
    [Arguments]    ${selector}    ${content}
    Focus    ${selector}
    Execute JavaScript    (function(){$("${selector}").val('');})()
    sleep    3s
    Input Text    ${selector}    ${content}
    sleep    3s
    Press Key    ${selector}    \\13
    sleep    2s

####################################
#          OPEN PROCEDURE          #
####################################

Підготувати дані для оголошення тендера
    [Arguments]   ${username}    ${tender_data}    ${param3}
    ${tender_data}=       adapt_data       ${tender_data}
    Log    ${tender_data}
    [Return]    ${tender_data}

Створити тендер
    [Arguments]    @{ARGUMENTS}
    ${tender_data}=    Set Variable    ${ARGUMENTS[1]}
    ${items}=    Get From Dictionary    ${tender_data.data}    items
    ${procuringEntity_legalName}=    Get From Dictionary     ${tender_data.data.procuringEntity.identifier}    legalName
    ${title}=    Get From Dictionary    ${tender_data.data}    title
    ${description}=    Get From Dictionary    ${tender_data.data}    description
    ${budget}=    Get From Dictionary    ${tender_data.data.value}    amount
    ${step_rate}=    Get From Dictionary    ${tender_data.data.minimalStep}    amount
    ${valTax}=     Get From Dictionary    ${tender_data.data.value}      valueAddedTaxIncluded
    ${latitude}    Get From Dictionary    ${items[0].deliveryLocation}    latitude
    ${longitude}    Get From Dictionary    ${items[0].deliveryLocation}    longitude
    ${postalCode}    Get From Dictionary    ${items[0].deliveryAddress}    postalCode
    ${locality}=    Get From Dictionary    ${items[0].deliveryAddress}    locality
    ${streetAddress}    Get From Dictionary    ${items[0].deliveryAddress}    streetAddress
    ${auction_start}=    Get From Dictionary    ${tender_data.data.auctionPeriod}    startDate
    ${auction_start}=    smarttender_service.convert_datetime_to_smarttender_format    ${auction_start}
    ${guarantee_amount}=    Get From Dictionary    ${tender_data.data.guarantee}    amount
    ${dgfID}=    Get From Dictionary     ${tender_data.data}        dgfID
    ${dgfDecisionId}=    Get From Dictionary    ${tender_data.data}    dgfDecisionID
    ${dgfDecisionDate}=    Get From Dictionary    ${tender_data.data}    dgfDecisionDate
    ${dgfDecisionDate}=    smarttender_service.convert_datetime_to_smarttender_format    ${dgfDecisionDate}
    ${tenderAttempts}=    Get From Dictionary    ${tender_data.data}    tenderAttempts
    Wait Until Page Contains    Робочий стіл    30
    Click Element    jquery=.listviewDataItem[data-itemkey='434']
    loading дочекатись закінчення загрузки сторінки
    Wait Until Page Contains        Тестові аукціони на продаж
    Click Image    jquery=.dxrControl_DevEx a[title*='(F7)'] img:eq(0)
    Wait Until Element Contains    cpModalMode    Оголошення   30
    Run Keyword If     '${mode}' == 'dgfOtherAssets'    Змінити процедуру
    Focus And Input     \#cpModalMode table[data-name='DTAUCTION'] input    ${auction_start}    SetTextInternal
    Focus And Input     \#cpModalMode table[data-name='INITAMOUNT'] input      ${budget}
    Run Keyword If        ${valTax}     Click Element     jquery=table[data-name='WITHVAT'] span:eq(0)
    Focus And Input     \#cpModalMode table[data-name='MINSTEP'] input     ${step_rate}
    Focus And Input     \#cpModalMode table[data-name='TITLE'] input     ${title}
    Focus And Input     \#cpModalMode table[data-name='DESCRIPT'] textarea     ${description}
    Focus And Input     \#cpModalMode table[data-name='DGFID'] input:eq(0)    ${dgfID}
    # ввод procuringEntityId
    ${legalName_input}  set variable  //div[@data-name='ORG_GPO_2']//input[not(contains(@type,'hidden'))]
    click element  ${legalName_input}
    loading дочекатися відображення елемента на сторінці  ${legalName_input}/ancestor::tr/td[@title="Вибір з довідника (F10)"]
    Click Element  ${legalName_input}/ancestor::tr/td[@title="Вибір з довідника (F10)"]
    loading дочекатись закінчення загрузки сторінки
    ${org_search_input}  set variable  //*[@data-name="ORG"]//input[not(contains(@type,'hidden'))]
    input text  ${org_search_input}  ${procuringEntity_legalName}
    press key  ${org_search_input}  \\13
    click element  //*[@data-name="OkButton"][contains(@id,"ORGSRCH")]
    Підтвердити вибір(F10)
	# ввод tenderAttempts
	click element  //*[@data-name='ATTEMPT']
	loading дочекатися відображення елемента на сторінці  //*[@class="dxpcDropDown_DevEx dxpclW dxpc-ddSys" and not(contains(@style, "display:none"))]
	click element  //*[@class="dxpcDropDown_DevEx dxpclW dxpc-ddSys" and not(contains(@style, "display:none"))]//*[text()="${tenderAttempts}"]
	loading дочекатися зникнення елемента зі сторінки  //*[@class="dxpcDropDown_DevEx dxpclW dxpc-ddSys" and not(contains(@style, "display:none"))]
	# ввод dgfDecisionId и dgfDecisionDate
	input text  //*[@data-name="DGFDECISION_NUMBER"]//input[@type="text"]  ${dgfDecisionId}
    Focus And Input     \#cpModalMode table[data-name='DGFDECISION_DATE'] input    ${dgfDecisionDate}

    ${index}=    Set Variable    ${0}
    :FOR    ${item}    in    @{items}
    \    Run Keyword If    '${index}' != '0'    Створити новий предмет
    \    smarttender.Додати предмет в тендер при створенні   ${item}
    \    ${index}=    SetVariable    ${index + 1}

    Focus And Input     \#cpModalMode table[data-name='POSTALCODE'] input     ${postalCode}
    Focus And Input     \#cpModalMode table[data-name='STREETADDR'] input     ${streetAddress}
    Click Element     jquery=#cpModalMode div[data-name='CITY_KOD'] input[type=text]:eq(0)
    sleep    3s
    Input Text     jquery=#cpModalMode div[data-name='CITY_KOD'] input[type=text]:eq(0)        ${locality}
    sleep    2s
    Press Key        jquery=#cpModalMode div[data-name='CITY_KOD'] input[type=text]:eq(0)         \\13
    sleep    3s
    Press Key        jquery=#cpModalMode div[data-name='CITY_KOD'] input[type=text]:eq(0)         \\13
    sleep  2s
    Focus And Input      \#cpModalMode table[data-name='LATITUDE'] input     ${latitude}
    Focus And Input      \#cpModalMode table[data-name='LONGITUDE'] input     ${longitude}

    Click Element     jquery=#cpModalMode li.dxtc-tab:contains('Гарантійний внесок')
    Wait Until Element Is Visible    jquery=[data-name='GUARANTEE_AMOUNT']
    Focus And Input     \#cpModalMode table[data-name='GUARANTEE_AMOUNT'] input     ${guarantee_amount}
    sleep    3s
    Click Image     jquery=#cpModalMode div.dxrControl_DevEx a:contains('Додати') img
    sleep    20s
    Click Image     jquery=#MainSted2Splitter .dxrControl_DevEx a[title='Надіслати вперед (Alt+Right)'] img:eq(0)
    Wait Until Page Contains    Оголосити аукціон?
    Click Element    jquery=#IMMessageBox_PW-1 #IMMessageBoxBtnYes_CD
    Wait Until Element Is Not Visible    jquery=#LoadingPanel
    sleep    20s
    ${return_value}     Get Text     jquery=div[data-placeid='TENDER'] td:Contains('UA-'):eq(0)
    [Return]     ${return_value}

Створити новий предмет
    Click Element    jquery=#cpModalMode div.gridViewAndStatusContainer a[title='Додати']
    sleep    1s

Змінити процедуру
    Click Element    jquery=table[data-name='KDM2']
    sleep   3s
    Click Element    jquery=div#CustomDropDownContainer div.dxpcDropDown_DevEx table:eq(2) tr:eq(1) td:eq(0)

Завантажити документ
    [Arguments]    @{ARGUMENTS}
    Підготуватися до редагування      ${ARGUMENTS[0]}     ${ARGUMENTS[2]}
    Click Element     jquery=.dxrControl_DevEx a[title*='(F4)'] img:eq(0)
    Wait Until Page Contains      Завантаження документації    20
    Додати документ за шляхом    ${ARGUMENTS[1]}
    [Teardown]    Закрити вікно редагування

Додати документ
    [Arguments]     ${document}
    Log    ${document[0]}
    Click Element     jquery=#cpModalMode li.dxtc-tab:contains('Завантаження документації')
    sleep   2s
    Click Element     jquery=#cpModalMode .dxtlControl_DevEx label:eq(0)
    sleep   2s
    Click Element     jquery=#cpModalMode div[data-name='BTADDATTACHMENT']
    sleep   2s
    Choose File      jquery=#cpModalMode input[type=file]:eq(1)    ${document[0]}
    sleep    2s
    Click Image      jquery=#cpModalMode div.dxrControl_DevEx a:contains('ОК') img
    sleep    2s

Додати документ за шляхом
    [Arguments]     ${document}
    Log    ${document}
    Click Element     jquery=#cpModalMode li.dxtc-tab:contains('Завантаження документації')
    sleep   2s
    Click Element     jquery=#cpModalMode .dxtlControl_DevEx label:eq(0)
    sleep   2s
    Click Element     jquery=#cpModalMode div[data-name='BTADDATTACHMENT']
    sleep   2s
    Choose File      jquery=#cpModalMode input[type=file]:eq(1)    ${document}
    sleep    2s
    Click Image      jquery=#cpModalMode div.dxrControl_DevEx a:contains('ОК') img
    sleep    2s

Додати предмет в тендер при створенні
    [Arguments]    @{ARGUMENTS}
    [Documentation]    ${ARGUMENTS[0]} == item
    ${description}=    Get From Dictionary    ${ARGUMENTS[0]}     description
    ${quantity}=       Get From Dictionary    ${ARGUMENTS[0]}     quantity
    ${cpv}=            Get From Dictionary    ${ARGUMENTS[0].classification}     id
    ${unit}=           Get From Dictionary    ${ARGUMENTS[0].unit}     name
    Input Ade    \#cpModalMode div[data-name='KMAT'] input[type=text]:eq(0)      ${description}
    sleep   2s
    Focus And Input      \#cpModalMode table[data-name='QUANTITY'] input      ${quantity}
    sleep   2s
    Input Ade      \#cpModalMode div[data-name='EDI'] input[type=text]:eq(0)       ${unit}
    sleep   2s
    input text  //div[@data-name="MAINCLASSIFICATION"]//input[@type="text"]    ${cpv}
    press key  //div[@data-name="MAINCLASSIFICATION"]//input[@type="text"]  \\13
    sleep    2s

Додати предмет закупівлі
    [Arguments]    ${user}    ${tenderId}    ${item}
    ${description}=    Get From Dictionary    ${item}     description
    ${quantity}=       Get From Dictionary    ${item}     quantity
    ${cpv}=            Get From Dictionary    ${item.classification}     id
    ${unit}=           Get From Dictionary    ${item.unit}     name
    ${unit}=           smarttender_service.convert_unit_to_smarttender_format    ${unit}
    smarttender.Підготуватися до редагування     ${user}    ${tenderId}
    Click Image     jquery=.dxrControl_DevEx a[title*='(F4)'] img:eq(0)
    Wait Until Element Contains      jquery=#cpModalMode     Коригування    20
    Page Should Not Contain Element    jquery=#cpModalMode div.gridViewAndStatusContainer a[title='Додати']
    [Teardown]      Закрити вікно редагування

Видалити предмет закупівлі
    [Arguments]    ${user}    ${tenderId}    ${itemId}
    ${readyToEdit} =  Execute JavaScript  return(function(){return ((window.location.href).indexOf('webclient') !== -1).toString();})()
    Run Keyword If     '${readyToEdit}' != 'true'    Підготуватися до редагування     ${user}    ${tenderId}
    Click Image     jquery=.dxrControl_DevEx a[title*='(F4)'] img:eq(0)
    Wait Until Element Contains      jquery=#cpModalMode     Коригування    20
    Page Should Not Contain Element     jquery=#cpModalMode a[title='Удалить']
    [Teardown]      Закрити вікно редагування

Внести зміни в тендер
    [Arguments]    @{ARGUMENTS}
    Pass Execution If    '${role}'=='provider' or '${role}'=='viewer'    Данний користувач не може вносити зміни в аукціон
    smarttender.Підготуватися до редагування     ${ARGUMENTS[0]}     ${ARGUMENTS[1]}
    Click Image     jquery=.dxrControl_DevEx a[title*='(F4)'] img:eq(0)
    Wait Until Element Contains      jquery=#cpModalMode     Коригування    20
    sleep   1s
    ${selector}=    auction_screen_field_selector       ${ARGUMENTS[2]}
    Focus    jquery=${selector}
    Input Text    jquery=${selector}    ${ARGUMENTS[3]}
    sleep   1s
    [Teardown]    Закрити вікно редагування

Закрити вікно редагування
    Click Element       jquery=div.dxpnlControl_DevEx a[title='Зберегти'] img
    Run Keyword And Ignore Error      Закрити вікно з помилкою
    sleep    2s

Закрити вікно з помилкою
    Wait Until Page Contains    PROZORRO
    Click Element    jquery=#IMMessageBoxBtnOK:eq(0)
    [Return]

Змінити опис тендера
    [Arguments]       ${description}
    Focus       jquery=table[data-name='DESCRIPT'] textarea
    sleep    2s
    Input Text       jquery=table[data-name='DESCRIPT'] textarea      ${description}

Отримати інформацію із тендера
    [Arguments]    @{ARGUMENTS}
    [Documentation]    ${ARGUMENTS[0]} == username
    ...    ${ARGUMENTS[2]} == fieldname
    run keyword if  "${ARGUMENTS[2]}" == "status"
        ...  run keywords
                ...  reload page  AND
                ...  loading дочекатись закінчення загрузки сторінки
    ${selector}=     auction_field_info    ${ARGUMENTS[2]}
    ${ret}=  get text  xpath=${selector}
    ${ret}=             convert_result        ${ARGUMENTS[2]}       ${ret}
    [Return]     ${ret}

Отримати інформацію із предмету
    [Arguments]    @{ARGUMENTS}
    [Documentation]    ${ARGUMENTS[0]} == username
    ...    ${ARGUMENTS[1]} == fieldname
    ${ret}=    smarttender.Отримати інформацію із тендера    ${ARGUMENTS[0]}    ${ARGUMENTS[1]}
    [Return]    ${ret}

Отримати кількість предметів в тендері
    [Arguments]    ${user}    ${tenderId}
    smarttender.Пошук тендера по ідентифікатору     ${user}    ${tenderId}
    ${numberOfItems}=     Get Matching Xpath Count     xpath=//div[@id='home']//div[@class='well']
    [Return]    ${numberOfItems}

Отримати інформацію із запитання
    [Arguments]    ${user}    ${tenderId}    ${objectId}    ${field}
    ${selector}=        question_field_info    ${field}     ${objectId}
    Run Keyword And Ignore Error     smarttender.Відкрити сторінку із даними запитань
    ${ret}=    Execute JavaScript    return (function() { return $("${selector}").text() })()
    [Return]    ${ret}

Відкрити аналіз тендера
    Sleep   2s
    ${title}=   Get Title
    Return From KeyWord If     '${title}' != 'Комерційні торги та публічні закупівлі в системі ProZorro'
    smarttender.Пошук тендера по ідентифікатору     0       ${TENDER['TENDER_UAID']}
    ${href} =     Get Element Attribute    jquery=a.button.analysis-button@href
    Click Element     jquery=a.button.analysis-button
    sleep   5s
    Select Window     url=${href}
    sleep    3s
    Select Frame      jquery=iframe:eq(0)

Відкрити скарги тендера
    [Arguments]     ${username}
    sleep   3s
    smarttender.Пошук тендера по ідентифікатору     ${username}       ${TENDER['TENDER_UAID']}
    ${href} =     Get Element Attribute      jquery=a.compliant-button@href
    Click Element     jquery=a.compliant-button
    sleep   10s
    Select Window     url=${href}
    sleep    3s
    Select Frame      jquery=iframe:eq(0)

Отримати інформацію із документа
    [Arguments]    ${username}  ${tender_uaid}  ${doc_id}  ${field}
    Run Keyword     smarttender.Пошук тендера по ідентифікатору     ${username}     ${tender_uaid}
	${isCancellation}=    Set Variable If    '${TEST NAME}' == 'Відображення опису документа до скасування лоту' or '${TEST NAME}' == 'Відображення заголовку документа до скасування лоту' or '${TEST NAME}' == 'Відображення вмісту документа до скасування лоту'   True    False
    Run Keyword If       ${isCancellation} == True     smarttender.Відкрити сторінку із данними скасування
    ${selector}=     document_fields_info     ${field}    ${doc_id}   ${isCancellation}
    ${result}=      Execute JavaScript    return (function() { return $("${selector}").text() })()
    [Return]    ${result}

Перейти до запитань
    [Arguments]    @{ARGUMENTS}
    [Documentation]    ${ARGUMENTS[0]} = username
    ...    ${ARGUMENTS[1]} = ${TENDER_UAID}
    Switch Browser    ${ARGUMENTS[0]}
    smarttender.Оновити сторінку з тендером    @{ARGUMENTS}

Отримати інформацію із документа по індексу
    [Arguments]    ${user}  ${tenderId}  ${doc_index}  ${field}
    ${result}=     Execute JavaScript    return(function(){ return $("div.row.document:eq(${doc_index+1}) span.info_attachment_type:eq(0)").text();})()
    ${resultDoctype}=    map_from_smarttender_document_type    ${result}
    [Return]    ${resultDoctype}

Задати запитання на тендер
    [Arguments]    @{ARGUMENTS}
    [Documentation]    ${ARGUMENTS[0]} = username
    ...    ${ARGUMENTS[1]} = ${TENDER_UAID}
    ...    ${ARGUMENTS[2]} = question_data
    ${title}=    Get From Dictionary    ${ARGUMENTS[2].data}    title
    ${description}=    Get From Dictionary    ${ARGUMENTS[2].data}    description
    Run Keyword And Ignore Error    smarttender.Відкрити сторінку із даними запитань
    Execute JavaScript     return (function() { $('#question-relation').select2().val(0).trigger('change'); $('input#add-question').trigger('click');})()
    sleep    5s
    ${status}=       Execute Javascript       return (function() { var questionSubmitIframe = $("iframe:eq(0)").get(0).contentWindow; questionSubmitIframe.$("input[name='subject']").val("${title}"); questionSubmitIframe.$("textarea[name='question']").text("${description}"); var submitButton = questionSubmitIframe.$('div#SubmitButton__1'); if (submitButton.css('display') != 'none') { submitButton.click(); }; var status = questionSubmitIframe.$('span.dxflGroupBoxCaption_DevEx').text(); return status; })()
    Log     ${status}
    Should Not Be Equal      ${status}     Період обговорення закінчено
    ${question_id}=    Execute JavaScript       return (function() {return $("span.question_idcdb").text() })()
    ${question_data}=     smarttender_service.get_question_data      ${question_id}
    [Return]        ${question_data}

Задати запитання на предмет
    [Arguments]    @{ARGUMENTS}
    [Documentation]    ${ARGUMENTS[0]} = username
    ...    ${ARGUMENTS[1]} = ${TENDER_UAID}
    ...    ${ARGUMENTS[2]} = question_data
    ${title}=    Get From Dictionary    ${ARGUMENTS[3].data}    title
    ${description}=    Get From Dictionary    ${ARGUMENTS[3].data}    description
    smarttender.Пошук тендера по ідентифікатору    ${ARGUMENTS[0]}    ${ARGUMENTS[1]}
    Run Keyword And Ignore Error    smarttender.Відкрити сторінку із даними запитань
    Click Element    jquery=#select2-question-relation-container:eq(0)
    Focus    jquery=.select2-search__field:eq(0)
    Input Text    jquery=.select2-search__field:eq(0)       ${ARGUMENTS[2]}
    Press Key    jquery=.select2-search__field:eq(0)       \\13
    Click Element    jquery=input#add-question
    sleep    10s
    ${status}=       Execute Javascript       return (function() { var questionSubmitIframe = $("iframe:eq(0)").get(0).contentWindow; questionSubmitIframe.$("input[name='subject']").val("${title}"); questionSubmitIframe.$("textarea[name='question']").text("${description}"); var submitButton = questionSubmitIframe.$('div#SubmitButton__1'); if (submitButton.css('display') != 'none') { submitButton.click(); }; var status = questionSubmitIframe.$('span.dxflGroupBoxCaption_DevEx').text(); return status; })()
    Log     ${status}
    Should Not Be Equal      ${status}     Період обговорення закінчено
    ${question_id}=    Execute JavaScript       return (function() {return $("span.question_idcdb").text() })()
    ${question_data}=     smarttender_service.get_question_data      ${question_id}
    [Return]        ${question_data}

Відповісти на запитання
    [Arguments]    ${user}    ${tenderId}    ${answer}     ${questionId}
    Підготуватися до редагування     ${user}     ${tenderId}
    sleep    1s
    ${answerText}=      Get From Dictionary     ${answer.data}    answer
    Click Element    jquery=#MainSted2PageControl_TENDER ul.dxtc-stripContainer li.dxtc-tab:eq(1)
    Wait Until Page Contains    ${questionId}
    Focus    jquery=div[data-placeid='TENDER'] table.hdr:eq(3) tbody tr:eq(1) td:eq(2) input:eq(0)
    sleep    1s
    Input Text      jquery=div[data-placeid='TENDER'] table.hdr:eq(3) tbody tr:eq(1) td:eq(2) input:eq(0)    ${questionId}
    sleep    1s
    Press Key       jquery=div[data-placeid='TENDER'] table.hdr:eq(3) tbody tr:eq(1) td:eq(2) input:eq(0)        \\13
    sleep    1s
    Click Image    jquery=.dxrControl_DevEx a[title*='Змінити'] img:eq(0)
    sleep    2s
    Focus       jquery=#cpModalMode textarea:eq(0)
    Input Text    jquery=#cpModalMode textarea:eq(0)     ${answerText}
    sleep    2s
    Click Element    jquery=#cpModalMode span.dxICheckBox_DevEx:eq(0)
    sleep    2s
    Click Image    jquery=#cpModalMode .dxrControl_DevEx .dxr-buttonItem:eq(0) img
    sleep    2s
    Click Element     jquery=#cpIMMessageBox .dxbButton_DevEx:eq(0)
    sleep    2s
    Wait Until Page Contains    Відповідь надіслана на сервер ЦБД        20s

Подати цінову пропозицію
    [Arguments]    @{ARGUMENTS}
    [Documentation]    ${ARGUMENTS[0]} == username
    ...    ${ARGUMENTS[1]} == ${TENDER_UAID}
    ...    ${ARGUMENTS[2]} == ${test_bid_data}
    smarttender.Подати заявку на участь в аукціоні       ${ARGUMENTS[0]}     ${ARGUMENTS[1]}     ${ARGUMENTS[2]}
    Log     ${mode}
    ${response}=  smarttender.Прийняти участь в тендері     ${ARGUMENTS[0]}     ${ARGUMENTS[1]}     ${ARGUMENTS[2]}
    [Return]    ${response}

Подати заявку на участь в аукціоні
    [Arguments]    ${user}    ${tenderId}    ${bid}
    Switch Browser  ${browserAlias}
    # натиснути "Взяти участь"
    loading дочекатися відображення елемента на сторінці  //*[@data-qa="btn-participate"]
    click element  //*[@data-qa="btn-participate"]
    ${participate_modal_locator}  set variable  //*[@data-qa="dynamic-form-auction-request"]
	loading дочекатися відображення елемента на сторінці  ${participate_modal_locator}//*[@placeholder="Ваше ім'я"]
	# Заповнити всі поля
	input text  ${participate_modal_locator}//*[@placeholder="Ваше ім'я"]  Іван
	input text  ${participate_modal_locator}//*[@placeholder="Ваше прізвище"]  Іванов
	input text  ${participate_modal_locator}//*[@placeholder="Як Вас по батькові"]  Іванович
	input text  ${participate_modal_locator}//*[@placeholder="Ваш номер"]  +38011111111
	# Завантажити документи
    ${file_path}  ${file_name}  ${file_content}=  create_fake_doc
    smarttender.Додати документ до кваліфікації    xpath=(${participate_modal_locator}//input[@type="file"])[3]    ${file_path}
    smarttender.Додати документ до кваліфікації    xpath=(${participate_modal_locator}//input[@type="file"])[1]    ${file_path}
    # Відмітити всі чекбокси
    click element  xpath=(${participate_modal_locator}//input[@type="checkbox"])[1]
	sleep  5s
	capture page screenshot
	click element  ${participate_modal_locator}//*[@data-qa="dynamic-form-submit-button"]
	loading дочекатись закінчення загрузки сторінки
	# Підтвердити заявку
	${resp}  evaluate  requests.get("""http://test.smarttender.biz/ws/webservice.asmx/ExecuteEx?calcId=_QA.ACCEPTAUCTIONBIDREQUEST&args={"IDLOT":"${tenderId}","SUCCESS":"true"}&ticket=""")  requests
	should be equal as integers  ${resp.status_code}  200
	should contain  ${resp.text}  True
	reload page
	loading дочекатись закінчення загрузки сторінки


Додати документ до кваліфікації
    [Arguments]    ${selector}    ${doc}
    Choose File    ${selector}    ${doc}
    sleep    2s

Заповнити поле значенням
    [Arguments]    ${selector}     ${value}
    Focus    ${selector}
    sleep    1s
    Input Text    ${selector}    ${value}
    sleep    1s

Змінити цінову пропозицію
    [Arguments]    @{ARGUMENTS}
    [Documentation]    ${ARGUMENTS[0]} == username
    ...    ${ARGUMENTS[1]} == ${TENDER_UAID}
    ...    ${ARGUMENTS[2]} ==  value.amount
    ...    ${ARGUMENTS[3]} ==  50000
    smarttender.Прийняти участь в тендері      ${ARGUMENTS[0]}    ${ARGUMENTS[1]}    ${ARGUMENTS[3]}

Прийняти участь в тендері
    [Arguments]    @{ARGUMENTS}
    [Documentation]    ${ARGUMENTS[0]} == username
    ...    ${ARGUMENTS[1]} == ${TENDER_UAID}
    ...    ${ARGUMENTS[2]} ==  ${test_bid_data}
    ${amount}=      Get From Dictionary    ${ARGUMENTS[2].data.value}      amount
    click element  //*[@data-qa="btn-bid-submit"]
	loading дочекатись закінчення загрузки сторінки
	loading дочекатися відображення елемента на сторінці  //input[@placeholder="Ваша ставка, грн."]
	input text  //input[@placeholder="Ваша ставка, грн."]  "${amount}"
	click element  //*[@id="submitBidPlease"]
	loading дочекатись закінчення загрузки сторінки
	Wait Until Page Contains       Пропозицію прийнято      15s
    ${response}=      smarttender_service.get_bid_response    ${${amount}}
    [Return]    ${response}

Прийняти участь в тендері dgfInsider
    [Arguments]    @{ARGUMENTS}
    [Documentation]    ${ARGUMENTS[0]} == username
    ...    ${ARGUMENTS[1]} == ${TENDER_UAID}
    ...    ${ARGUMENTS[2]} == bid_info
    smarttender.Пошук тендера по ідентифікатору      ${ARGUMENTS[0]}     ${ARGUMENTS[1]}
    Wait Until Page Contains Element        jquery=a#bid    5s
    ${href} =     Get Element Attribute      jquery=a#bid@href
    Click Element     jquery=a#bid
    sleep  5s
    Select Window     url=${href}
    Wait Until Page Contains       Пропозиція по аукціону   10s
    Wait Until Page Contains Element        jquery=button#submitBidPlease    5s
    Click Element      jquery=button#submitBidPlease
    Wait Until Page Contains Element        jquery=button:contains('Так')    5s
    Click Element      jquery=button:contains('Так')
    Wait Until Page Contains       Пропозицію прийнято      30s
    [Return]    ${ARGUMENTS[2]}

Отримати інформацію із пропозиції
    [Arguments]    @{ARGUMENTS}
    [Documentation]    ${ARGUMENTS[0]} == username
    ...    ${ARGUMENTS[1]} == ${TENDER_UAID}
    ...    ${ARGUMENTS[2]} == field
    smarttender.Пошук тендера по ідентифікатору     ${ARGUMENTS[0]}    ${ARGUMENTS[1]}
    ${ret}=     smarttender.Отримати інформацію із тендера     ${ARGUMENTS[0]}     ${ARGUMENTS[1]}   ${ARGUMENTS[2]}
    ${ret}=     Execute JavaScript    return (function() { return parseFloat('${ret}') })()
    [Return]     ${ret}

Завантажити документ в ставку
    [Arguments]    @{ARGUMENTS}
    [Documentation]    ${ARGUMENTS[0]} == username
    ...    ${ARGUMENTS[1]} == path
    ...    ${ARGUMENTS[2]} == tenderid
    Pass Execution If     '${mode}' == 'dgfOtherAssets'     Для типа 'Продаж майна банків, що ліквідуються' документы не вкладываются
    Run Keyword     smarttender.Пошук тендера по ідентифікатору     ${ARGUMENTS[0]}     ${ARGUMENTS[2]}
	click element  //*[@data-qa="btn-bid-submit"]
	loading дочекатись закінчення загрузки сторінки
	Choose File     //input[@type="file"]    ${ARGUMENTS[1]}
	loading дочекатись закінчення загрузки сторінки
	click element  //*[@id="submitBidPlease"]
	loading дочекатись закінчення загрузки сторінки
    Wait Until Page Contains       Пропозицію прийнято      30s

Змінити документ в ставці
    [Arguments]    @{ARGUMENTS}
    smarttender.Завантажити документ в ставку     ${ARGUMENTS[0]}      ${ARGUMENTS[2]}     ${TENDER['TENDER_UAID']}

Відкрити сторінку із даними запитань
    ${alreadyOpened}=    Execute JavaScript    return(function(){ ((window.location.href).indexOf('discuss') !== -1).toString();})()
    Return From Keyword If    '${alreadyOpened}' == 'true'
    Click Element    jquery=a#question:eq(0)
    ${href}=    Get Element Attribute    jquery=a#question:eq(0)@href
    Select Window     url=${href}
    sleep     3s
    Select Frame    jquery=iframe:eq(0)
    sleep    3s
    [Return]

Отримати документ
    [Arguments]    ${user}    ${tenderId}     ${docId}
    Run Keyword     smarttender.Пошук тендера по ідентифікатору     ${user}     ${tenderId}
    ${selector}=     document_fields_info     content    ${docId}    False
    ${fileUrl}=     Get Element Attribute    jquery=div.row.document:contains('${docId}') a.info_attachment_link:eq(0)@href
    ${result}=      Execute JavaScript    return (function() { return $("${selector}").text() })()
    smarttender_service.download_file    ${fileUrl}    ${OUTPUT_DIR}${/}${result}
    sleep   7s
    [Return]     ${result}

Завантажити ілюстрацію
    [Arguments]    @{ARGUMENTS}
    Pass Execution If      '${role}' == 'provider' or '${role}' == 'viewer'     Даний учасник не може завантажити ілюстрацію
    Підготуватися до редагування    ${ARGUMENTS[0]}     ${ARGUMENTS[1]}
    Click Element     jquery=.dxrControl_DevEx a[title*='(F4)'] img:eq(0)
    Wait Until Page Contains    Завантаження документації
    sleep    2s
    Додати документ за шляхом    ${ARGUMENTS[2]}
    Click Element    jquery=label:Contains('illustration')
    Wait Until Element Is Enabled       jquery=td.dhxcombo_input_container:eq(0)
    sleep    3s
    Focus    jquery=div[data-name='DOCUMENT_TYPE'] td.dhxcombo_input_container input:eq(0)
    Input Text      jquery=div[data-name='DOCUMENT_TYPE'] td.dhxcombo_input_container input:eq(0)    Ілюстрація
    Press Key        jquery=div[data-name='DOCUMENT_TYPE'] td.dhxcombo_input_container input:eq(0)         \\13
    sleep    3s
    Click Image     jquery=#cpModalMode div.dxrControl_DevEx a:contains('Зберегти') img
    sleep    5s

Додати Virtual Data Room
    [Arguments]    ${user}    ${tenderId}     ${link}
    Pass Execution If      '${role}' == 'provider' or '${role}' == 'viewer'     Даний учасник не може завантажити ілюстрацію
    Підготуватися до редагування    ${user}     ${tenderId}
    Click Element     jquery=.dxrControl_DevEx a[title*='(F4)'] img:eq(0)
    Wait Until Page Contains    Завантаження документації
    Click Element     jquery=#cpModalMode li.dxtc-tab:contains('Завантаження документації')
    sleep    2s
    Focus    jquery=div#pcModalMode_PWC-1 table[data-name='VDRLINK'] input:eq(0)
    Input Text    jquery=div#pcModalMode_PWC-1 table[data-name='VDRLINK'] input:eq(0)    ${link}
    Press Key    jquery=div#pcModalMode_PWC-1 table[data-name='VDRLINK'] input:eq(0)    \\13
    sleep    3s
    Click Image     jquery=#cpModalMode div.dxrControl_DevEx a:contains('Зберегти') img
    sleep    5s

Додати публічний паспорт активу
    [Arguments]    ${user}    ${tenderId}     ${link}
    Pass Execution If      '${role}' == 'provider' or '${role}' == 'viewer'     Даний учасник не може завантажити паспорт активу
    Підготуватися до редагування    ${user}     ${tenderId}
    Click Element     jquery=.dxrControl_DevEx a[title*='(F4)'] img:eq(0)
    Wait Until Page Contains    Завантаження документації
    Click Element     jquery=#cpModalMode li.dxtc-tab:contains('Завантаження документації')
    sleep    2s
    Focus    jquery=div#pcModalMode_PWC-1 table[data-name='PACLINK'] input:eq(0)
    Input Text    jquery=div#pcModalMode_PWC-1 table[data-name='PACLINK'] input:eq(0)    ${link}
    Press Key    jquery=div#pcModalMode_PWC-1 table[data-name='PACLINK'] input:eq(0)    \\13
    sleep    3s
    Click Image     jquery=#cpModalMode div.dxrControl_DevEx a:contains('Зберегти') img
    sleep    5s

Додати офлайн документ
    [Arguments]    ${user}    ${tenderId}     ${description}
    Pass Execution If      '${role}' == 'provider' or '${role}' == 'viewer'     Даний учасник не може додати офлайн документ
    Підготуватися до редагування    ${user}     ${tenderId}
    Click Element     jquery=.dxrControl_DevEx a[title*='(F4)'] img:eq(0)
    Wait Until Page Contains    Завантаження документації
    Click Element     jquery=#cpModalMode li.dxtc-tab:contains('Завантаження документації')
    sleep    2s
    Focus    jquery=div#pcModalMode_PWC-1 table[data-name='ACCESSDET'] textarea:eq(0)
    Input Text    jquery=div#pcModalMode_PWC-1 table[data-name='ACCESSDET'] textarea:eq(0)    ${description}
    Press Key    jquery=div#pcModalMode_PWC-1 table[data-name='ACCESSDET'] textarea:eq(0)    \\13
    sleep    3s
    Click Image     jquery=#cpModalMode div.dxrControl_DevEx a:contains('Зберегти') img
    sleep    5s

Завантажити документ в тендер з типом
    [Arguments]    ${user}    ${tenderId}    ${file_path}    ${doc_type}
    Pass Execution If      '${role}' == 'provider' or '${role}' == 'viewer'     Даний учасник не може завантажити документ в тендер
    Підготуватися до редагування    ${user}    ${tenderId}
    Click Element     jquery=.dxrControl_DevEx a[title*='(F4)'] img:eq(0)
    Wait Until Page Contains    Завантаження документації
    sleep    2s
    smarttender.Додати документ за шляхом    ${file_path}
    ${documentTypeNormalized}=    map_to_smarttender_document_type    ${doc_type}
    Click Element    jquery=label:contains('(файл завантаження)')
    Wait Until Element Is Enabled       jquery=td.dhxcombo_input_container:eq(0)
    sleep    3s
    Focus    jquery=div[data-name='DOCUMENT_TYPE'] td.dhxcombo_input_container input:eq(0)
    Input Text      jquery=div[data-name='DOCUMENT_TYPE'] td.dhxcombo_input_container input:eq(0)    ${documentTypeNormalized}
    Press Key        jquery=div[data-name='DOCUMENT_TYPE'] td.dhxcombo_input_container input:eq(0)         \\13
    sleep    3s
    Click Image     jquery=#cpModalMode div.dxrControl_DevEx a:contains('Зберегти') img
    sleep    5s

Завантажити фінансову ліцензію
    [Arguments]    ${user}    ${tenderId}    ${license_path}
    smarttender.Завантажити документ в ставку    ${user}    ${license_path}    ${tenderId}

Отримати кількість документів в тендері
    [Arguments]    ${user}    ${tenderId}
    Run Keyword    smarttender.Пошук тендера по ідентифікатору    ${user}    ${tenderId}
    ${documentNumber}=    Execute JavaScript    return (function(){return $("div.row.document").length-1;})()
    ${documentNumber}=    Convert To Integer    ${documentNumber}
    [Return]    ${documentNumber}

####################################
#          CANCELLATION            #
####################################

Скасувати закупівлю
    [Arguments]    ${user}     ${tenderId}     ${reason}    ${file}    ${descript}
    Pass Execution If      '${role}' == 'provider' or '${role}' == 'viewer'     Даний учасник не може скасувати тендер
    ${documents}=    create_fake_doc
    Підготуватися до редагування    ${user}     ${tenderId}
    Click Element       jquery=a[data-name='F2_________GPCANCEL']
    Wait Until Page Contains    Протоколи скасування
    sleep    2s
    Focus    jquery=#cpModalMode table[data-name='reason'] input:eq(1)
    Execute JavaScript    (function(){$("#cpModalMode table[data-name='reason'] input:eq(1)").val('');})()
    sleep    3s
    Input Text    jquery=#cpModalMode table[data-name='reason'] input:eq(1)    ${reason}
    sleep    3s
    Press Key        jquery=#cpModalMode table[data-name='reason'] input:eq(1)         \\13
    sleep    2s
    Click Element       jquery=div[title='Додати']
    Wait Until Page Contains       Список файлів
    Choose File      jquery=#cpModalMode input[type=file]:eq(1)    ${file}
    sleep    2s
    Click Element    jquery=span:Contains('ОК'):eq(0)
    Wait Until Page Contains    Протоколи скасування
    Click Element    jquery=label:Contains('Завантажений файл'):eq(0)
    sleep    1s
    Focus    jquery=table[data-name='DocumentDescription'] input:eq(0)
    Input Text    jquery=table[data-name='DocumentDescription'] input:eq(0)    ${descript}
    Wait Until Page Contains    Протоколи скасування
    Click Element       jquery=a[title='OK']
    Wait Until Page Contains    аукціон буде
    Click Element    jquery=#IMMessageBoxBtnYes
    sleep   3s

Скасувати цінову пропозицію
    [Arguments]    @{ARGUMENTS}
    [Documentation]    ${ARGUMENTS[0]} == username
    ...    ${ARGUMENTS[1]} == ${TENDER_UAID}
    smarttender.Пошук тендера по ідентифікатору     ${ARGUMENTS[0]}     ${ARGUMENTS[1]}
    ${href} =     Get Element Attribute      jquery=a:Contains('Подати пропозицію')@href
    Click Element      jquery=a:Contains('Подати пропозицію')
    sleep    3s
    Select Window     url=${href}
    sleep     3s
    Select Frame     jquery=iframe#iframe
    sleep    1s
    Click Element      jquery=#btCancellationOffers
    sleep    2s
    Wait Until Keyword Succeeds    10 sec    2 sec    Current Frame Contains    Пропозиція анульована

Відкрити сторінку із данними скасування
    Click Element       jquery=a#cancellation:eq(0)
    Select Frame    jquery=#widgetIframe
    sleep    10s
    [Return]

Закрити сторінку із данними скасування
    Click button       jquery=button.close:eq(0)
    Select Frame    jquery=iframe:eq(0)
    sleep       3s
    [Return]

####################################
#             AUCTION              #
####################################

Отримати посилання на аукціон для глядача
    [Arguments]    @{ARGUMENTS}
    Switch Browser  ${browserAlias}
    reload page
    loading дочекатись закінчення загрузки сторінки
    click element  //*[@data-qa="button-poptip-view"]
    sleep  3
	loading дочекатися відображення елемента на сторінці  //a[@data-qa="link-view"]
	${href}  get element attribute  //a[@data-qa="link-view"]@href
    Log    ${href}
    [Return]      ${href}

Отримати посилання на аукціон для учасника
    [Arguments]    @{ARGUMENTS}
    Switch Browser  ${browserAlias}
    reload page
    loading дочекатись закінчення загрузки сторінки
	click element  //*[@data-qa="button-poptip-participate-view"]
	sleep  5
	loading дочекатися відображення елемента на сторінці  //a[@data-qa="link-participate"]
	${href}  get element attribute  //a[@data-qa="link-participate"]@href
	[Return]      ${href}

####################################
#          QUALIFICATION           #
####################################

Підтвердити наявність протоколу аукціону
    [Arguments]    ${user}     ${tenderId}    ${bidIndex}
    Run Keyword    smarttender.Підготуватися до редагування    ${user}    ${tenderId}
    Click Element     jquery=#MainSted2TabPageHeaderLabelActive_1
    sleep     1s
    ${normalizedIndex}=     normalize_index    ${bidIndex}     1
    Click Element    jquery=div[data-placeid='BIDS'] div.objbox.selectable.objbox-scrollable table tbody tr:eq(${normalizedIndex}) td:eq(2)
    Wait Until Page Contains    Вкладення до пропозиції
    sleep   6s
    ${count}=     Execute JavaScript    return(function(){ var counter = 0;var documentSelector = $("#cpModalMode tr label:contains('Протокол рішення Кваліфікаційного комітету')").closest("tr");while (true) { documentSelector = documentSelector.next(); if(documentSelector.length == 0 || documentSelector[0].innerHTML.indexOf("label") === -1){ break;} counter = counter +1;} return counter;})()
    Should Be True    ${count} > ${0}

Отримати кількість документів в ставці
    [Arguments]    ${user}     ${tenderId}    ${bidIndex}
    Run Keyword    smarttender.Підготуватися до редагування    ${user}    ${tenderId}
    Click Element     jquery=#MainSted2TabPageHeaderLabelActive_1
    sleep     1s
    ${normalizedIndex}=     normalize_index    ${bidIndex}     1
    Click Element    jquery=div[data-placeid='BIDS'] div.objbox.selectable.objbox-scrollable table tbody tr:eq(${normalizedIndex}) td:eq(2)
    Wait Until Page Contains    Вкладення до пропозиції
    sleep   6s
    ${count}=     Execute JavaScript    return(function(){ var counter = 0;var documentSelector = $("#cpModalMode tr label:contains('Квалификации')").closest("tr");while (true) { documentSelector = documentSelector.next(); if(documentSelector.length == 0 || documentSelector[0].innerHTML.indexOf("label") === -1){ break;} counter = counter +1;} return counter;})()
    [Return]    ${count}

Підтвердити постачальника
    [Arguments]    @{ARGUMENTS}
    Pass Execution If      '${role}' == 'provider' or '${role}' == 'viewer'     Даний учасник не може підтвердити постачальника
    Підготуватися до редагування     ${ARGUMENTS[0]}      ${ARGUMENTS[1]}
    loading дочекатись закінчення загрузки сторінки
	click element  //*[@id="MainSted2TabPageHeaderLabelActive_1" and contains(., "Пропозиції")]
	loading дочекатись закінчення загрузки сторінки
    ${normalizedIndex}=     evaluate  int(${ARGUMENTS[2]}) + 1
    click element  xpath=(//*[@data-placeid="BIDS"]//*[@class="objbox selectable objbox-scrollable"]//tr[not(@style)])[${normalizedIndex}]
    loading дочекатись закінчення загрузки сторінки
	loading дочекатися відображення елемента на сторінці  //*[@title="Кваліфікація"]
    click element  //*[@title="Кваліфікація"]
    ${qual_sceen_locator}  set variable  //*[@id="pcModalMode_PW-1" and contains(., "Рішення кваліфікації")]
	loading дочекатися відображення елемента на сторінці  ${qual_sceen_locator}
	# Підтвердити перевірку протоколу
	click element  ${qual_sceen_locator}//*[text()="Підтвердити перевірку протоколу"]
	loading дочекатись закінчення загрузки сторінки
	# Натиснути зберегти
	click element  ${qual_sceen_locator}//*[@title="Зберегти"]
	loading дочекатись закінчення загрузки сторінки
	# Натиснути "Так" в валідаційному вікні
	loading дочекатися відображення елемента на сторінці  //*[@id="IMMessageBox_PW-1" and contains(., "Ви впевнені у своєму рішенні?")]
	click element  //*[@id="IMMessageBox_PW-1" and contains(., "Ви впевнені у своєму рішенні?")]//*[@id="IMMessageBoxBtnYes"]
	loading дочекатись закінчення загрузки сторінки
    sleep    10s
    # Отримати статус біда
    ${status}  get element attribute  xpath=(//*[@data-placeid="BIDS"]//*[@class="objbox selectable objbox-scrollable"]//tr[not(@style) and contains(@class, "rowselected")]//td)[6]@innerText
    should be equal as strings  ${status}  Визначений переможцем

Отримати дані із документу пропозиції
    [Arguments]    ${user}    ${tenderId}    ${bid_index}    ${document_index}    ${field}
    Run Keyword    smarttender.Підготуватися до редагування    ${user}    ${tenderId}
    Click Element     jquery=#MainSted2TabPageHeaderLabelActive_1
    sleep     1s
    ${normalizedIndex}=     normalize_index    ${bid_index}     1
    Click Element    jquery=div[data-placeid='BIDS'] div.objbox.selectable.objbox-scrollable table tbody tr:eq(${normalizedIndex}) td:eq(2)
    Wait Until Page Contains    Вкладення до пропозиції
    ${selectedType}=     Execute JavaScript    return(function(){ var startElement = $("#cpModalMode tr label:contains('Квалификации')"); var documentSelector = $(startElement).closest("tr").next(); if(${document_index} > 0){ for (i=0;i<=${document_index};i++) {documentSelector = $(documentSelector).next();}}if($(documentSelector).length == 0) {return "";} return "auctionProtocol";})()
    [Return]    ${selectedType}

Скасування рішення кваліфікаційної комісії
    [Arguments]    ${user}    ${tenderId}    ${index}
    Pass Execution If      '${role}' == 'provider' or '${role}' == 'tender_owner'   Доступно тільки для другого учасника
    # Відкрити сторінку детальної
    Run Keyword    smarttender.Пошук тендера по ідентифікатору    ${user}    ${tenderId}
    # Натиснути "Забрати ГВ"
    loading дочекатися відображення елемента на сторінці  //*[@data-qa="btn-withdraw-participation-auction"]
    click element  //*[@data-qa="btn-withdraw-participation-auction"]
    # Активувати айфрейм в модалці
    loading дочекатися відображення елемента на сторінці  //*[@data-qa="modal-withdraw"]
	Select Frame  //iframe[@data-qa="modal-withdraw-frame"]
	# Погодитися в першому вікні
	click element  //*[@id="firstYes"]
	# Погодитися в другому вікні
	click element  //*[@id="secondYes"]
	Unselect Frame
	sleep  5s

Дискваліфікувати постачальника
    [Arguments]    ${user}    ${tenderId}    ${index}    ${description}
    Підготуватися до редагування     ${user}      ${tenderId}
    sleep    3s
    Click Element      jquery=#MainSted2TabPageHeaderLabelActive_1
    sleep    1s
    ${normalizedIndex}=     normalize_index    ${index}     1
    Click Element    jquery=div[data-placeid='BIDS'] div.objbox.selectable.objbox-scrollable table tbody tr:eq(${normalizedIndex}) td:eq(1)
    sleep    2s
    Click Element      jquery=a[title='Дисквалификация']
    sleep    5s
    # Додати файл
    click element  //input[@value="Перегляд..."]/../..
    loading дочекатись закінчення загрузки сторінки
    ${file_path}  ${file_title}  ${file_content}=  create_fake_doc
    choose file  //input[@name="fileUpload[]"]  ${file_path}
    sleep  10
    click element  //*[@id="OpenFileRibbon_T0G0"]
    loading дочекатись закінчення загрузки сторінки
    Focus    jquery=#cpModalMode textarea
    Input Text    jquery=#cpModalMode textarea    ${description}
    Click Element    jquery=div.dxbButton_DevEx.dxbButtonSys.dxbTSys span:contains('Відхилити пропозицію')
    Wait Until Page Contains    Ви впевнені у своєму рішенні?
    Click Element    jquery=#IMMessageBoxBtnYes
    loading дочекатись закінчення загрузки сторінки

Завантажити протокол аукціону
    [Arguments]    ${user}    ${tenderId}    ${filePath}    ${index}
    Підготуватися до редагування     ${user}    ${tenderId}
    loading дочекатись закінчення загрузки сторінки
	click element  //*[@id="MainSted2TabPageHeaderLabelActive_1" and contains(., "Пропозиції")]
	loading дочекатись закінчення загрузки сторінки
    ${normalizedIndex}=     evaluate  int(${index}) + 1
    click element  xpath=(//*[@data-placeid="BIDS"]//*[@class="objbox selectable objbox-scrollable"]//tr[not(@style)])[${normalizedIndex}]
    loading дочекатись закінчення загрузки сторінки
	loading дочекатися відображення елемента на сторінці  //*[@title="Кваліфікація"]
    click element  //*[@title="Кваліфікація"]
    ${qual_sceen_locator}  set variable  //*[@id="pcModalMode_PW-1" and contains(., "Рішення кваліфікації")]
	loading дочекатися відображення елемента на сторінці  ${qual_sceen_locator}
	# Завантажити протокол аукціону
	click element  ${qual_sceen_locator}//*[text()="Перегляд..."]
	loading дочекатися відображення елемента на сторінці  //*[@id="pcModalMode_PW-1" and contains(., "Виберіть протокол(и) рішення Кваліфікаційного комітету")]
	Choose File  //*[@id="pcModalMode_PW-1" and contains(., "Виберіть протокол(и) рішення Кваліфікаційного комітету")]//input[@name="fileUpload[]"]  ${filePath}
	sleep  10
	click element  //*[@id="OpenFileRibbon_T0G0"]
	loading дочекатись закінчення загрузки сторінки
	# Натиснути зберегти
	click element  ${qual_sceen_locator}//*[@title="Зберегти"]
	loading дочекатись закінчення загрузки сторінки


Завантажити протокол аукціону в авард
    [Arguments]    ${username}    ${tender_uaid}    ${filepath}    ${award_index}
    smarttender.Завантажити документ рішення кваліфікаційної комісії    ${username}    ${filepath}    ${tender_uaid}     ${award_index}
    Sleep    3s    reason=None
    Click Element    jquery=a[title='Зберегти']
    Sleep    1s    reason=None
    Wait Until Page Contains    Ви впевнені у своєму рішенні?
    Click Element    jquery=#IMMessageBoxBtnYes
    Sleep    10s

Завантажити документ рішення кваліфікаційної комісії
    [Arguments]    ${user}    ${filePath}    ${tenderId}    ${index}
    Pass Execution If      '${role}' == 'provider' or '${role}' == 'viewer'     Даний учасник не може підтвердити постачальника
    Підготуватися до редагування     ${user}      ${tenderId}
    sleep    3s
    Click Element      jquery=#MainSted2TabPageHeaderLabelActive_1
    sleep    2s
    ${normalizedIndex}=     normalize_index    ${index}     1
    Click Element    jquery=div[data-placeid='BIDS'] div.objbox.selectable.objbox-scrollable table tbody tr:eq(${normalizedIndex}) td:eq(1)
    sleep    2s
    Click Element      jquery=a[title='Кваліфікація']
    sleep    5s
    Click Element    jquery=span:contains('Обзор')
    Wait Until Page Contains    Список файлів
    Choose File    jquery=#OpenFileUploadControl_TextBox0_Input:eq(0)     ${filePath}
    sleep     3s
    Click Element    jquery=span:Contains('ОК'):eq(0)
    sleep     5s
    Click Element    jquery=div.dxbButton_DevEx:eq(2)

####################################
#         CONTRACT SIGNING         #
####################################
Вказати дату отримання оплати
	[Arguments]    @{ARGUMENTS}
	Run Keyword    smarttender.Підготуватися до редагування      ${ARGUMENTS[0]}    ${ARGUMENTS[1]}
	Click Element     jquery=#MainSted2TabPageHeaderLabelActive_1
    sleep    1s
    Click Element     jquery=#MainSted2TabPageHeaderLabelActive_1
    sleep    1s
    Click Element    jquery=div[data-placeid='BIDS'] div.objbox.selectable.objbox-scrollable table tbody tr:contains('Визначений переможцем') td:eq(1)
    loading дочекатись закінчення загрузки сторінки
    Click Element    jquery=a[title='Прикріпити договір']:eq(0)
    loading дочекатись закінчення загрузки сторінки
    ${date_to_smart_format}  convert_datetime_to_smarttender_format  ${ARGUMENTS[3]}
    input text  xpath=//*[text()="Дата оплати"]//following-sibling::table//input  ${date_to_smart_format}
    Input Text  xpath=//*[text()="Номер договору"]//following-sibling::table//input    11111111111111
    loading дочекатись закінчення загрузки сторінки
    Click Element    //*[@data-name="OkButton"]
    loading дочекатись закінчення загрузки сторінки

Завантажити угоду до тендера
    [Arguments]    @{ARGUMENTS}
    Run Keyword    smarttender.Підготуватися до редагування      ${ARGUMENTS[0]}    ${ARGUMENTS[1]}
    sleep    1s
    Click Element     jquery=#MainSted2TabPageHeaderLabelActive_1
    sleep    1s
    Click Element    jquery=div[data-placeid='BIDS'] div.objbox.selectable.objbox-scrollable table tbody tr:contains('Визначений переможцем') td:eq(1)
    loading дочекатись закінчення загрузки сторінки
    Click Element    jquery=a[title='Прикріпити договір']:eq(0)
    Wait Until Page Contains    Вкладення договірних документів
    sleep    2s
    ${file_path}  ${file_title}  ${file_content}=  create_fake_doc
    ${argCount}=    Get Length    ${ARGUMENTS}
    ${doc}=    Set Variable If
    ...        '${argCount}' == '4'    ${ARGUMENTS[3]}
    ...        ${file_path}
    Click Element    jquery=.dxbButton_DevEx span:Contains('Перегляд...'):eq(0)
    loading дочекатись закінчення загрузки сторінки
    Choose File    //input[@name="fileUpload[]"]     ${doc}
    sleep     10s
    Click Element    jquery=span:Contains('ОК'):eq(0)
    loading дочекатись закінчення загрузки сторінки
    Click Element    jquery=a[title='OK']:eq(0)
    loading дочекатись закінчення загрузки сторінки

Підтвердити підписання контракту
    [Arguments]    @{ARGUMENTS}
    Pass Execution If      '${role}' == 'provider' or '${role}' == 'viewer'     Даний учасник не може підписати договір
    smarttender.Підготуватися до редагування    ${ARGUMENTS[0]}     ${ARGUMENTS[1]}
    Click Element     jquery=#MainSted2TabPageHeaderLabelActive_1
    sleep    1s
    Click Element    jquery=div[data-placeid='BIDS'] div.objbox.selectable.objbox-scrollable table tbody tr:contains('Визначений переможцем') td:eq(1)
    loading дочекатися відображення елемента на сторінці
    Click Element    //*[@title="Завершити електронні торги"]
    loading дочекатися відображення елемента на сторінці
    Click Element    jquery=#IMMessageBoxBtnYes_CD:eq(0)
    loading дочекатись закінчення загрузки сторінки
    Click Element    jquery=#IMMessageBoxBtnOK:eq(0)
    sleep      2s
    ${ContractState}=        Execute JavaScript        return (function(){ return $("div[data-placeid='BIDS'] div.objbox.selectable.objbox-scrollable table tbody tr:contains('Визначений переможцем') td:eq(7)").text();})()
    Should Be Equal     ${ContractState}     Підписаний



################################################################################################################
                                        ###   KEYWORDS   ###
################################################################################################################
Дочекатись синхронізації
	${url}  Set Variable  http://test.smarttender.biz/ws/webservice.asmx/Execute?calcId=_QA.GET.LAST.SYNCHRONIZATION&args={"SEGMENT":4}
	${response}  evaluate  requests.get('${url}').content  requests
	${a}  Replace String  ${response}   \n  ${Empty}
	${content}  Get Regexp Matches  ${a}  {(?P<content>.*)}  content
	${reg}  evaluate  re.search(r'"DateStart":"(?P<DateStart>.*)","DateEnd":"(?P<DateEnd>.*)","WorkStatus":"(?P<WorkStatus>.*)","Success":(?P<Success>.*)', '${content[0]}')  re
	${DateStart}  evaluate  "${reg.group('DateStart')}"
	${DateEnd}  evaluate  "${reg.group('DateEnd')}"
	${WorkStatus}  evaluate  "${reg.group('WorkStatus')}"
	${Success}  evaluate  "${reg.group('Success')}"

	${result}  Subtract Date From Date  ${DateStart}  ${TENDER['LAST_MODIFICATION_DATE']}  date1_format=%d.%m.%Y %H:%M:%S  date2_format=%Y-%m-%d %H:%M:%S.%f
	${status}  set variable if  ${result} > 0  ${True}
	${status}  Run Keyword if  ${status} and '${DateEnd}' != '${EMPTY}' and '${WorkStatus}' != 'working' and '${WorkStatus}' != 'fail' and '${Success}' == 'true'
	...  Set Variable  Pass
	Should Be Equal  ${status}  Pass


Підтвердити вибір(F10)
	${ok button}  Set Variable  //*[@title="Вибрати"]|//*[@title="Выбрать"]
	loading дочекатися відображення елемента на сторінці  ${ok button}
	loading дочекатись закінчення загрузки сторінки
	Click Element  ${ok button}
	loading дочекатись закінчення загрузки сторінки
	Wait Until Page Does Not Contain Element  ${ok button}