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

Підготувати дані для оголошення тендера користувачем
	[Arguments]   ${username}    ${tender_data}
    ${tender_data}=       adapt_data       ${tender_data}
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
    ${start_date}=    Get From Dictionary    ${tender_data.data.tenderPeriod}    startDate
    ${start_date}=    smarttender_service.convert_datetime_to_smarttender_format    ${start_date}
    ${end_date}=    Get From Dictionary    ${tender_data.data.tenderPeriod}    endDate
    ${end_date}=    smarttender_service.convert_datetime_to_smarttender_format    ${end_date}      
    ${enquiry_end_date}=       Get From Dictionary    ${tender_data.data.enquiryPeriod}    endDate
    ${enquiry_end_date}=        smarttender_service.convert_datetime_to_smarttender_format         ${enquiry_end_date}
    ${documents}=    create_fake_doc
    Wait Until Page Contains    Рабочий стол    30
    Click Element    jquery=.listviewDataItem:eq(9)
    Wait Until Element Contains    cpModalMode    Условие отбора тендеров    20
    Click Image    jquery=#cpModalMode .dxrControl_DevEx .dxr-buttonItem:eq(0) img
    sleep    5
    Click Image    jquery=.dxrControl_DevEx a[title*='(F7)'] img:eq(0)
    Wait Until Element Contains    cpModalMode    Объявление    20
  
    Focus And Input       \#cpModalMode table[data-name='DDM'] input    ${enquiry_end_date}    SetTextInternal
    Focus And Input      \#cpModalMode table[data-name='D_SCH'] input    ${start_date}    SetTextInternal
    Focus And Input       \#cpModalMode table[data-name='D_SROK'] input      ${end_date}     SetTextInternal
    Focus And Input      \#cpModalMode table[data-name='INITAMOUNT'] input      ${budget}
	Run Keyword If    ${valTax}     Click Element     jquery=table[data-name='WITHVAT'] span:eq(0)
    Focus And Input     \#cpModalMode table[data-name='MINSTEP'] input     ${step_rate}
    Focus And Input     \#cpModalMode table[data-name='TITLE'] input     ${title}
    Focus And Input     \#cpModalMode table[data-name='DESCRIPT'] textarea     ${description}    
    smarttender.Додати предмет в тендер    ${items[0]}
	
    Focus And Input     \#cpModalMode table[data-name='POSTALCODE'] input     ${postalCode}
    Focus And Input     \#cpModalMode table[data-name='STREETADDR'] input     ${streetAddress}
    Click Element     jquery=#cpModalMode div[data-name='CITY_KOD'] input[type=text]:eq(0)
	sleep    3s
	Input Text     jquery=#cpModalMode div[data-name='CITY_KOD'] input[type=text]:eq(0)        ${locality}
	sleep    2s
	Press Key        jquery=#cpModalMode div[data-name='CITY_KOD'] input[type=text]:eq(0)         \\13
	sleep    3s
	sleep  2s
	Focus And Input      \#cpModalMode table[data-name='LATITUDE'] input     ${latitude}
	Focus And Input      \#cpModalMode table[data-name='LONGITUDE'] input     ${longitude}
    Додати документ     ${documents}
	sleep    3s
    Click Image     jquery=#cpModalMode div.dxrControl_DevEx a:contains('Добавить') img
	sleep    5s
    Click Image     jquery=#MainSted2Splitter .dxrControl_DevEx span[title='Передать вперед (Alt+Right)'] img:eq(0)
	sleep    2s
    Click Element     jquery=#cpModalMode #contextMenu li:eq(0)
	sleep    10s
    ${return_value}     Get Text     jquery=#MainSted2PageControl_TENDER .dxtc-content > div:visible table.dxgvControl_DevEx table.dxgvTable_DevEx.dxgvRBB .dxgvSelectedRow_DevEx td:eq(3)
    [Return]     ${return_value}
	
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
    Input Text    MainContent_MainContent_MainContent_ctl14_FilterLayout_FilterTextBox_I    ${ARGUMENTS[1]}
    sleep    1s
    ${timeout_on_wait}=    Set Variable    10
    Click Element    MainContent_MainContent_MainContent_ctl14_FilterLayout_FilterLayout_E1
    sleep    2s
    Location Should Contain    f=${ARGUMENTS[1]}
    Click Element    jquery=#tenders.table tr.head:eq(0) td:eq(0)
    sleep    1s
    Capture Page Screenshot
	
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
	Wait Until Page Contains    Рабочий стол    20s
    Click Element    jquery=.listviewDataItem:eq(9)
    sleep    2s
    sleep    1s
    Click Image      jquery=#cpModalMode .dxrControl_DevEx .dxr-buttonItem:eq(0) img
    sleep    3s 
    Focus    jquery=.dxtc-content:eq(0) .dxgvFilterRow_DevEx:eq(0) td.dxgv:eq(3) input[type=text]
    sleep   1s
    Input Text      jquery=.dxtc-content:eq(0) .dxgvFilterRow_DevEx:eq(0) td.dxgv:eq(3) input[type=text]    ${TENDER_ID}
    sleep   1s
    Press Key       jquery=.dxtc-content:eq(0) .dxgvFilterRow_DevEx:eq(0) td.dxgv:eq(3) input[type=text]        \\13
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
	Click Element     jquery=#cpModalMode li.dxtc-tab:contains('Документы')
    sleep   2s
    Click Element     jquery=#cpModalMode .dxtlControl_DevEx label:eq(0)
    sleep   2s
    Click Element     jquery=#cpModalMode div[data-name='BTADDATTACHMENT']
	sleep   2s
    Choose File      jquery=#cpModalMode input[type=file]:eq(1)    ${document}
    sleep    2s
    Click Image      jquery=#cpModalMode div.dxrControl_DevEx a:contains('ОК') img
    sleep    2s
	
