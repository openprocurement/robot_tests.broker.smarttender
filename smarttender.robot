*** Settings ***
Library           Selenium2Screenshots
Library           String
Library           DateTime
Library           smarttender_service.py
Library           op_robot_tests.tests_files.service_keywords

*** Variables ***
${locator.auctionID}    jquery=span.info_tendernum
${locator.procuringEntity.name}       jquery=span.info_organization
${locator.tenderPeriod.startDate}    jquery=span.info_d_sch
${locator.tenderPeriod.endDate}    jquery=span.info_d_srok
${locator.enquiryPeriod.endDate}    jquery=span.info_ddm
${locator.auctionPeriod.startDate}      jquery=span.info_dtauction
${locator.questions[0].description}    ${EMPTY}
${locator.questions[0].answer}    ${EMPTY}

*** Keywords ***

Підготувати дані для оголошення тендера
    [Arguments]   ${username}    ${tender_data}    ${param3}
    ${tender_data}=       adapt_data       ${tender_data}
	Log    ${tender_data}
    [Return]    ${tender_data}

Підготувати клієнт для користувача
    [Arguments]    @{ARGUMENTS}
    [Documentation]      Відкрити браузер, створити об’єкт api wrapper, тощо
    ...    ${ARGUMENTS[0]} == username
    Open Browser    ${USERS.users['${ARGUMENTS[0]}'].homepage}    ${USERS.users['${ARGUMENTS[0]}'].browser}    alias=${ARGUMENTS[0]}
    Set Window Size    @{USERS.users['${ARGUMENTS[0]}'].size}
    Set Window Position    @{USERS.users['${ARGUMENTS[0]}'].position}
    Run Keyword If      '${ARGUMENTS[0]}' != 'SmartTender_Viewer'      Login      @{ARGUMENTS}

Login
    [Arguments]     @{ARGUMENTS}
    Click Element    LoginAnchor
    Input Text    jquery=.login-tb:eq(1)    ${USERS.users['${ARGUMENTS[0]}'].login}
    Input Text    jquery=.password-tb:eq(1)    ${USERS.users['${ARGUMENTS[0]}'].password}
    Click Element    jquery=.remember-cb:eq(1)
    Click Element    jquery=#sm_content .log-in a.button
    sleep    5s

Створити тендер
    [Arguments]    @{ARGUMENTS}
    ${tender_data}=    Set Variable    ${ARGUMENTS[1]}
    ${items}=    Get From Dictionary    ${tender_data.data}    items
	${procuringEntityName}=    Get From Dictionary     ${tender_data.data.procuringEntity.identifier}    legalName
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
	${guarantee_amount}=    Get From Dictionary    ${tender_data.data.guarantee}	amount
    ${dgfID}=    Get From Dictionary	 ${tender_data.data}		dgfID
	
    ${documents}=    create_fake_doc
    Wait Until Page Contains    Робочий стіл    30
    Click Element    jquery=.listviewDataItem[data-itemkey='434']
    Wait Until Page Contains		Тестові аукціони на продаж
    Click Image    jquery=.dxrControl_DevEx a[title*='(F7)'] img:eq(0)
    Wait Until Element Contains    cpModalMode    Оголошення   20
	
	Run Keyword If     '${mode}' == 'dgfOtherAssets'    Змінити процедуру
    Focus And Input     \#cpModalMode table[data-name='DTAUCTION'] input    ${auction_start}    SetTextInternal
    Focus And Input     \#cpModalMode table[data-name='INITAMOUNT'] input      ${budget}
	Run Keyword If    	${valTax}     Click Element     jquery=table[data-name='WITHVAT'] span:eq(0)
    Focus And Input     \#cpModalMode table[data-name='MINSTEP'] input     ${step_rate}
    Focus And Input     \#cpModalMode table[data-name='TITLE'] input     ${title}
    Focus And Input     \#cpModalMode table[data-name='DESCRIPT'] textarea     ${description}
    Focus And Input     \#cpModalMode table[data-name='DGFID'] input:eq(0)    ${dgfID}
	Focus And Input     \#cpModalMode div[data-name='ORG_GPO_2'] input    ${procuringEntityName}
    smarttender.Додати предмет в тендер    ${items[0]}
	
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
		
    Додати документ     ${documents}
	sleep    3s
	
    Click Image     jquery=#cpModalMode div.dxrControl_DevEx a:contains('Додати') img
	sleep    5s
    Click Image     jquery=#MainSted2Splitter .dxrControl_DevEx a[title='Надіслати вперед (Alt+Right)'] img:eq(0)
	Wait Until Page Contains    Оголосити аукціон?
	Click Element	jquery=#IMMessageBox_PW-1 #IMMessageBoxBtnYes_CD
	Wait Until Element Is Not Visible    jquery=#LoadingPanel
    sleep    20s
    ${return_value}     Get Text     jquery=div[data-placeid='TENDER'] td:Contains('UA-'):eq(0)
    [Return]     ${return_value}

