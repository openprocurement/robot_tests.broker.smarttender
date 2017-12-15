﻿# -*- coding: utf-8 -*-
*** Settings ***
Library           String
Library           DateTime
Library           smarttender_service.py
Library           op_robot_tests.tests_files.service_keywords
Library           Selenium2Library

*** Variables ***
${number_of_tabs}                       ${1}
${locator.auctionID}                    jquery=span.info_tendernum
${locator.procuringEntity.name}         jquery=span.info_organization
${locator.tenderPeriod.startDate}       jquery=span.info_d_sch
${locator.tenderPeriod.endDate}         jquery=span.info_d_srok
${locator.enquiryPeriod.endDate}        jquery=span.info_ddm
${locator.auctionPeriod.startDate}      jquery=span.info_dtauction
${locator.questions[0].description}     ${EMPTY}
${locator.questions[0].answer}          ${EMPTY}
${browserAlias}                         'our_browser'

${synchronization}                      http://test.smarttender.biz/ws/webservice.asmx/ExecuteEx?calcId=_SYNCANDMOVE&args=&ticket=&pureJson=
${path to find tender}                  http://test.smarttender.biz/test-tenders/
${find tender field}                    xpath=//input[@placeholder="Введіть запит для пошуку або номер тендеру"]
${tender found}                         xpath=//*[@id="tenders"]/tbody//a[@class="linkSubjTrading"]

${block}                                xpath=.//*[@class='ivu-card ivu-card-bordered']
${cancellation offers button}           ${block}[last()]//div[@class="ivu-poptip-rel"]/button
${cancel. offers confirm button}        ${block}[last()]//div[@class="ivu-poptip-footer"]/button[2]
${ok button}                            xpath=.//div[@class="ivu-modal-body"]/div[@class="ivu-modal-confirm"]//button
${owner F4}                             xpath=//*[@data-name="TBCASE____F4"]
${ok add file}                          jquery=span:Contains('ОК'):eq(0)


*** Keywords ***
####################################
#              COMMON              #
####################################

Підготувати клієнт для користувача
    [Arguments]    @{ARGUMENTS}
    [Documentation]      Відкрити браузер, створити об’єкт api wrapper, тощо
    ...    ${ARGUMENTS[0]} == username
    Open Browser    ${USERS.users['${ARGUMENTS[0]}'].homepage}    ${USERS.users['${ARGUMENTS[0]}'].browser}  alias=${browserAlias}
    Run Keyword If      '${ARGUMENTS[0]}' != 'SmartTender_Viewer'      Login      @{ARGUMENTS}

Login
    [Arguments]     @{ARGUMENTS}
    Click Element    LoginAnchor
    Input Text    jquery=.login-tb:eq(1)    ${USERS.users['${ARGUMENTS[0]}'].login}
    Input Text    jquery=.password-tb:eq(1)    ${USERS.users['${ARGUMENTS[0]}'].password}
    Click Element    jquery=.remember-cb:eq(1)
    Click Element    jquery=#sm_content .log-in a.button
    sleep    5s

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
    Switch Browser  ${browserAlias}
    Go To  ${synchronization}
    Wait Until Page Contains  True  30s
    smarttender.Пошук тендера по ідентифікатору    ${ARGUMENTS[0]}    ${ARGUMENTS[1]}

Підготуватися до редагування
    [Arguments]     ${USER}     ${TENDER_ID}
    Go To  ${synchronization}
    Wait Until Page Contains  True  30s
    sleep  1
    Go To  ${USERS.users['${USER}'].homepage}
    Click Element  LoginAnchor
    Sleep  1
    Run Keyword And Ignore Error  click element  id=IMMessageBoxBtnNo_CD
    Wait Until Page Contains element  xpath=//*[@data-itemkey='438']  10
    Click Element  xpath=//*[@data-itemkey='438']
    Wait Until Page Contains  Тестові аукціони на продаж
    sleep  3s
    Focus  jquery=div[data-placeid='TENDER'] table.hdr tr:eq(2) td:eq(3) input:eq(0)
    sleep  1s
    Input Text  jquery=div[data-placeid='TENDER'] table.hdr tr:eq(2) td:eq(3) input:eq(0)  ${TENDER_ID}
    sleep  1s
    Press Key       jquery=div[data-placeid='TENDER'] table.hdr tr:eq(2) td:eq(3) input:eq(0)        \\13
    sleep    3s

Пошук тендера по ідентифікатору
    [Arguments]    @{ARGUMENTS}
    [Documentation]    ${ARGUMENTS[0]} == username
    ...    ${ARGUMENTS[1]} == ${TENDER_UAID}
    Go To  ${path to find tender}
    Wait Until Page Contains  Торговий майданчик  60s
    Input Text  ${find tender field }  ${ARGUMENTS[1]}
    Press Key  ${find tender field }  \\13
    Location Should Contain  f=${ARGUMENTS[1]}
    Capture Page Screenshot
    ${condition}=  run keyword and return status  wait until page contains element  ${tender found}
    run keyword if  '${condition}'=='${False}'  smarttender.Пошук тендера по ідентифікатору  @{ARGUMENTS}
    ...  ELSE  find tender continue

find tender continue
    ${href}=  Get Element Attribute  ${tender found}@href
    Go To  ${href}
    Select Frame      jquery=iframe:eq(0)

Focus And Input
    [Arguments]    ${selector}    ${value}    ${method}=SetText
    sleep  2
    Click Element At Coordinates     jquery=${selector}    10    5
    sleep  1
    ${value}=       Convert To String     ${value}
    Input text      jquery=${selector}    ${value}
    sleep  2