Додати предмет в тендер
    [Arguments]    @{ARGUMENTS}
    [Documentation]    ${ARGUMENTS[0]} == item
    ${items_description}=    Get From Dictionary    ${ARGUMENTS[0]}     description
    ${quantity}=     Get From Dictionary    ${ARGUMENTS[0]}     quantity
    ${cpv}=     Get From Dictionary    ${ARGUMENTS[0].classification}     id
    ${unit}=     Get From Dictionary    ${ARGUMENTS[0].unit}     name
    Input Ade    \#cpModalMode div[data-name='KMAT'] input[type=text]:eq(0)      ${items_description}
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
    Switch browser    ${ARGUMENTS[0]}
    Run Keyword And Return    Отримати інформацію про ${ARGUMENTS[1]}

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

Отримати інформацію про status
	Відкрити аналіз тендера
    ${return_value}=    Execute Javascript    return (function() { return $("span.info_tender_status").text() })()
    [Return]    ${return_value}
	
Отримати інформацію про title
    Відкрити аналіз тендера
    ${return_value}=    Execute Javascript    return (function() { return $("span.info_orderItem").text() })()
    [Return]    ${return_value}

Отримати інформацію про description
    Відкрити аналіз тендера
    ${return_value}=     Execute Javascript    return (function() { return $("span.info_info_comm2").text() })()
    [Return]    ${return_value}

Отримати інформацію про minimalStep.amount
    Відкрити аналіз тендера
    ${return_value}=    Execute JavaScript    return (function() { return parseFloat($("span.info_minstep").text().replace(",",".")) })()
    [Return]    ${return_value}

Отримати інформацію про value.amount
    Відкрити аналіз тендера
    ${return_value}=    Execute JavaScript    return (function() { return parseFloat($("span.info_budget").text().replace(",",".")) })()
    [Return]    ${return_value}
	
Отримати інформацію про value.currency
	Відкрити аналіз тендера
	${budget}=            Execute JavaScript       return (function() { return $("div.price:eq(0)").text().replace(/[0-9.]/g, "") })()
	${index}=     Execute JavaScript     return (function() { return "${budget}".indexOf('з') })()
	${hasValueTax}=     Execute JavaScript       return (function() { return "${budget}".indexOf('з') > -1 })()
	${return_value}=     Run Keyword If 
	...                         ${hasValueTax}
	...                         Execute JavaScript      return (function() { return "${budget}".replace("з ПДВ", "") })()
	...                         ELSE      Set Variable    ${budget}
	${return_value}=     smarttender_service.stripString        ${return_value}
	${return_value}=     smarttender_service.convert_currency_from_smarttender_format        ${return_value}
	[Return]      ${return_value}
	