Змінити процедуру
	Click Element    jquery=table[data-name='KDM2']
	sleep   3s
	Click Element    jquery=div#CustomDropDownContainer div.dxpcDropDown_DevEx table:eq(2) tr:eq(1) td:eq(0)
	
Пошук тендера по ідентифікатору
    [Arguments]    @{ARGUMENTS}
    [Documentation]    ${ARGUMENTS[0]} == username
    ...    ${ARGUMENTS[1]} == ${TENDER_UAID}
    Go To    http://test.smarttender.biz/ws/webservice.asmx/ExecuteEx?calcId=_SYNCANDMOVE&args=&ticket=&pureJson=
    Wait Until Page Contains     True    30s
	sleep    10s
    Go To    http://test.smarttender.biz/test-tenders?allcat=1
    Wait Until Page Contains    Торговий майданчик    10s
    sleep    1s
    Input Text    MainContent_MainContent_MainContent_ctl13_FilterLayout_FilterTextBox_I    ${ARGUMENTS[1]}
    sleep    1s
    ${timeout_on_wait}=    Set Variable    10
    Click Element    MainContent_MainContent_MainContent_ctl13_FilterLayout_FilterLayout_E1
    sleep    2s
    Location Should Contain    f=${ARGUMENTS[1]}
    Click Element    jquery=#tenders.table tr.head:eq(0) td:eq(0)
    sleep    1s
    Capture Page Screenshot
	${href} =     Get Element Attribute      jquery=a.button.analysis-button@href
    Click Element     jquery=a.button.analysis-button
    sleep   5s
    Select Window     url=${href}
    sleep    3s
    Select Frame      jquery=iframe:eq(0)
	
Оновити сторінку з тендером
    [Arguments]    @{ARGUMENTS}
    [Documentation]    ${ARGUMENTS[0]} = username
    ...    ${ARGUMENTS[1]} = ${TENDER_UAID}
    Selenium2Library.Switch Browser    ${ARGUMENTS[0]}
    smarttender.Пошук тендера по ідентифікатору    ${ARGUMENTS[0]}    ${ARGUMENTS[1]}

Підготуватися до редагування
	[Arguments]     ${USER}     ${TENDER_ID}
	Go To    http://test.smarttender.biz/ws/webservice.asmx/ExecuteEx?calcId=_SYNCANDMOVE&args=&ticket=&pureJson=
    Wait Until Page Contains     True     30s
	sleep    10s
    Go To    ${USERS.users['${USER}'].homepage}
	Click Element    LoginAnchor
    Sleep        5s
	Wait Until Page Contains    Робочий стіл    30
    Click Element    jquery=.listviewDataItem[data-itemkey='434']
    Wait Until Page Contains		Тестові аукціони на продаж
    sleep    3s 
    Focus    jquery=div[data-placeid='TENDER'] table.hdr tr:eq(2) td:eq(3) input:eq(0)
    sleep   1s
    Input Text      jquery=div[data-placeid='TENDER'] table.hdr tr:eq(2) td:eq(3) input:eq(0)    ${TENDER_ID}
    sleep   1s
    Press Key       jquery=div[data-placeid='TENDER'] table.hdr tr:eq(2) td:eq(3) input:eq(0)        \\13
    sleep    3s
	
Завантажити документ
    [Arguments]    @{ARGUMENTS}
	Підготуватися до редагування      ${ARGUMENTS[0]}     ${ARGUMENTS[2]}
	Click Image     jquery=.dxrControl_DevEx a[title*='(F4)'] img:eq(0)
	Wait Until Element Contains      jquery=#cpModalMode     Объявление    20
	Додати документ     ${ARGUMENTS[1]}
	Click Element       jquery=div.dxpnlControl_DevEx a[title='Сохранить'] img
	sleep     5s
	${status}=     Run Keyword And Return Status       Page Should Contain    Загрузка документации
	Run Keyword If    ${status}    Click Image     jquery=a[title='OK'] img
	[Return]      ${status}