Input Ade
    [Arguments]     ${selector}     ${value}
    sleep  2
    Click Element At Coordinates     jquery=${selector}    10    5
    sleep  1
    Input Text    jquery=${selector}    ${value}
    Sleep  1
    Press Key     jquery=${selector}       \\09
    Sleep  2

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
    log  ${ARGUMENTS[1]}
    ${tender_data}=    Set Variable    ${ARGUMENTS[1]}
    ${items}=    Get From Dictionary    ${tender_data.data}    items
    ${procuringEntityName}=    Get From Dictionary     ${tender_data.data.procuringEntity.identifier}    legalName
    ${title}=    Get From Dictionary    ${tender_data.data}    title
    ${description}=    Get From Dictionary    ${tender_data.data}    description
    ${budget}=    Get From Dictionary    ${tender_data.data.value}    amount
    ${step_rate}=    Get From Dictionary    ${tender_data.data.minimalStep}    amount
    log to console  ${step_rate}
    set global variable  ${step_rate}
    ${valTax}=     Get From Dictionary    ${tender_data.data.value}      valueAddedTaxIncluded
    ${guarantee_amount}=    Get From Dictionary    ${tender_data.data.guarantee}    amount
    ${dgfID}=    Get From Dictionary     ${tender_data.data}        dgfID
    ${minNumberOfQualifiedBids}=  Get From Dictionary    ${tender_data.data}  minNumberOfQualifiedBids
    ${auction_start}=    Get From Dictionary    ${tender_data.data.auctionPeriod}    startDate
    ${auction_start}=    smarttender_service.convert_datetime_to_smarttender_format    ${auction_start}
    ${tenderAttempts}=    Get From Dictionary    ${tender_data.data}    tenderAttempts
    Run Keyword And Ignore Error  Wait Until Page Contains element  id=IMMessageBoxBtnNo_CD  60
    sleep  1
    Run Keyword And Ignore Error  click element  id=IMMessageBoxBtnNo_CD
    Wait Until Page Contains element  xpath=//*[@data-itemkey='438']  10
    sleep  1
    Click Element  xpath=//*[@data-itemkey='438']
    Wait Until Page Contains element  xpath=.//*[@data-name="TBCASE____F7"]
    sleep  1
    Click Element  xpath=.//*[@data-name="TBCASE____F7"]
    Wait Until Element Contains    cpModalMode    Оголошення   60
    sleep  1
    Run Keyword If     '${mode}' != 'dgfOtherAssets'    Змінити процедуру
    Focus And Input     \#cpModalMode table[data-name='DTAUCTION'] input    ${auction_start}    SetTextInternal
    Focus And Input     \#cpModalMode table[data-name='INITAMOUNT'] input      ${budget}
    Run Keyword If      ${valTax}     Click Element     jquery=table[data-name='WITHVAT'] span:eq(0)
    Focus And Input     \#cpModalMode table[data-name='MINSTEP'] input     ${step_rate}
    Focus And Input     \#cpModalMode table[data-name='TITLE'] input     ${title}
    Focus And Input     \#cpModalMode table[data-name='DESCRIPT'] textarea     ${description}
    Focus And Input     \#cpModalMode table[data-name='DGFID'] input:eq(0)    ${dgfID}
    Focus And Input     \#cpModalMode div[data-name='ORG_GPO_2'] input    ${procuringEntityName}
    sleep  1
    press key  jquery=\#cpModalMode div[data-name='ORG_GPO_2'] input    \\09
    sleep  3
    press key  jquery=\#cpModalMode div[data-name='ORG_GPO_2'] input    \\13
    sleep  1
    Focus    jquery=#cpModalMode table[data-name='ATTEMPT'] input:eq(1)
    sleep  1
    Execute JavaScript    (function(){$("#cpModalMode table[data-name='ATTEMPT'] input:eq(1)").val('');})()
    sleep  1
    Input Text    jquery=#cpModalMode table[data-name='ATTEMPT'] input:eq(1)    ${tenderAttempts}
    sleep  1
    Press Key    jquery=#cpModalMode table[data-name='ATTEMPT'] input:eq(1)    \\13
    sleep  1
    run keyword if  "${minNumberOfQualifiedBids}" == '1'  run keywords
    ...  click element  xpath=//*[@data-name="PARTCOUNT"]
    ...  AND  sleep  2
    ...  AND  click element  xpath=(//td[text()="1"])[last()]
    ${index}=    Set Variable    ${0}
    log  ${items}
    :FOR    ${item}    in    @{items}
    \    log  ${index}
    \    Run Keyword If    '${index}' != '0'    Створити новий предмет
    \    smarttender.Додати предмет в тендер при створенні   ${item}
    \    ${index}=    SetVariable    ${index + 1}
    Click Element     jquery=#cpModalMode li.dxtc-tab:contains('Гарантійний внесок')
    sleep  1
    Wait Until Element Is Visible    jquery=[data-name='GUARANTEE_AMOUNT']
    Focus And Input     \#cpModalMode table[data-name='GUARANTEE_AMOUNT'] input     ${guarantee_amount}
    Click Image     jquery=#cpModalMode div.dxrControl_DevEx a:contains('Додати') img
    sleep  2
    Wait Until Element Is Not Visible    jquery=#LoadingPanel  60
    sleep  1
    click element  xpath=//*[@data-name="TBCASE____SHIFT-F12N"]
    sleep  1
    Wait Until Element Is Not Visible    jquery=#LoadingPanel  60
    Wait Until Page Contains    Оголосити аукціон?
    sleep  1
    Click Element  id=IMMessageBoxBtnYes_CD
    sleep  1
    Wait Until Element Is Not Visible    jquery=#LoadingPanel  60
    sleep    10s
    ${return_value}     Get Text     jquery=div[data-placeid='TENDER'] td:Contains('UA-'):eq(0)
    [Return]     ${return_value}

Створити новий предмет
    sleep  1
    Click Element    xpath=(//*[@title='Додати'])[2]
    sleep    1s

Змінити процедуру
    sleep  2
    run keyword and ignore error  Click Element  xpath=//*[@data-name="OWNERSHIPTYPE"]
    run keyword and ignore error  Click Element  xpath=//*[@data-name="KDM2"]
    sleep  2
    Click Element    jquery=div#CustomDropDownContainer div.dxpcDropDown_DevEx table:eq(2) tr:eq(1) td:eq(0)

Завантажити документ
    [Arguments]    @{ARGUMENTS}
    [Documentation]  ${ARGUMENTS[0]}  role
    ...  ${ARGUMENTS[1]}  path to file
    ...  ${ARGUMENTS[2]}  tenderID
    Підготуватися до редагування  ${ARGUMENTS[0]}  ${ARGUMENTS[2]}
    sleep  3
    click element  ${owner F4}
    Wait Until Page Contains  Завантаження документації  60
    Click Element  jquery=#cpModalMode li.dxtc-tab:contains('Завантаження документації')
    sleep  3
    Click Element  jquery=#cpModalMode div[data-name='BTADDATTACHMENT']
    Choose File  xpath=//*[@type='file'][1]  ${ARGUMENTS[1]}
    Click Element    ${ok add file}
    [Teardown]  Закрити вікно редагування

Додати документ
    [Arguments]     ${document}
    Log    ${document[0]}
    Click Element     jquery=#cpModalMode li.dxtc-tab:contains('Завантаження документації')
    sleep   2s
    Click Element     jquery=#cpModalMode div[data-name='BTADDATTACHMENT']
    sleep   2s
    Choose File      jquery=#cpModalMode input[type=file]:eq(1)    ${document[0]}
    sleep    2s
    Click Image      jquery=#cpModalMode div.dxrControl_DevEx a:contains('ОК') img
    sleep    2s

Додати предмет в тендер при створенні
    [Arguments]    @{ARGUMENTS}
    [Documentation]    ${ARGUMENTS[0]} == item
    ${description}=    Get From Dictionary    ${ARGUMENTS[0]}     description
    ${quantity}=       Get From Dictionary    ${ARGUMENTS[0]}     quantity
    ${cpv}=            Get From Dictionary    ${ARGUMENTS[0].classification}     id
    ${cpv/cav}=        Get From Dictionary    ${ARGUMENTS[0].classification}     scheme
    ${unit}=           Get From Dictionary    ${ARGUMENTS[0].unit}     name
    ${unit}=           smarttender_service.convert_unit_to_smarttender_format    ${unit}
    ${postalCode}    Get From Dictionary    ${ARGUMENTS[0].deliveryAddress}    postalCode
    ${locality}=    Get From Dictionary    ${ARGUMENTS[0].deliveryAddress}    locality
    ${streetAddress}    Get From Dictionary    ${ARGUMENTS[0].deliveryAddress}    streetAddress
    ${latitude}    Get From Dictionary    ${ARGUMENTS[0].deliveryLocation}    latitude
    ${longitude}    Get From Dictionary    ${ARGUMENTS[0].deliveryLocation}    longitude
    ${contractPeriodendDate}  Get From Dictionary  ${ARGUMENTS[0].contractPeriod}  endDate
    ${contractPeriodendDate}  smarttender_service.convert_datetime_to_smarttender_form  ${contractPeriodendDate}
    ${contractPeriodstartDate}  Get From Dictionary  ${ARGUMENTS[0].contractPeriod}  startDate
    ${contractPeriodstartDate}  smarttender_service.convert_datetime_to_smarttender_form  ${contractPeriodstartDate}
    Wait Until Element Is Not Visible    jquery=#LoadingPanel  60
    log to console  ${cpv/cav}
    sleep  1
    click element  xpath=//*[@data-name="MAINSCHEME"]
    sleep  1
    run keyword if  "${cpv/cav}" == "CAV"  click element  xpath=//td[text()="CAV"]
    ...  ELSE IF  "${cpv/cav}" == "CAV-PS"  click element  xpath=//td[text()="CAV"]
    ...  ELSE IF  "${cpv/cav}" == "CPV"  click element  xpath=//td[text()="CPV"]
    Input Ade    \#cpModalMode div[data-name='KMAT'] input[type=text]:eq(0)      ${description}
    Focus And Input      \#cpModalMode table[data-name='QUANTITY'] input      ${quantity}
    Input Ade      \#cpModalMode div[data-name='EDI'] input[type=text]:eq(0)       ${unit}
    sleep  1
    Input text  xpath=//*[@data-name="CONTRFROM"]//input  ${contractPeriodendDate}
    sleep  1
    click element  xpath=//*[@data-name="CONTRTO"]
    sleep  1
    Input text  xpath=//*[@data-name="CONTRTO"]//input  ${contractPeriodendDate}
    Focus And Input      \#cpModalMode div[data-name='MAINCLASSIFICATION'] input[type=text]:eq(0)      ${cpv}
    Press Key  jquery=\#cpModalMode div[data-name='MAINCLASSIFICATION'] input[type=text]:eq(0)  \\13
    Focus And Input     \#cpModalMode table[data-name='POSTALCODE'] input     ${postalCode}
    Focus And Input     \#cpModalMode table[data-name='STREETADDR'] input     ${streetAddress}
    Click Element     jquery=#cpModalMode div[data-name='CITY_KOD'] input[type=text]:eq(0)
    sleep    1s
    Input Text     jquery=#cpModalMode div[data-name='CITY_KOD'] input[type=text]:eq(0)        ${locality}
    sleep    1s
    Press Key        jquery=#cpModalMode div[data-name='CITY_KOD'] input[type=text]:eq(0)         \\13
    Focus And Input      \#cpModalMode table[data-name='LATITUDE'] input     ${latitude}
    Focus And Input      \#cpModalMode table[data-name='LONGITUDE'] input     ${longitude}

Додати предмет закупівлі
    [Arguments]    ${user}    ${tenderId}    ${item}
    ${description}=    Get From Dictionary    ${item}     description
    ${quantity}=       Get From Dictionary    ${item}     quantity
    ${cpv}=            Get From Dictionary    ${item.classification}     id
    ${unit}=           Get From Dictionary    ${item.unit}     name
    ${unit}=           smarttender_service.convert_unit_to_smarttender_format    ${unit}
    smarttender.Підготуватися до редагування     ${user}    ${tenderId}
    sleep  3
    click element  ${owner F4}
    Wait Until Element Contains      jquery=#cpModalMode     Коригування    60
    Page Should Not Contain Element    jquery=#cpModalMode div.gridViewAndStatusContainer a[title='Додати']
    [Teardown]      Закрити вікно редагування

Видалити предмет закупівлі
    [Arguments]    ${user}    ${tenderId}    ${itemId}
    ${readyToEdit} =  Execute JavaScript  return(function(){return ((window.location.href).indexOf('webclient') !== -1).toString();})()
    Run Keyword If     '${readyToEdit}' != 'true'    Підготуватися до редагування     ${user}    ${tenderId}
    sleep  3
    click element  ${owner F4}
    Wait Until Element Contains      jquery=#cpModalMode     Коригування    60
    Page Should Not Contain Element     jquery=#cpModalMode a[title='Удалить']
    [Teardown]      Закрити вікно редагування

Внести зміни в тендер
    [Arguments]    @{ARGUMENTS}
    Pass Execution If  '${role}'=='provider' or '${role}'=='viewer'  Данний користувач не може вносити зміни в аукціон
    smarttender.Підготуватися до редагування  ${ARGUMENTS[0]}  ${ARGUMENTS[1]}
    sleep  3
    click element  ${owner F4}
    Wait Until Element Contains  jquery=#cpModalMode  Коригування  60
    log to console  ${ARGUMENTS[3]}
    ${converted_Arg3}=  convert to string  ${ARGUMENTS[3]}
    ${selector}=  auction_screen_field_selector       ${ARGUMENTS[2]}
    run keyword if
    ...  '${ARGUMENTS[2]}' == 'guarantee.amount'  run keywords
    ...     Click Element  jquery=#cpModalMode li.dxtc-tab:contains('Гарантійний внесок')
    ...     AND  sleep  3
    ...     AND  Focus And Input  \#cpModalMode table[data-name='GUARANTEE_AMOUNT'] input  ${converted_Arg3}
    ...     AND  Press Key  jquery=\#cpModalMode table[data-name='GUARANTEE_AMOUNT'] input  \\13
    ...  ELSE IF  '${ARGUMENTS[2]}' == 'value.amount'  run keywords
    ...     Input Text  jquery=${selector}  ${converted_Arg3}
    ...     AND  Press Key  jquery=${selector}  \\13
    ...     AND  Focus And Input  \#cpModalMode table[data-name='MINSTEP'] input  ${step_rate}
    ...  ELSE IF  '${ARGUMENTS[2]}' == 'minimalStep.amount'  run keywords
    ...     Input Text  jquery=${selector}  ${converted_Arg3}
    ...     AND  click element  xpath=//*[@data-name="CONTRTO"]
    ...  ELSE  run keywors
    ...     Input Text  jquery=${selector}  ${converted_Arg3}
    [Teardown]  Закрити вікно редагування

Закрити вікно редагування
    sleep  3
    Click Element       jquery=div.dxpnlControl_DevEx a[title='Зберегти'] img
    Run Keyword And Ignore Error      Закрити вікно з помилкою
    sleep  2

Закрити вікно з помилкою
    sleep  1
    Run Keyword And Ignore Error  Wait Until Page Contains    PROZORRO
    sleep  1
    Run Keyword And Ignore Error  Click Element    jquery=#IMMessageBoxBtnOK:eq(0)
    sleep  1
    Run Keyword And Ignore Error  Wait Until Page Contains    xpath=//*[@id="cpModalMode"]//*[text()='Записать']
    sleep  1
    Run Keyword And Ignore Error  Click Element    xpath=//*[@id="cpModalMode"]//*[text()='Записать']
    sleep  1
    [Return]

Змінити опис тендера
    [Arguments]       ${description}
    Focus       jquery=table[data-name='DESCRIPT'] textarea
    sleep    2s
    Input Text       jquery=table[data-name='DESCRIPT'] textarea      ${description}

Отримати інформацію із тендера
    [Arguments]    @{ARGUMENTS}
    [Documentation]    ${ARGUMENTS[0]} == username
    ...    ${ARGUMENTS[1]} == fieldname
    log  ${ARGUMENTS[0]}
    log  ${ARGUMENTS[1]}
    log  ${ARGUMENTS[2]}
    ${isCancellationField}=     string_contains     ${ARGUMENTS[2]}    cancellation
    ${isQuestionField}=     string_contains     ${ARGUMENTS[2]}    questions
    ${isDataAuctionStart}=      string_contains     ${ARGUMENTS[2]}    auctionPeriod.startDate 
    Run Keyword If    '${ARGUMENTS[2]}' == 'status' or '${isCancellationField}' == 'true' or '${isDataAuctionStart}' == 'true'
    ...     smarttender.Оновити сторінку з тендером     @{ARGUMENTS}
    Run Keyword If     '${isCancellationField}' == 'true'   smarttender.Відкрити сторінку із данними скасування
    Run Keyword If    '${isQuestionField}' == 'true'    smarttender.Відкрити сторінку із даними запитань
    ${selector}=  auction_field_info  ${ARGUMENTS[2]}
    ${ret}=  Execute JavaScript  return (function() { return $("${selector}").text() })()
    ${ret}=  convert_result  ${ARGUMENTS[2]}  ${ret}
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
    [Arguments]  ${user}  ${tenderId}  ${objectId}  ${field}
    log  ${objectId}
    log  ${field}
    ${selector}=  question_field_info  ${field}  ${objectId}
    Run Keyword And Ignore Error     smarttender.Відкрити сторінку із даними запитань
    ${ret}=  Execute JavaScript  return (function() { return $("${selector}").text() })()
    [Return]    ${ret}

Відкрити аналіз тендера
    Sleep   2s
    ${title}=   Get Title
    Return From KeyWord If     '${title}' != 'Комерційні торги та публічні закупівлі в системі ProZorro'
    smarttender.Пошук тендера по ідентифікатору     0       ${TENDER['TENDER_UAID']}
    ${href} =     Get Element Attribute    jquery=a.button.analysis-button@href
    go to  ${href}
    sleep    3s
    Select Frame      jquery=iframe:eq(0)

Відкрити скарги тендера
    [Arguments]     ${username}
    sleep   3s
    smarttender.Пошук тендера по ідентифікатору     ${username}       ${TENDER['TENDER_UAID']}
    ${href} =     Get Element Attribute      jquery=a.compliant-button@href
    go to  ${href}
    sleep    3s
    Select Frame      jquery=iframe:eq(0)

Отримати інформацію із документа
    [Arguments]    ${username}  ${tender_uaid}  ${doc_id}  ${field}
    log  ${field}
    log  ${doc_id}
    Run Keyword     smarttender.Пошук тендера по ідентифікатору     ${username}     ${tender_uaid}
    ${isCancellation}=    Set Variable If    '${TEST NAME}' == 'Відображення опису документа до скасування лоту' or '${TEST NAME}' == 'Відображення заголовку документа до скасування лоту' or '${TEST NAME}' == 'Відображення вмісту документа до скасування лоту'   True    False
    Run Keyword If       ${isCancellation} == True     smarttender.Відкрити сторінку із данними скасування
    ${selector}=  run keyword if  '${TEST NAME}' == 'Відображення заголовку документа до скасування лоту'
    ...     document_fields_info     title1    ${doc_id}   ${isCancellation}
    ...  ELSE
    ...     document_fields_info     ${field}    ${doc_id}   ${isCancellation}
    ${result}=      Execute JavaScript    return (function() { return $("${selector}").text() })()
    [Return]    ${result}

Перейти до запитань
    [Arguments]    @{ARGUMENTS}
    [Documentation]    ${ARGUMENTS[0]} = username
    ...    ${ARGUMENTS[1]} = ${TENDER_UAID}
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
    Execute JavaScript  return (function() { $('#question-relation').select2().val(0).trigger('change'); $('input#add-question').trigger('click');})()
    sleep    5s
    Select Frame      jquery=iframe:eq(0)
    input text  id=subject  ${title}
    input text  id=question  ${description}
    click element  xpath=//button
    sleep  10
    ${status}=  get text  xpath=//*[@class='ivu-alert-message']/span
    Log     ${status}
    Should Not Be Equal  ${status}  Період обговорення закінчено
    reload page
    select frame      jquery=iframe:eq(0)
    ${question_id}=  Execute JavaScript  return (function() {return $("span.question_idcdb").text() })()
    ${question_data}=  smarttender_service.get_question_data  ${question_id}
    [Return]  ${question_data}

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
    Select Frame      jquery=iframe:eq(0)
    input text  id=subject  ${title}
    input text  id=question  ${description}
    click element  xpath=//button
    sleep  10
    ${status}=  get text  xpath=//*[@class='ivu-alert-message']/span
    Log     ${status}
    Should Not Be Equal      ${status}     Період обговорення закінчено
    reload page
    select frame      jquery=iframe:eq(0)
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
    Wait Until Element Is Not Visible    jquery=#LoadingPanel  60
    sleep  1
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
    Wait Until Page Contains    Відповідь надіслана на сервер ЦБД        60s

Подати цінову пропозицію
    [Arguments]    @{ARGUMENTS}
    [Documentation]    ${ARGUMENTS[0]} == username
    ...    ${ARGUMENTS[1]} == ${TENDER_UAID}
    ...    ${ARGUMENTS[2]} == ${test_bid_data}
    smarttender.Пройти кваліфікацію для подачі пропозиції       ${ARGUMENTS[0]}     ${ARGUMENTS[1]}     ${ARGUMENTS[2]}
    Log     ${mode}
    ${response}=  Run Keyword If    '${mode}' == 'dgfInsider'   
    ...     smarttender.Прийняти участь в тендері dgfInsider  ${ARGUMENTS[0]}     ${ARGUMENTS[1]}       ${ARGUMENTS[2]}
    ...    ELSE        
    ...     smarttender.Прийняти участь в тендері     ${ARGUMENTS[0]}     ${ARGUMENTS[1]}     ${ARGUMENTS[2]}
    [Return]    ${response}

Пройти кваліфікацію для подачі пропозиції
    [Arguments]    ${user}    ${tenderId}    ${bid}
    ${temp}=    Get Variable Value    ${bid['data'].qualified}
    ${shouldQualify}=    convert_bool_to_text    ${temp}
    Return From Keyword If     '${shouldQualify}' == 'false'
    Run Keyword     smarttender.Пошук тендера по ідентифікатору       ${user}    ${tenderId}
    Wait Until Page Contains Element  jquery=a#participate  10s
    ${lotId}=    Execute JavaScript    return(function(){return $("span.info_lotId").text()})()
    Click Element     jquery=a#participate
    Wait Until Page Contains Element  jquery=iframe#widgetIframe:eq(1)  60s
    Select Frame      jquery=iframe#widgetIframe:eq(1)
    Wait Until Page Contains Element  xpath=.//*[@class="ivu-form-item ivu-form-item-required"][1]//input  60
    input text  xpath=.//*[@class="ivu-form-item ivu-form-item-required"][1]//input  Іван
    sleep    1s
    input text  xpath=.//*[@class="ivu-form-item ivu-form-item-required"][2]//input  Іванов
    sleep    1s
    input text  xpath=.//*[@class="ivu-form-item"][2]//input  Іванович
    sleep    1s
    input text  xpath=.//*[@class="ivu-form-item ivu-form-item-required"][3]//input  +38011111111
    sleep    1s
    ${file_path}  ${file_name}  ${file_content}=  create_fake_doc
    Run Keyword And Ignore Error    smarttender.Додати документ до кваліфікації    jquery=input#GUARAN    ${file_path}
    Run Keyword And Ignore Error    smarttender.Додати документ до кваліфікації    jquery=input#FIN    ${file_path}
    Run Keyword And Ignore Error    smarttender.Додати документ до кваліфікації    jquery=input#NOTDEP    ${file_path}
    Run Keyword And Ignore Error    smarttender.Додати документ до кваліфікації    xpath=//input[@type="file"]    ${file_path}
    click element  xpath=//*[@class="group-line"]//input
    click element  xpath=//button[@class="ivu-btn ivu-btn-primary pull-right ivu-btn-large"]
    Unselect Frame
    sleep    5s
    Go To    http://test.smarttender.biz/ws/webservice.asmx/ExecuteEx?calcId=_QA.ACCEPTAUCTIONBIDREQUEST&args={"IDLOT":"${lotId}","SUCCESS":"true"}&ticket=
    Wait Until Page Contains     True

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
    [Documentation]  ...
    ${value}=  convert_bool_to_text  ${ARGUMENTS[3]}
    ${href}=  Get Element Attribute  jquery=a#bid@href
    go to  ${href}
    Focus  jquery=div#lotAmount0 input
    sleep  2s
    Input text  jquery=div#lotAmount0 input  ${value}
    Click Element  jquery=button#submitBidPlease
    run keyword and ignore error  Wait Until Page Contains  Пропозицію прийнято  60s
    ${response}=  smarttender_service.get_bid_response    ${value}
    reload page
    [Return]  ${response}

Прийняти участь в тендері
    [Arguments]    @{ARGUMENTS}
    [Documentation]    ${ARGUMENTS[0]} == username
    ...    ${ARGUMENTS[1]} == ${TENDER_UAID}
    ...    ${ARGUMENTS[2]} ==  ${test_bid_data}
    log  ${ARGUMENTS[2]}
    log to console  ${ARGUMENTS[2]}
    log  ${ARGUMENTS[2].data.value}
    log to console  ${ARGUMENTS[2].data.value}
    ${amount}=  Get From Dictionary  ${ARGUMENTS[2].data.value}  amount
    ${amount}=  convert to string  ${amount}
    log to console  ${amount}
    smarttender.Пошук тендера по ідентифікатору  ${ARGUMENTS[0]}  ${ARGUMENTS[1]}
    sleep  2s
    Wait Until Page Contains Element        jquery=a#bid    60s
    ${href}=  Get Element Attribute  jquery=a#bid@href
    go to  ${href}
    sleep    3s
    Wait Until Page Contains       Пропозиція по аукціону
    sleep    2s
    Focus      jquery=div#lotAmount0 input
    sleep   2s
    Input text      jquery=div#lotAmount0 input    ${amount}
    sleep    1s
    Click Element      jquery=button#submitBidPlease
    Wait Until Page Contains       Пропозицію прийнято      60s
    ${response}=      smarttender_service.get_bid_response    ${${amount}}
    [Return]    ${response}

Прийняти участь в тендері dgfInsider
    [Arguments]    @{ARGUMENTS}
    [Documentation]    ${ARGUMENTS[0]} == username
    ...    ${ARGUMENTS[1]} == ${TENDER_UAID}
    ...    ${ARGUMENTS[2]} == bid_info
    smarttender.Пошук тендера по ідентифікатору      ${ARGUMENTS[0]}     ${ARGUMENTS[1]}
    Wait Until Page Contains Element        jquery=a#bid    60s
    ${href} =     Get Element Attribute      jquery=a#bid@href
    go to  ${href}
    Wait Until Page Contains       Пропозиція по аукціону   60s
    Wait Until Page Contains Element        jquery=button#submitBidPlease    60s
    Click Element      jquery=button#submitBidPlease
    Wait Until Page Contains Element        jquery=button:contains('Так')    60s
    Click Element      jquery=button:contains('Так')
    Wait Until Page Contains       Пропозицію прийнято      60s
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
    smarttender.Пошук тендера по ідентифікатору    ${ARGUMENTS[0]}    ${ARGUMENTS[2]}
    Wait Until Page Contains Element        jquery=a#bid    60s
    ${href} =     Get Element Attribute      jquery=a#bid@href
    go to  ${href}
    Wait Until Page Contains       Пропозиція   10s
    Wait Until Page Contains Element        jquery=button:contains('Обрати файли')    60s
    Choose File     jquery=button:contains('Обрати файли')    ${ARGUMENTS[1]}
    Click Element      jquery=button#submitBidPlease
    Wait Until Page Contains Element        jquery=button:contains('Так')    60s
    Click Element      jquery=button:contains('Так')
    Wait Until Page Contains       Пропозицію прийнято      60s

Змінити документ в ставці
    [Arguments]    @{ARGUMENTS}
    smarttender.Завантажити документ в ставку     ${ARGUMENTS[0]}      ${ARGUMENTS[2]}     ${TENDER['TENDER_UAID']}

Відкрити сторінку із даними запитань
    ${alreadyOpened}=    Execute JavaScript    return(function(){ ((window.location.href).indexOf('discuss') !== -1).toString();})()
    Return From Keyword If  '${alreadyOpened}' == 'true'
    sleep  3
    ${href}=  Get Element Attribute  jquery=a#question:eq(0)@href
    Go to  ${href}
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
    [Documentation]  ${ARGUMENTS[0]}  role
    ...  ${ARGUMENTS[1]}  tenderID
    ...  ${ARGUMENTS[2]}  path to file
    Pass Execution If      '${role}' == 'provider' or '${role}' == 'viewer'     Даний учасник не може завантажити ілюстрацію
    Підготуватися до редагування    ${ARGUMENTS[0]}     ${ARGUMENTS[1]}
    sleep  3
    click element  ${owner F4}
    Wait Until Page Contains    Завантаження документації  60
    Click Element  jquery=#cpModalMode li.dxtc-tab:contains('Завантаження документації')
    sleep  3
    Click Element  jquery=#cpModalMode div[data-name='BTADDATTACHMENT']
    sleep  1
    Choose File  xpath=//*[@type='file'][1]  ${ARGUMENTS[2]}
    sleep  1
    Click Element    ${ok add file}
    sleep  5
    click element  xpath=(//*[text()="Інший тип"])[last()-1]
    sleep  3
    click element  xpath=(//*[text()="Інший тип"])[last()-1]
    sleep  3
    click element  xpath=(//*[text()="Ілюстрація"])[2]
    sleep  1
    [Teardown]  Закрити вікно редагування

Додати Virtual Data Room
    [Arguments]    ${user}    ${tenderId}     ${link}
    Pass Execution If      '${role}' == 'provider' or '${role}' == 'viewer'     Даний учасник не може завантажити ілюстрацію
    Підготуватися до редагування    ${user}     ${tenderId}
    sleep  3
    click element  ${owner F4}
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
    sleep  3
    click element  ${owner F4}
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
    sleep  3
    click element  ${owner F4}
    Wait Until Page Contains    Завантаження документації  60
    Click Element  jquery=#cpModalMode li.dxtc-tab:contains('Завантаження документації')
    sleep  3
    input text  xpath=(//*[@data-type="EditBox"])[last()]//textarea  ${description}
    sleep  1
    [Teardown]  Закрити вікно редагування

Завантажити документ в тендер з типом
    [Arguments]    ${user}    ${tenderId}    ${file_path}    ${doc_type}
    Pass Execution If      '${role}' == 'provider' or '${role}' == 'viewer'     Даний учасник не може завантажити документ в тендер
    Підготуватися до редагування    ${user}    ${tenderId}
    sleep  3
    click element  ${owner F4}
    Wait Until Page Contains    Завантаження документації  60
    Click Element  jquery=#cpModalMode li.dxtc-tab:contains('Завантаження документації')
    sleep  3
    Click Element  jquery=#cpModalMode div[data-name='BTADDATTACHMENT']
    sleep  1
    Choose File  xpath=//*[@type='file'][1]  ${file_path}
    sleep  1
    Click Element    ${ok add file}
    sleep  5
    ${documentTypeNormalized}=    map_to_smarttender_document_type    ${doc_type}
    click element  xpath=(//*[text()="Інший тип"])[last()-1]
    sleep  3
    click element  xpath=(//*[text()="Інший тип"])[last()-1]
    sleep  3
    click element  xpath=(//*[text()="${documentTypeNormalized}"])[2]
    Capture Page Screenshot
    sleep  1
    [Teardown]  Закрити вікно редагування

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
    sleep  1
    Focus    jquery=#cpModalMode table[data-name='reason'] input:eq(1)
    Execute JavaScript    (function(){$("#cpModalMode table[data-name='reason'] input:eq(1)").val('');})()
    sleep  1
    Input Text    jquery=#cpModalMode table[data-name='reason'] input:eq(1)    ${reason}
    sleep  1
    Press Key        jquery=#cpModalMode table[data-name='reason'] input:eq(1)         \\13
    click element  xpath=//div[@title="Додати"]
    sleep  1
    Choose File  id=fileUpload  ${file}
    sleep  1
    Click Element    xpath=//*[@class="dxr-group mygroup"][1]
    sleep  1
    click element  xpath=.//*[@data-type="TreeView"]//tbody/tr[2]
    sleep  1
    click element  xpath=.//*[@data-type="TreeView"]//tbody/tr[2]
    sleep  1
    Focus    jquery=table[data-name='DocumentDescription'] input:eq(0)
    sleep  1
    Input Text    jquery=table[data-name='DocumentDescription'] input:eq(0)    ${descript}
    sleep  1
    Press Key  jquery=table[data-name='DocumentDescription'] input:eq(0)  \\13
    sleep  1
    Click Element  jquery=a[title='OK']
    Wait Until Page Contains    аукціон буде
    Click Element    jquery=#IMMessageBoxBtnYes
    sleep   3s

Скасувати цінову пропозицію
    [Arguments]    @{ARGUMENTS}
    [Documentation]    ${ARGUMENTS[0]} == username
    ...    ${ARGUMENTS[1]} == ${TENDER_UAID}
    smarttender.Пошук тендера по ідентифікатору     ${ARGUMENTS[0]}     ${ARGUMENTS[1]}
    ${href} =     Get Element Attribute      jquery=a:Contains('Подати пропозицію')@href
    go to  ${href}
    sleep     3s
    wait until page contains element  ${cancellation offers button}
    Cancellation offer continue

Cancellation offer continue
    run keyword and ignore error  click element  ${cancellation offers button}
    run keyword and ignore error  click element  ${cancel. offers confirm button}
    ${passed}=  run keyword and return status  wait until page contains element  ${ok button}  60
    Run keyword if  '${passed}'=='${False}'  Cancellation offer continue
    run keyword and ignore error  click element   ${ok button}
    ${passed}=  run keyword and return status  wait until page does not contain element   ${ok button}
    Run keyword if  '${passed}'=='${False}'  Cancellation offer continue

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
    smarttender.Пошук тендера по ідентифікатору   ${ARGUMENTS[0]}   ${ARGUMENTS[1]}
    ${href} =     Get Element Attribute      jquery=a#view-auction@href
    Log    ${href}
    [Return]      ${href}

Отримати посилання на аукціон для учасника
    [Arguments]    @{ARGUMENTS}
    smarttender.Пошук тендера по ідентифікатору   ${ARGUMENTS[0]}   ${ARGUMENTS[1]}
    Wait Until Page Contains Element        jquery=a#to-auction  60s
    Click Element    jquery=a#to-auction
    Wait Until Page Contains Element        jquery=iframe#widgetIframe  60s
    Select Frame    jquery=iframe#widgetIframe
    Wait Until Page Contains Element        jquery=a.link-button:eq(0)  60s
    ${return_value}=    Get Element Attribute     jquery=a.link-button:eq(0)@href
    [return]      ${return_value}

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
    Wait Until Page Contains    Вкладення до пропозиції  60s
    sleep   3s
    click element  xpath=//*[@data-name="OkButton"]

Отримати кількість документів в ставці
    [Arguments]    ${user}     ${tenderId}    ${bidIndex}
    Run Keyword    smarttender.Підготуватися до редагування    ${user}    ${tenderId}
    Click Element     jquery=#MainSted2TabPageHeaderLabelActive_1
    sleep     1s
    ${normalizedIndex}=     normalize_index    ${bidIndex}     1
    Click Element    jquery=div[data-placeid='BIDS'] div.objbox.selectable.objbox-scrollable table tbody tr:eq(${normalizedIndex}) td:eq(2)
    Wait Until Page Contains    Вкладення до пропозиції  60s
    sleep   6s
    ${count}=     Execute JavaScript    return(function(){ var counter = 0;var documentSelector = $("#cpModalMode tr label:contains('Кваліфікація')").closest("tr");while (true) { documentSelector = documentSelector.next(); if(documentSelector.length == 0 || documentSelector[0].innerHTML.indexOf("label") === -1){ break;} counter = counter +1;} return counter;})()
    [Return]    ${count}

Підтвердити постачальника
    [Arguments]    @{ARGUMENTS}
    Pass Execution If      '${role}' == 'provider' or '${role}' == 'viewer'     Даний учасник не може підтвердити постачальника
    Підготуватися до редагування     ${ARGUMENTS[0]}      ${ARGUMENTS[1]}
    sleep    3s
    Click Element      jquery=#MainSted2TabPageHeaderLabelActive_1
    sleep    1s
    ${normalizedIndex}=     normalize_index    ${ARGUMENTS[2]}     1
    Click Element    jquery=div[data-placeid='BIDS'] div.objbox.selectable.objbox-scrollable table tbody tr:eq(${normalizedIndex}) td:eq(1)
    sleep    2s
    Click Element      jquery=a[title='Кваліфікація']
    sleep    5s
    Click Element    jquery=div.dxbButton_DevEx:contains('Підтвердити оплату')
    sleep    3s
    Click Element    jquery=div#IMMessageBoxBtnYes
    sleep    10s
    ${status}=     Execute JavaScript      return  (function() { return $("div[data-placeid='BIDS'] tr.rowselected td:eq(5)").text() } )()
    Should Be Equal       '${status}'      'Визначений переможцем'

Отримати дані із документу пропозиції
    [Arguments]    ${user}    ${tenderId}    ${bid_index}    ${document_index}    ${field}
    Run Keyword    smarttender.Підготуватися до редагування    ${user}    ${tenderId}
    Click Element     jquery=#MainSted2TabPageHeaderLabelActive_1
    sleep     1s
    ${normalizedIndex}=     normalize_index    ${bid_index}     1
    Click Element    jquery=div[data-placeid='BIDS'] div.objbox.selectable.objbox-scrollable table tbody tr:eq(${normalizedIndex}) td:eq(2)
    Wait Until Page Contains    Вкладення до пропозиції  60s
    ${selectedType}=     Execute JavaScript    return(function(){ var startElement = $("#cpModalMode tr label:contains('Квалификации')"); var documentSelector = $(startElement).closest("tr").next(); if(${document_index} > 0){ for (i=0;i<=${document_index};i++) {documentSelector = $(documentSelector).next();}}if($(documentSelector).length == 0) {return "";} return "auctionProtocol";})()
    [Return]    ${selectedType}

Скасування рішення кваліфікаційної комісії
    [Arguments]    ${user}    ${tenderId}    ${index}
    Pass Execution If      '${role}' == 'provider' or '${role}' == 'tender_owner'   Доступно тільки для другого учасника
    Go To  ${synchronization}
    Wait Until Page Contains  True  30s
    Run Keyword    smarttender.Пошук тендера по ідентифікатору    ${user}    ${tenderId}
    Sleep    4s
    Click Element    jquery=div#auctionResults div.row.well:eq(${index}) div.btn.withdraw:eq(0)
    Sleep    7s
    Select Frame    jquery=iframe#cancelPropositionFrame
    Sleep    2s
    Click Element    jquery=#firstYes
    sleep    2s
    Click Element    jquery=#secondYes
    Sleep    10s

Дискваліфікувати постачальника
    [Arguments]    ${user}    ${tenderId}    ${index}    ${description}
    Підготуватися до редагування     ${user}      ${tenderId}
    sleep    3s
    Click Element      jquery=#MainSted2TabPageHeaderLabelActive_1
    sleep    1s
    ${normalizedIndex}=     normalize_index    ${index}     1
    Click Element    jquery=div[data-placeid='BIDS'] div.objbox.selectable.objbox-scrollable table tbody tr:eq(${normalizedIndex}) td:eq(1)
    sleep    2s
    click element  xpath=//a[@title="Кваліфікація"]
    sleep    5s
    Click Element    jquery=div.dxbButton_DevEx.dxbButtonSys.dxbTSys span:contains('Відхилити пропозицію')
    sleep  3
    click element  id=IMMessageBoxBtnNo_CD
    Focus    jquery=#cpModalMode textarea
    Input Text    jquery=#cpModalMode textarea    ${description}
    click element  xpath=//span[text()="Зберегти"]
    sleep  1
    click element  id=IMMessageBoxBtnYes_CD
    sleep    10s

Завантажити протокол аукціону
    [Arguments]    ${user}    ${tenderId}    ${filePath}    ${index}
    Run Keyword    smarttender.Пошук тендера по ідентифікатору    ${user}    ${tenderId}
    ${href}=    Get Element Attribute    jquery=div#auctionResults div.row.well:eq(${index}) a.btn.btn-primary@href
    Go To      ${href}
    sleep    7s
    Click Element    jquery=a.attachment-button:eq(0)
    ${hrefQualification}=    Get Element Attribute    jquery=a.attachment-button:eq(0)@href
    go to  ${hrefQualification}
    sleep    10s
    Choose File    jquery=input[name='fieldUploaderTender_TextBox0_Input']:eq(0)    ${filePath}
    sleep    1s
    Click Element    jquery=div#SubmitButton__1_CD
    sleep    10s
    Page Should Contain     Кваліфікаційні документи відправлені

Завантажити протокол аукціону в авард
    [Arguments]    ${username}    ${tender_uaid}    ${filepath}    ${award_index}
    smarttender.Завантажити документ рішення кваліфікаційної комісії    ${username}    ${filepath}    ${tender_uaid}     ${award_index}
    Sleep    2
    Click Element    jquery=div.dxbButton_DevEx:eq(2)
    sleep  5
    Click element  xpath=//span[text()="Зберегти"]
    sleep  2
    click element  id=IMMessageBoxBtnYes_CD

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
    Click Element    xpath=//span[text()='Перегляд...']
    sleep  2
    Choose File  xpath=//*[@type='file'][1]  ${filePath}
    sleep     3s
    Click Element    ${ok add file}
    sleep     5s

####################################
#         CONTRACT SIGNING         #
####################################

Завантажити угоду до тендера
    [Arguments]    @{ARGUMENTS}
    [DOCUMENTATION]  ${ARGUMENTS[0]}  role
    ...  ${ARGUMENTS[1]}  tenderID
    ...  ${ARGUMENTS[2]}  contract_number
    ...  ${ARGUMENTS[3]}  file path
    Run Keyword    smarttender.Підготуватися до редагування      ${ARGUMENTS[0]}    ${ARGUMENTS[1]}
    sleep    1s
    Click Element     jquery=#MainSted2TabPageHeaderLabelActive_1
    sleep    1s
    Click Element    jquery=div[data-placeid='BIDS'] div.objbox.selectable.objbox-scrollable table tbody tr:contains('Визначений переможцем') td:eq(1)
    sleep     2s
    Click Element    jquery=a[title='Прикріпити договір']:eq(0)
    Wait Until Page Contains    Вкладення договірних документів
    sleep    2s
    Focus     jquery=td.dxic input[maxlength='30']
    Input Text    jquery=td.dxic input[maxlength='30']    11111111111111
    sleep    1s
    click element  xpath=//span[text()="Перегляд..."]
    sleep  1
    Choose File  xpath=//*[@type='file'][1]  ${ARGUMENTS[3]}
    sleep  1
    Click Element    ${ok add file}
    sleep  1
    Click Element    jquery=a[title='OK']:eq(0)
    Wait Until Element Is Not Visible    jquery=#LoadingPanel  60
    sleep  1

Підтвердити підписання контракту
    [Arguments]    @{ARGUMENTS}
    [DOCUMENTATION]  ${ARGUMENTS[0]}  role
    ...  ${ARGUMENTS[1]}  tenderID
    ...  ${ARGUMENTS[2]}  contract_number
    smarttender.Підготуватися до редагування    ${ARGUMENTS[0]}     ${ARGUMENTS[1]}
    sleep    1s
    Click Element    jquery=div[data-placeid='BIDS'] div.objbox.selectable.objbox-scrollable table tbody tr:contains('Визначений переможцем') td:eq(1)
    sleep     2s
    Click Element    jquery=a[title='Підписати договір']:eq(0)
    sleep    3s
    Click Element    jquery=#IMMessageBoxBtnYes_CD:eq(0)
    sleep    10s
    Click Element    jquery=#IMMessageBoxBtnOK:eq(0)
    sleep      2s