Отримати інформацію про value.valueAddedTaxIncluded
	Відкрити аналіз тендера
	${budget}=            Execute JavaScript       return (function() { return $("div.budget div.price:eq(0)").text().replace(/[0-9.]/g, '') })()
	${hasValueTax}=     Execute JavaScript       return (function() { return "${budget}".indexOf("з") > -1 })()
	${return_value}=     Set Variable   ${hasValueTax}
	[Return]      ${return_value}
	
Отримати інформацію про auctionID
    Відкрити аналіз тендера
    ${return_value}=    Отримати текст із поля і показати на сторінці    auctionID
    [Return]    ${return_value}

Отримати інформацію про procuringEntity.name
    Відкрити аналіз тендера
    ${return_value}=    Отримати текст із поля і показати на сторінці    procuringEntity.name
    [Return]    ${return_value}

Отримати інформацію про tenderPeriod.startDate
    Відкрити аналіз тендера
	${startDate}=      Execute JavaScript    return (function() { return $("div.group-element-value:eq(2)").text() })()
	${startDate}=     smarttender_service.stripString        ${startDate}
    ${return_value}=    Execute JavaScript  return (function() { return "${startDate}".substring(2,"${startDate}".indexOf("по")-1).replace("з","") })()
	${return_value}=     smarttender_service.stripString        ${return_value}
    ${return_value}=    smarttender_service.convert_date    ${return_value}
    [Return]    ${return_value}

Отримати інформацію про tenderPeriod.endDate
    Відкрити аналіз тендера
	${startDate}=      Execute JavaScript    return (function() { return $("div.group-element-value:eq(2)").text() })()
	${startDate}=     smarttender_service.stripString        ${startDate}
    ${return_value}=    Execute JavaScript  return (function() { return "${startDate}".substring("${startDate}".indexOf("по")+3) })()
	${return_value}=     smarttender_service.stripString        ${return_value}
    ${return_value}=    smarttender_service.convert_date    ${return_value}
    [Return]    ${return_value}

Отримати інформацію про enquiryPeriod.startDate
    Відкрити аналіз тендера
	${return_value}=     Execute JavaScript    return (function() { return $("span.info_enquirysta").text() })()
    ${return_value}=    smarttender_service.convert_date    ${return_value}
    [Return]    ${return_value}

Отримати інформацію про enquiryPeriod.endDate
    Відкрити аналіз тендера
    ${return_value}=    Отримати текст із поля і показати на сторінці    enquiryPeriod.endDate
    ${return_value}=    smarttender_service.convert_date    ${return_value}
    [Return]    ${return_value}
	
Отримати інформацію про items[0].description
    Відкрити аналіз тендера
    sleep       5
    ${return_value}=    Execute JavaScript    return (function() { return $("span.info_name").text() })()
    [Return]    ${return_value}

Отримати інформацію про items[0].deliveryLocation.latitude
    Відкрити аналіз тендера
    ${return_value}=    Execute JavaScript    return (function() { return $("span.info_latitude").text().replace(/0+$/,'').replace(',','.') })()
    [Return]    ${return_value}

Отримати інформацію про items[0].deliveryLocation.longitude
    Відкрити аналіз тендера
    ${return_value}=    Execute JavaScript    return (function() { return $("span.info_longitude").text().replace(/0+$/,'').replace(',','.') })()
    [Return]    ${return_value}
    
Отримати інформацію про items[0].unit.name
    Відкрити аналіз тендера
    ${return_value}=    Execute JavaScript  return (function() { return $("span.info_snedi:eq(0)").text() })()
    [Return]    ${return_value}
    
Отримати інформацію про items[0].unit.code
    Відкрити аналіз тендера
    ${return_value}=    Execute JavaScript    return (function() { return $("span.info_edi:eq(0)").text() })()
	${return_value}=    smarttender_service.convert_edi_from_starttender_format         ${return_value}
    [Return]    ${return_value}
    
Отримати інформацію про items[0].quantity
    Відкрити аналіз тендера
    ${return_value}=    Execute JavaScript    return (function() { return parseFloat($("span.info_count").text().replace(",",".")) })()
    [Return]    ${return_value}

Отримати інформацію про items[0].classification.id
    Відкрити аналіз тендера
    ${return_value}=    Execute JavaScript    return (function() {  return $("span.info_cpv_code").text() })()
    [Return]    ${return_value}