Додати документ
	[Arguments]     ${document}
	Log    ${document}
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
	
Додати предмет в тендер
    [Arguments]    @{ARGUMENTS}
    [Documentation]    ${ARGUMENTS[0]} == item
    ${description}=    Get From Dictionary    ${ARGUMENTS[0]}     description
    ${quantity}=       Get From Dictionary    ${ARGUMENTS[0]}     quantity
    ${cpv}=            Get From Dictionary    ${ARGUMENTS[0].classification}     id
    ${unit}=           Get From Dictionary    ${ARGUMENTS[0].unit}     name
	${unit}=		   smarttender_service.convert_unit_to_smarttender_format    ${unit}
    Input Ade    \#cpModalMode div[data-name='KMAT'] input[type=text]:eq(0)      ${description}
	sleep   2s
    Focus And Input      \#cpModalMode table[data-name='QUANTITY'] input      ${quantity}
	sleep   2s
    Input Ade      \#cpModalMode div[data-name='EDI'] input[type=text]:eq(0)       ${unit}
	sleep   2s
    Focus And Input      \#cpModalMode div[data-name='IDCPV'] input[type=text]:eq(0)      ${cpv}

Внести зміни в тендер
    [Arguments]    @{ARGUMENTS}
	Підготуватися до редагування     ${ARGUMENTS[0]}     ${ARGUMENTS[1]}
	Click Image     jquery=.dxrControl_DevEx a[title*='(F4)'] img:eq(0)
	Wait Until Element Contains      jquery=#cpModalMode     Объявление    20
	sleep   1s
	Run Keyword If      '${ARGUMENTS[2]}' == 'description'     Змінити опис тендера      ${ARGUMENTS[3]} 
	sleep   1s
	Click Element       jquery=div.dxpnlControl_DevEx a[title='Сохранить'] img	

Змінити опис тендера
	[Arguments]       ${description}
	Focus       jquery=table[data-name='DESCRIPT'] textarea
	sleep    2s
	Input Text       jquery=table[data-name='DESCRIPT'] textarea      ${description}
	
Отримати інформацію із тендера
    [Arguments]    @{ARGUMENTS}
    [Documentation]    ${ARGUMENTS[0]} == username
    ...    ${ARGUMENTS[1]} == fieldname
    ${isCancellationField}=     string_contains_cancellation     '${ARGUMENTS[2]}'
    Run Keyword If    '${ARGUMENTS[2]}' == 'status' or '${isCancellationField}' == 'true'  smarttender.Оновити сторінку з тендером     @{ARGUMENTS}
    Run Keyword If     '${isCancellationField}' == 'true'   smarttender.Відкрити сторінку із данними скасування
    ${selector}=	 auction_field_info    ${ARGUMENTS[2]}
	${ret}= 		 Execute JavaScript    return (function() { return $("${selector}").text() })()
	${ret}=			 convert_result		${ARGUMENTS[2]}	   ${ret}
	[Return] 	${ret}
	
Отримати інформацію із предмету
	[Arguments]    @{ARGUMENTS}
    [Documentation]    ${ARGUMENTS[0]} == username
    ...    ${ARGUMENTS[1]} == fieldname
	${ret}=    smarttender.Отримати інформацію із тендера    ${ARGUMENTS[0]}    ${ARGUMENTS[1]}
	[Return]	${ret}

Отримати текст із поля і показати на сторінці
    [Arguments]    ${fieldname}
    sleep    2s
    ${return_value}=    Get Text    ${locator.${fieldname}}
    [Return]    ${return_value}
	
Відкрити аналіз тендера
    Sleep   2s
    ${title}=   Get Title
    Return From KeyWord If     '${title}' != 'Комерційні торги та публічні закупівлі в системі ProZorro'
    smarttender.Пошук тендера по ідентифікатору     0       ${TENDER['TENDER_UAID']}
    ${href} =     Get Element Attribute      jquery=a.button.analysis-button@href
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
	[Arguments]  ${username}  ${tender_uaid}  ${doc_id}  ${field}
    Run Keyword     smarttender.Пошук тендера по ідентифікатору     ${username}     ${tender_uaid}
    Run Keyword     smarttender.Відкрити сторінку із данними скасування
    ${selector}=     document_fields_info     ${field}
    ${result}=      Execute JavaScript    return (function() { return $("${selector}").text() })()
	[Return]    ${result}
	