Отримати інформацію про items[0].classification.scheme
    Відкрити аналіз тендера
    ${return_value}=    Execute JavaScript    return (function() { return $("span.info_cpv").text() })()
    [Return]    ${return_value}

Отримати інформацію про items[0].classification.description
    Відкрити аналіз тендера
    ${return_value}=    Execute JavaScript    return (function() {  return $("span.info_cpv_name").text() })()
    [Return]    ${return_value}
    
Отримати інформацію про items[0].additionalClassifications[0].id
    Відкрити аналіз тендера
    ${return_value}=    Execute JavaScript    return (function() {  return $("span.info_dkpp_code").text() })()
    [Return]    ${return_value}

Отримати інформацію про items[0].additionalClassifications[0].scheme
    Відкрити аналіз тендера
    ${return_value}=    Execute JavaScript    return (function() { return $("span.info_DKPP:eq(0)").text() })()
    [Return]    ${return_value}

Отримати інформацію про items[0].additionalClassifications[0].description
    Відкрити аналіз тендера
    ${return_value}=    Execute JavaScript    return (function() { return $("span.info_dkpp_name").text() })()
    [Return]    ${return_value}

Отримати інформацію про items[0].deliveryAddress.postalCode
    Відкрити аналіз тендера
    ${return_value}=    Execute JavaScript    return (function() { return $("span.info_postalcode:eq(0)").text() })()
    [Return]    ${return_value}

Отримати інформацію про items[0].deliveryAddress.countryName
    Відкрити аналіз тендера
    ${return_value}=    Execute JavaScript    return (function() { return $("span.info_delivery-country:eq(0)").text() })()
	${return_value}=    smarttender_service.convert_country_from_smarttender_format       ${return_value}
    [Return]    ${return_value}

Отримати інформацію про items[0].deliveryAddress.region
    Відкрити аналіз тендера
    ${return_value}=    Execute JavaScript    return (function() { return $("span.info_nobl:eq(0)").text() })()
    [Return]    ${return_value}

Отримати інформацію про items[0].deliveryAddress.locality
	Відкрити аналіз тендера
    ${return_value}=    Execute JavaScript    return (function() { return "м. "+$("span.info_city:eq(0)").text() })()
    [Return]    ${return_value}

Отримати інформацію про items[0].deliveryAddress.streetAddress
    Відкрити аналіз тендера
    ${return_value}=    Execute JavaScript    return (function() { return $("span.info_streetaddr:eq(0)").text() })()
    [Return]    ${return_value}
	
Отримати інформацію про items[0].deliveryDate.endDate
    Відкрити аналіз тендера
	${return_value}=     Execute JavaScript    return (function() { return $("span.info_date_to:eq(0)").text() })()
    ${return_value}=    smarttender_service.convert_date    ${return_value}
    [Return]    ${return_value}
	
Отримати інформацію про questions[0].title
    Click Element    jquery=a.button.questions-button
    sleep    3
    ${href} =    Get Element Attribute    jquery=a.button.questions-button@href
    Select Window    url=${href}
    Select Frame    jquery=iframe:eq(0)
	${return_value}=		Execute JavaScript	return (function() { return $("div.title-question").text().substring(0, $("div.title-question").text().indexOf("|")) })()
	${return_value}=    smarttender_service.stripString    ${return_value}
	[Return]		${return_value}

Отримати інформацію про questions[0].description
    ${ret}=    Execute JavaScript    return (function() { return $("div.q-content").text() })()
    ${stripped}=    smarttender_service.stripString    ${ret}
    log    ${stripped}
    [Return]    ${stripped}

Отримати інформацію про questions[0].date
    ${return_value}=		Execute JavaScript	return (function() { return $("div.question-relation:eq(0)").text() })()
    Log            ${return_value}
    ${return_value}=    smarttender_service.convert_date    ${return_value}
    [Return]    ${return_value}

Отримати інформацію про questions[0].answer
    Click Element    jquery=a.button.questions-button
    sleep    3
    ${href} =    Get Element Attribute    jquery=a.button.questions-button@href
    Select Window    url=${href}
    Select Frame    jquery=iframe:eq(0)
    ${ret}=    Execute JavaScript    return (function() { return $("div.answer div:eq(2)").text() })()
    log    ${ret}
    ${stripped}=    smarttender_service.stripString    ${ret}
    log    ${stripped}
	smarttender.Пошук тендера по ідентифікатору     0       ${TENDER['TENDER_UAID']}
    [Return]    ${stripped}