Отримати посилання на аукціон для глядача
    [Arguments]    @{ARGUMENTS}
    smarttender.Пошук тендера по ідентифікатору   ${ARGUMENTS[0]}   ${ARGUMENTS[1]}
    ${href} =     Get Element Attribute      jquery=a#view-auction@href
    Click Element    jquery=a#view-auction
     sleep   10s
    Select Window     url=${href}
    Log    ${href}
    [Return]      ${href}

Отримати посилання на аукціон для учасника
    [Arguments]    @{ARGUMENTS}
    smarttender.Пошук тендера по ідентифікатору   ${ARGUMENTS[0]}   ${ARGUMENTS[1]}
    Click Link    jquery=#tenders.table tr.content:eq(0) a.auction-participate-button
    sleep    2s
	${status}=     Run Keyword And Return Status       Page Should Contain    Чи погоджуєтесь Ви з умовами проведення аукціону?
	Run Keyword If    ${status}    Click Element      jquery=button.btn-success
	Run Keyword If    ${status}    sleep     3s
    ${return_value}=    Get Location
    [return]      ${return_value}

Перейти до запитань
    [Arguments]    @{ARGUMENTS}
    [Documentation]    ${ARGUMENTS[0]} = username
    ...    ${ARGUMENTS[1]} = ${TENDER_UAID}
    Selenium2Library.Switch Browser    ${ARGUMENTS[0]}
    smarttender.Оновити сторінку з тендером    @{ARGUMENTS}

Задати питання
    [Arguments]    @{ARGUMENTS}
    [Documentation]    ${ARGUMENTS[0]} = username
    ...    ${ARGUMENTS[1]} = ${TENDER_UAID}
    ...    ${ARGUMENTS[2]} = question_data
    ${title}=    Get From Dictionary    ${ARGUMENTS[2].data}    title
    ${description}=    Get From Dictionary    ${ARGUMENTS[2].data}    description
    smarttender.Пошук тендера по ідентифікатору    ${ARGUMENTS[0]}    ${ARGUMENTS[1]}
    Click Element    jquery=a.button.questions-button
    sleep    2s
	 ${href} =    Get Element Attribute    jquery=a.button.questions-button@href
    Select Window    url=${href}
	sleep    5s
	Execute JavaScript     return (function() { var questionsIframe = $("iframe:eq(0)").get(0).contentWindow; questionsIframe.$('#question-relation').select2().val(0).trigger('change'); questionsIframe.$('input#add-question').trigger('click'); ;})()
    sleep    5s
	${status}=       Execute Javascript       return (function() { var questionsIframe = $("iframe:eq(0)").get(0).contentWindow; var questionSubmitIframe = questionsIframe.$("iframe:eq(0)").get(0).contentWindow; questionSubmitIframe.$("input[name='subject']").val("${title}"); questionSubmitIframe.$("textarea[name='question']").text("${description}"); var submitButton = questionSubmitIframe.$('div#SubmitButton__1'); if (submitButton.css('display') != 'none') { submitButton.click(); }; var status = questionSubmitIframe.$('span.dxflGroupBoxCaption_DevEx').text(); return status; })()
	Log     ${status}
	Should Not Be Equal      ${status}     Період обговорення закінчено
	${question_id}=    Execute JavaScript       return (function() {return $("span.question_idcdb").text() })()
	${question_data}=     smarttender_service.get_question_data      ${question_id}
	[Return]        ${question_data}

Відповісти на питання
    [Arguments]    @{ARGUMENTS}
	Підготуватися до редагування     ${ARGUMENTS[0]}     ${ARGUMENTS[1]}
	sleep    1s
    Click Element    jquery=#MainSted2PageControl_TENDER ul.dxtc-stripContainer li.dxtc-tab:eq(1)
	smarttender.Дочекатись розблокування інтерфейсу
    sleep    1s
    Click Element    jquery=#MainSted2PageControl_TENDER .dxtc-content > div:visible table.dxgvControl_DevEx table.dxgvTable_DevEx.dxgvRBB tr.dxgvDataRow_DevEx:visible:eq(1)
	smarttender.Дочекатись розблокування інтерфейсу
    sleep    1s
    Click Image    jquery=.dxrControl_DevEx a[title*='Изменить'] img:eq(0)
	smarttender.Дочекатись розблокування інтерфейсу
    sleep    1s
    Input Text    jquery=#cpModalMode textarea:eq(0)    ${ARGUMENTS[3]['data']['answer']}
	smarttender.Дочекатись розблокування інтерфейсу
    sleep    1s
    Click Element    jquery=#cpModalMode span.dxICheckBox_DevEx:eq(0)
	smarttender.Дочекатись розблокування інтерфейсу
    sleep    1s
    Click Image    jquery=#cpModalMode .dxrControl_DevEx .dxr-buttonItem:eq(0) img
	smarttender.Дочекатись розблокування інтерфейсу
    sleep    1s
    Click Element     jquery=#cpIMMessageBox .dxbButton_DevEx:eq(0)
	smarttender.Дочекатись розблокування інтерфейсу
    Wait Until Page Contains    Ответ отправлен на сервер ЦБД        20s

Подати цінову пропозицію
    [Arguments]    @{ARGUMENTS}
    [Documentation]    ${ARGUMENTS[0]} == username
    ...    ${ARGUMENTS[1]} == ${TENDER_UAID}
    ...    ${ARGUMENTS[2]} == ${test_bid_data}
    ${amount}=     Get From Dictionary    ${ARGUMENTS[2].data.value}      amount
    ${response}=    smarttender.Прийняти участь в тендері     ${ARGUMENTS[0]}     ${ARGUMENTS[1]}     ${amount}
    [Return]    ${response}

Змінити цінову пропозицію
    [Arguments]    @{ARGUMENTS}
    [Documentation]    ${ARGUMENTS[0]} == username
    ...    ${ARGUMENTS[1]} == ${TENDER_UAID}
    ...    ${ARGUMENTS[2]} ==  value.amount
    ...    ${ARGUMENTS[3]} ==  50000
	smarttender.Прийняти участь в тендері    ${ARGUMENTS[0]}    ${ARGUMENTS[1]}    ${ARGUMENTS[3]}
	
Прийняти участь в тендері
    [Arguments]    @{ARGUMENTS}
    [Documentation]    ${ARGUMENTS[0]} == username
    ...    ${ARGUMENTS[1]} == ${TENDER_UAID}
    ...    ${ARGUMENTS[2]} == value
    smarttender.Пошук тендера по ідентифікатору     ${ARGUMENTS[0]}     ${ARGUMENTS[1]}
	sleep    2s
	${href} =     Get Element Attribute      jquery=a#bid@href
    Click Element     jquery=a#bid
    sleep    3s
	Select Window     url=${href}
    sleep    3s
    Select Frame    jquery=iframe:eq(0)
    Wait Until Element Contains      jquery=div.title-text         Комерційна пропозиція по аукціону
	${value}=     Execute JavaScript     return (function() { var a = ${ARGUMENTS[2]}; return a.toString().replace('.',',') })()
    Focus      jquery=input[name*='fieldBidAmount'][autocomplete='off']
    sleep   2s
    Input text      jquery=input[name*='fieldBidAmount'][autocomplete='off']    ${value}
	sleep	1s
	Unselect Frame
	sleep    1s
	Select Frame      jquery=iframe#iframe
    Click Element      jquery=#btAccept
    Wait Until Keyword Succeeds    40 sec    2 sec    Current Frame Contains    Пропозицію прийнято
    ${response}=      smarttender_service.get_bid_response    ${ARGUMENTS[2]}
    [Return]    ${response}

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
    smarttender.Пошук тендера по ідентифікатору    ${ARGUMENTS[0]}    ${ARGUMENTS[2]}
    sleep    3s
	${href} =     Get Element Attribute      jquery=a#bid@href
    Click Element     jquery=a#bid
    sleep    3s
	Select Window     url=${href}
    sleep    3s
    Select Frame     jquery=iframe:eq(0)
    Wait Until Page Contains     Комерційна пропозиція по аукціону
    Choose File     jquery=input[type=file]:eq(1)    ${ARGUMENTS[1]}
    sleep    2s
    Click Element    jquery=#btAccept
    Wait Until Keyword Succeeds    15 sec    2 sec    Current Frame Contains    Пропозицію прийнято
	