Отримати інформацію про bids
	Відкрити аналіз тендера
	Click Element        jquery=div#pageControlFor_Detail li:eq(4)
	${info}=    Execute JavaScript     return (function() { $("table[id*='MainTable']:eq(1) tr:eq(1) td:eq(0)").text() })()
	${info}=    smarttender_service.Strip String	   ${info}
	Log       ${info}
	${status}=    Should Not Be Equal     ${info}     Немає даних для відображення
	Log       ${status}
	[Return]   ${status}
	
Отримати посилання на аукціон для глядача
    [Arguments]    @{ARGUMENTS}
    smarttender.Пошук тендера по ідентифікатору   ${ARGUMENTS[0]}   ${ARGUMENTS[1]}
    Click Link    jquery=#tenders.table tr.content:eq(0) a.auction-button
    sleep    10s
    ${return_value}=    Get Location
    [Return]      ${return_value}

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
	Execute JavaScript     return (function() { var questionsIframe = $("iframe:eq(0)").get(0).contentWindow; questionsIframe.$('#question-relation').select2().val(0).trigger('change'); questionsIframe.$('input#add-question').trigger('click'); setTimeout(function() { var questionSubmitIframe = questionsIframe.$("iframe:eq(0)").get(0).contentWindow; questionSubmitIframe.$("input[name='subject']").val("${title}"); questionSubmitIframe.$("textarea[name='question']").text("${description}"); questionSubmitIframe.$('div#SubmitButton__1').click(); }, 5000);})()
    sleep    3s
	Page Should Not Contain      Період обговорення закінчено
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

Скасувати цінову пропозицію
    [Arguments]    @{ARGUMENTS}
    [Documentation]    ${ARGUMENTS[0]} == username
    ...    ${ARGUMENTS[1]} == ${TENDER_UAID}
    smarttender.Пошук тендера по ідентифікатору     ${ARGUMENTS[0]}     ${ARGUMENTS[1]}
    Click Element      jquery=a.button.proposal-button
    Select Frame     jquery=iframe:eq(0)
    Wait Until Page Contains      Комерційна пропозиція по аукціону
    sleep   1s
    Focus     jquery=#btCancellationOffers
    Click Element      jquery=#btCancellationOffers
    sleep    2s
    Wait Until Keyword Succeeds    10 sec    2 sec    Current Frame Contains    Пропозиція анульована

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
    Click Element     jquery=a.button.proposal-button
    sleep    5s
    Select Frame    jquery=iframe:eq(0)
    Wait Until Page Contains      Комерційна пропозиція по аукціону
    Focus      jquery=input[name*='fieldBidAmount'][autocomplete='off']
    sleep   2s
    Input text      jquery=input[name*='fieldBidAmount'][autocomplete='off']    ${ARGUMENTS[2]}
	sleep	1s
	Unselect Frame
	sleep    1s
	Select Frame      jquery=iframe#iframe
    Click Element      jquery=#btAccept
    Wait Until Keyword Succeeds    15 sec    2 sec    Current Frame Contains    Пропозицію прийнято
    ${response}=      smarttender_service.get_bid_response    ${ARGUMENTS[2]}
    [Return]    ${response}
	
Завантажити документ в ставку
    [Arguments]    @{ARGUMENTS}
    [Documentation]    ${ARGUMENTS[0]} == username
    ...    ${ARGUMENTS[1]} == path
    ...    ${ARGUMENTS[2]} == tenderid
    smarttender.Пошук тендера по ідентифікатору    ${ARGUMENTS[0]}    ${ARGUMENTS[2]}
    Click Element     jquery=a.button.proposal-button
    sleep    2s
    Select Frame     jquery=iframe:eq(0)
    Wait Until Page Contains     Комерційна пропозиція по аукціону
    Choose File     jquery=input[type=file]:eq(1)    ${ARGUMENTS[1]}
    sleep    2s
    Click Element    jquery=#btAccept
    Wait Until Keyword Succeeds    10 sec    2 sec    Current Frame Contains    Пропозицію прийнято
	
Змінити документ в ставці
    [Arguments]    @{ARGUMENTS}
    smarttender.Завантажити документ в ставку     ${ARGUMENTS[0]}      ${ARGUMENTS[1]}     ${TENDER['TENDER_UAID']}
	
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