Змінити документ в ставці
    [Arguments]    @{ARGUMENTS}
    smarttender.Завантажити документ в ставку     ${ARGUMENTS[0]}      ${ARGUMENTS[1]}     ${TENDER['TENDER_UAID']}
	
Підтвердити постачальника
    [Arguments]    @{ARGUMENTS}
    Pass Execution If      '${role}' == 'provider' or '${role}' == 'viewer'     Даний учасник не може підтвердити постачальника
    Підготуватися до редагування     ${ARGUMENTS[0]}      ${ARGUMENTS[1]}
    sleep    3s
    Click Element      jquery=#MainSted2TabPageHeaderLabelActive_1
    sleep    2s
    Click Element      jquery=a[data-name='F2_________TGAWARD']
    sleep    5s
    Click Element    jquery=div.dxbButton_DevEx:eq(2)
    sleep    3s
    Click Element    jquery=div#IMMessageBoxBtnYes
    sleep    10s
    Click Element      jquery=a[data-name='F2_________TGAWARD']
    sleep    3s
    Click Element    jquery=div.dxbButton_DevEx:eq(0)
    sleep    2s
    Click Element    jquery=div#IMMessageBoxBtnYes
    sleep    10s
    ${status}=     Execute JavaScript      return  (function() { return $("div[data-placeid='BIDS'] tr.rowselected td:eq(5)").text() } )()
    Should Be Equal       '${status}'	  'Визначений переможцем'
    
    
Focus And Input
    [Arguments]    ${selector}    ${value}    ${method}=SetText
    Click Element At Coordinates     jquery=${selector}    10    5
	sleep     1s
	${value}=       Convert To String     ${value}
    Input text      jquery=${selector}    ${value}

Input Ade
    [Arguments]     ${selector}     ${value}
    Click Element At Coordinates     jquery=${selector}    10    5
	sleep     1s
    Input Text    jquery=${selector}    ${value}
    Sleep    1s
    Press Key     jquery=${selector}       \\09
    Sleep    1s
	
Дочекатись розблокування інтерфейсу
	Sleep    2s
	
Підтвердити підписання контракту 
    [Arguments]    @{ARGUMENTS}
    Pass Execution If      '${role}' == 'provider' or '${role}' == 'viewer'     Даний учасник не може підписати договір
    ${documents}=    create_fake_doc
    Підготуватися до редагування    ${ARGUMENTS[0]}     ${ARGUMENTS[1]}
    sleep    1s
    Click Element	 jquery=#MainSted2TabPageHeaderLabelActive_1
    sleep     1s
    Click Element	jquery=a[data-name='F2_________TENDGOSD']:eq(0)
    sleep     2s
    Focus And Input    \.dxic input[maxlength='30']    11111111111111
    sleep    2s
    Click Element	jquery=.dxbButton_DevEx span:Contains('Обзор...'):eq(0)
    sleep     3s
    Choose File    jquery=#OpenFileUploadControl_TextBox0_Input:eq(0)     ${documents[0]}
    sleep     3s
    Click Element    jquery=span:Contains('ОК'):eq(0)
    sleep     3s
    Click Element	jquery=a[title='OK']:eq(0)
    sleep     13s
    Click Element	jquery=a[data-name='F2_________TENDGOSS']:eq(0)
    sleep    3s
    Click Element	jquery=#IMMessageBoxBtnYes_CD:eq(0)
    sleep    10s
    Click Element	jquery=#IMMessageBoxBtnOK:eq(0)
    sleep	  2s
    ${ContractState}=		Execute JavaScript		return (function(){ return $("div[data-placeid='BIDS'] tr.rowselected td:eq(6)").text();})()
    Should Be Equal     ${ContractState} 	Підписаний

Скасувати закупівлю
    [Arguments]    ${user}     ${tenderId}     ${reason}    ${file}    ${descript}
    Pass Execution If      '${role}' == 'provider' or '${role}' == 'viewer'     Даний учасник не може скасувати тендер
    ${documents}=    create_fake_doc
    Підготуватися до редагування    ${user}     ${tenderId}
    Click Element       jquery=a[data-name='F2_________GPCANCEL']
    Wait Until Page Contains    Протоколи скасування
    Focus    jquery=table[data-type='EditBox'] textarea:eq(0)   
    Input Text    jquery=table[data-type='EditBox'] textarea:eq(0)    ${reason}    
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
    Select Frame     jquery=iframe:eq(0)
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









