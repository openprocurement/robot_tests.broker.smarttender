*** Settings ***
Library           String
Library           DateTime
Library           smarttender_service.py
Library           op_robot_tests.tests_files.service_keywords

*** Variables ***
${browserAlias}                        'main_browser'
${loading}                              css=div.smt-load
${send offer button}                    css=button#submitBidPlease
${validation message}                   css=.ivu-modal-content .ivu-modal-confirm-body>div:nth-child(2)
${cancellation succeed}                 Пропозиція анульована.
${cancellation error1}                  Не вдалося анулювати пропозицію.
${succeed1}                              Пропозицію прийнято
${succeed2}                             Не вдалося зчитати пропозицію з ЦБД!
${empty error}                          ValueError: Element locator
${error1}                               Не вдалося подати пропозицію
${error2}                               Виникла помилка при збереженні пропозиції.
${error3}                               Непередбачувана ситуація
${error4}                               В даний момент вже йде подача/зміна пропозиції по тендеру від Вашої організації!
${ok button}                            xpath=.//div[@class="ivu-modal-body"]/div[@class="ivu-modal-confirm"]//button
${cancellation offers button}           xpath=.//*[@class='ivu-card ivu-card-bordered'][last()]//div[@class="ivu-poptip-rel"]/button
${cancel. offers confirm button}        xpath=.//*[@class='ivu-card ivu-card-bordered'][last()]//div[@class="ivu-poptip-footer"]/button[2]

#login
${open login button}                    id=LoginAnchor
${login field}                          xpath=(//*[@id="LoginBlock_LoginTb"])[2]
${password field}                       xpath=(//*[@id="LoginBlock_PasswordTb"])[2]
${remember me}                          xpath=(//*[@id="LoginBlock_RememberMe"])[2]
${login button}                         xpath=(//*[@id="LoginBlock_LogInBtn"])[2]

# Privatization
${search input field privatization}     css=.ivu-card-body input[type=text]
${do search privatization}              css=.ivu-card-body button>i
${ss_id}                                None


*** Keywords ***
Підготувати клієнт для користувача
  [Arguments]  ${username}  @{ARGUMENTS}
  [Documentation]  Відкриває переглядач на потрібній сторінці, готує api wrapper, тощо для користувача username.
  Open Browser  http://test.smarttender.biz  chrome  alias=${browserAlias}
  Run Keyword If  '${username}' != 'SmartTender_Viewer'  Login  ${username}

Login
  [Arguments]  ${username}
  Click Element  ${open login button}
  Input Text  ${login field}  ${USERS.users['${username}'].login}
  Input Text  ${password field}  ${USERS.users['${username}'].password}
  Click Element  ${remember me}
  Click Element  ${login button}

Підготувати дані для оголошення тендера
  [Arguments]  ${username}  ${tender_data}  ${role_name}
  [Documentation]  Адаптує початкові дані для створення лоту. Наприклад, змінити дані про procuringEntity на дані про користувача tender_owner на майданчику.
  ...  Перевіряючи значення аргументу role_name, можна адаптувати різні дані для різних ролей
  ...  (наприклад, необхідно тільки для ролі tender_owner забрати з початкових даних поле mode: test, а для інших ролей не потрібно робити нічого).
  ...  Це ключове слово викликається в циклі для кожної ролі, яка бере участь в поточному сценарії.
  ...  З ключового слова потрібно повернути адаптовані дані tender_data. Різниця між початковими даними і кінцевими буде виведена в консоль під час запуску тесту.
  ${tender_data}  smarttender_service.adapt_data_assets  ${tender_data}
  [Return]  ${tender_data}


########################################################################
###                                                                  ###
###                           ASSET                                  ###
###                                                                  ###
########################################################################


Оновити сторінку з об'єктом МП
  [Arguments]  ${username}  ${tender_uaid}
  [Documentation]  Оновлює сторінку з об’єктом МП для отримання потенційно оновлених даних.
  Run Keyword If
  ...  "${username}" != "SmartTender_Owner" or "${username}" == "SmartTender_Owner" and '${mode}' == 'auctions'
  ...  Оновити сторінку з об'єктом МП continue

Оновити сторінку з об'єктом МП continue
  [Documentation]  можно спробувати прискорити синхронізацію використовуючи
  ...  ${last_modification_date} convert_tzdate_synch ${TENDER.LAST_MODIFICATION_DATE}
  ...  але не у всіх сютах оновлюється ${TENDER.LAST_MODIFICATION_DATE} перед виконанням синхронізації
  Log  ${mode}
  ${n}    Run Keyword If  '${mode}' == 'assets'             Set Variable  7
  ...     ELSE IF         '${mode}' == 'lots'               Set Variable  8
  ...     ELSE IF         '${mode}' == 'auctions'           Set Variable  6
  ${time}  Get Current Date
  ${last_modification_date}  convert_datetime_to_kot_format  ${time}
  Go To  http://test.smarttender.biz/ws/webservice.asmx/Execute?calcId=_QA.GET.LAST.SYNCHRONIZATION&args={"SEGMENT":${n}}
  Wait Until Keyword Succeeds  10min  5sec  waiting_for_synch  ${last_modification_date}

waiting_for_synch
  [Arguments]  ${last_modification_date}
  ${synch dict}  Get Text  css=.text
  ${dict}  synchronization  ${synch dict}
  ${DateStart}  Set Variable  ${dict[0]}
  ${DateEnd}  Set Variable  ${dict[1]}
  ${WorkStatus}  Set Variable  ${dict[2]}
  ${Success}  Set Variable  ${dict[3]}
  ${status}  Run Keyword if  '${last_modification_date}' < '${DateStart}' and '${DateEnd}' != '${EMPTY}' and '${WorkStatus}' != 'working' and '${WorkStatus}' != 'fail' and '${Success}' == 'true'
  ...  Set Variable  Pass
  ...  ELSE  Reload Page
  Should Be Equal  ${status}  Pass
  Run Keyword If  '${status}' == 'Pass'  Run Keywords
  ...       Go Back
  ...  AND  Reload Page
  ...  AND  waiting skeleton

Оновити сторінку з лотом
  [Arguments]  ${username}  ${tender_uaid}
  [Documentation]  Оновлює сторінку з лотом для отримання потенційно оновлених даних.
  smarttender.Оновити сторінку з об'єктом МП  ${username}  ${tender_uaid}

Створити об'єкт МП
  [Arguments]  ${username}  ${tender_data}
  [Documentation]  Створює об’єкт МП з початковими даними tender_data  return:  (ідентифікатор новоствореного об’єкта МП)
  Відкрити бланк для створення об’єкту
  Заповнити title для assets  ${tender_data.data.title}
  Заповнити description для assets  ${tender_data.data.description}
  Додати assetHolder
  Заповнити name для assetHolder  ${tender_data.data.assetHolder.name}
  Заповнити scheme для assetHolder  ${tender_data.data.assetHolder.identifier.scheme}
  Заповнити id для assetHolder  ${tender_data.data.assetHolder.identifier.id}
  Заповнити postalCode для assetHolder  ${tender_data.data.assetHolder.address.postalCode}
  Заповнити countryName для assetHolder  ${tender_data.data.assetHolder.address.countryName}
  Заповнити locality для assetHolder  ${tender_data.data.assetHolder.address.locality}
  Заповнити streetAddress для assetHolder  ${tender_data.data.assetHolder.address.streetAddress}
  Додати contactPoint
  Заповнити name для assetHolder.contactPoint  ${tender_data.data.assetHolder.contactPoint.name}
  Заповнити telephone для assetHolder.contactPoint  ${tender_data.data.assetHolder.contactPoint.telephone}
  Заповнити faxNumber для assetHolder.contactPoint  ${tender_data.data.assetHolder.contactPoint.faxNumber}
  Заповнити email для assetHolder.contactPoint  ${tender_data.data.assetHolder.contactPoint.email}
  Заповнити url для assetHolder.contactPoint  ${tender_data.data.assetHolder.contactPoint.url}

  :FOR  ${decision}  in  @{tender_data.data['decisions']}
  \  Заповнити title для decision  ${decision.title}
  \  Заповнити decisionID для decision  ${decision.decisionID}
  \  Заповнити decisionDate для decision  ${decision.decisionDate}

  :FOR  ${item}  in  @{tender_data.data['items']}
  \  Заповнити description для item  ${item.description}
  \  Заповнити classification для item  ${item.classification.id}  ${item.classification.scheme}  ${item.classification.description}
  \  Заповнити quantity для item  ${item.quantity}
  \  Заповнити items.unit для item  ${item.unit.name}
  \  Заповнити postalCode для item  ${item.address.postalCode}
  \  Заповнити countryName для item  ${item.address.countryName}
  \  Заповнити locality для item  ${item.address.locality}
  \  Заповнити streetAddress для item  ${item.address.streetAddress}
  \  Заповнити registrationDetails.status для item  ${item.registrationDetails.status}

  Створити об'єкт приватизації
  ${tender_uaid}  smarttender.Отримати інформацію із об'єкта МП  assetID  assetID  assetID
  [Return]  ${tender_uaid}

Додати assetHolder
  Click Element  css=.ivu-icon.ivu-icon-plus
  Wait Until Page Contains Element  css=.ivu-icon.ivu-icon-minus

Відкрити бланк для створення об’єкту
  Go to  http://test.smarttender.biz/cabinet/registry/privatization-objects/
  Click Element  xpath=//button/*[contains(text(), "Створити об'єкт у реєстрі")]
  waiting skeleton

Створити об'єкт приватизації
  Зберегти об'єкт
  wait until keyword succeeds  120s  5s  Опублікувати asset
  wait_for_loading

Зберегти об'єкт
  ${status}  Run Keyword And Return Status  Click Element  xpath=//*[contains(text(), "Внести зміни")]
  Run Keyword If  "${status}" == "False"  Click Element  xpath=//*[contains(text(), "Зберегти")]
  Wait Until Page Contains Element  css=.ivu-notice>div.ivu-notice-notice  120
  waiting skeleton

Опублікувати asset
  Run Keyword And Ignore Error  Click Element  xpath=//*[contains(text(), "Опублікувати")]
  Wait Until Page Does Not Contain Element  xpath=//*[contains(text(), "Опублікувати")]

wait_for_loading
  ${status}  ${message}  Run Keyword And Ignore Error  Wait Until Page Contains Element  css=.ivu-message .ivu-load-loop  3
  Run Keyword If  "${status}" == "PASS"  Run Keyword And Ignore Error  Wait Until Page Does Not Contain Element  css=.ivu-message .ivu-load-loop  120

Натиснути Коригувати asset
  Wait Until Keyword Succeeds  30s  5  Run Keywords
  ...       Click Element  xpath=//button/span[contains(text(), "Коригування об'єкту приватизації")]
  ...  AND  Sleep  1
  ...  AND  waiting skeleton
  ...  AND  Element Should Not Be Visible  xpath=//button/span[contains(text(), "Коригування об'єкту приватизації")]

Заповнити title для assets
  [Arguments]  ${text}
  Input Text  xpath=(//*[contains(text(), "Найменування")]/..//input)[1]  ${text}

Заповнити description для assets
  [Arguments]  ${text}
  Input Text  xpath=//*[contains(text(), "Опис об'єкту приватизації")]/..//textarea  ${text}

Заповнити name для assetHolder
  [Arguments]  ${text}
  Input Text  xpath=//*[contains(text(), 'Балансоутримувач')]/ancestor::div[@class='ivu-card-body']//*[contains(text(), 'Назва')]/..//input  ${text}

Заповнити scheme для assetHolder
  [Arguments]  ${text}
  ${locator}  Set Variable  xpath=(//*[contains(text(), 'Балансоутримувач')]/ancestor::div[@class='ivu-card-body']//*[contains(text(), 'Код агентства реєстрації')]/..//input)[2]
  Mouse Over  ${locator}
  Click Element  xpath=//*[contains(text(), 'Балансоутримувач')]/ancestor::div[@class='ivu-card-body']//*[contains(text(), 'Код агентства реєстрації')]/..//*[contains(@class, 'ivu-icon-ios-close')]
  Click Element  ${locator}
  Sleep  .5
  Input Text  ${locator}  ${text}
  Sleep  .5
  Click Element  xpath=//ul[@class="ivu-select-dropdown-list"]//li[contains(text(), '${text}')]

Заповнити id для assetHolder
  [Arguments]  ${text}
  Input Text  xpath=//*[contains(text(), 'Балансоутримувач')]/ancestor::div[@class='ivu-card-body']//*[contains(text(), 'Код ЄДРПОУ')]/../following-sibling::div//input  ${text}

Заповнити postalCode для assetHolder
  [Arguments]  ${text}
  Input Text  xpath=//*[contains(text(), 'Балансоутримувач')]/ancestor::div[@class='ivu-card-body']//*[contains(text(), 'Поштовий індекс')]/../following-sibling::div//input  ${text}

Заповнити countryName для assetHolder
  [Arguments]  ${text}
  ${locator}  Set Variable  xpath=(//*[contains(text(), 'Балансоутримувач')]/ancestor::div[@class='ivu-card-body']//*[contains(text(), 'Країна')]/../following-sibling::div//input)[2]
  Click Element  ${locator}
  Sleep  .5
  Input Text  ${locator}  ${text}
  Sleep  .5
  Click Element  xpath=//ul[@class="ivu-select-dropdown-list"]//li[contains(text(), '${text}')]

Заповнити locality для assetHolder
  [Arguments]  ${text}
  ${locator}   Set Variable  xpath=(//*[contains(text(), 'Балансоутримувач')]/ancestor::div[@class='ivu-card-body']//*[contains(text(), 'Місто')]/../following-sibling::div//input)[2]
  Click Element  ${locator}
  Sleep  .5
  Input Text  ${locator}  ${text}
  Sleep  .5
  Click Element  xpath=//ul[@class="ivu-select-dropdown-list"]//li[contains(text(), '${text}')]

Заповнити streetAddress для assetHolder
  [Arguments]  ${text}
  Input Text  xpath=//*[contains(text(), 'Балансоутримувач')]/ancestor::div[@class='ivu-card-body']//*[contains(text(), 'Вулиця')]/..//input  ${text}

Додати contactPoint
  Click Element  xpath=//*[contains(text(), 'Контактна особа')]/../following-sibling::div//*[contains(@class, 'ivu-icon-plus')]

Заповнити name для assetHolder.contactPoint
  [Arguments]  ${text}
  Input Text  xpath=//*[contains(text(), "Контактна особа")]/../../following-sibling::*//*[contains(text(), 'ПІБ')]/..//input  ${text}

Заповнити telephone для assetHolder.contactPoint
  [Arguments]  ${text}
  Input Text  xpath=//*[contains(text(), "Контактна особа")]/../../following-sibling::*//*[contains(text(), 'Телефон')]/..//input  ${text}

Заповнити faxNumber для assetHolder.contactPoint
  [Arguments]  ${text}
  Input Text  xpath=(//*[contains(text(), "Контактна особа")]/../../following-sibling::*//*[contains(text(), 'Телефон')]/..//input)[2]  ${text}

Заповнити email для assetHolder.contactPoint
  [Arguments]  ${text}
  Input Text  xpath=(//*[contains(text(), "Контактна особа")]/../../following-sibling::*//*[contains(text(), 'Email')]/..//input)[1]  ${text}

Заповнити url для assetHolder.contactPoint
  [Arguments]  ${text}
  Input Text  xpath=(//*[contains(text(), "Контактна особа")]/../../following-sibling::*//*[contains(text(), 'Email')]/..//input)[2]  ${text}

Заповнити title для decision
  [Arguments]  ${text}
  ${selector}  Set Variable  xpath=//*[contains(text(), "Рішення про приватизацію об'єкту")]/../div[1]//input
  Input Text  ${selector}  ${text}

Заповнити decisionID для decision
  [Arguments]  ${text}
  Input Text  xpath=//*[contains(text(), "Рішення про приватизацію об'єкту")]/../div[2]/div/div/div[1]//input  ${text}

Заповнити decisionDate для decision
  [Arguments]  ${text}
  ${data}  convert_datetime_to_smarttender_format_minute  ${text}
  ${selector}  Set Variable  xpath=//*[contains(text(), "Рішення про приватизацію об'єкту")]/../div[2]/div/div/div[3]//input
  Input Text  ${selector}  ${data}
  Press Key  ${selector}  \\09

Заповнити description для item
  [Arguments]  ${text}  ${number}=1
  ${selector}  Set Variable  xpath=//*[@data-qa="item"][${number}]//div[1]//textarea
  Input Text  ${selector}  ${text}

Заповнити classification для item
  [Arguments]  ${id}  ${scheme}  ${description}  ${number}=1
  Click Element  xpath=//*[@data-qa="item"][${number}]//div[1]//a
  Wait Until Keyword Succeeds  45  3  Вибрати потрібну вкладку для item.classification  ${scheme}
  Sleep  1
  ${locator}  Run Keyword If  "${scheme}" == "CPV"
  ...        Set Variable  css=.ivu-tabs-tabpane:nth-child(1) input
  ...  ELSE  Set Variable  css=.ivu-tabs-tabpane:nth-child(2) input
  Input Text  ${locator}  ${id}
  Sleep  1
  Wait Until Keyword Succeeds  45  3  Click Element  xpath=(//a[contains(text(), "${id}") and contains(text(), "${description}")])[last()]
  Click Element  css=.ivu-modal-footer button

Вибрати потрібну вкладку для item.classification
  [Arguments]  ${scheme}
  ${scheme}  Run Keyword If  '${scheme}' == 'CPV'  Set Variable  ДК021
  ...  ELSE  Set Variable  ${scheme}
  Click Element  xpath=(//*[contains(text(), "${scheme}")])[last()]
  Wait Until Page Contains Element  xpath=(//*[contains(text(), "${scheme}") and contains(@class, 'active')])[last()]

Заповнити quantity для item
  [Arguments]  ${text}  ${number}=1
  ${str_text}  Evaluate  str(${text})
  ${locator}  Set Variable  xpath=((//*[contains(text(), "Загальна інформація")]/ancestor::*[@class="ivu-card-body"]//*[contains(text(), "Об'єм")])[${number}]/following-sibling::div//input)[1]
  Double Click Element   ${locator}
  Sleep  .5
  Press Key  ${locator}  \\127
  Sleep  .5
  Input Text  ${locator}  ${str_text}
  Sleep  .5

Заповнити items.unit для item
  [Arguments]  ${text}  ${number}=1
  ${locator}  Set Variable  xpath=(//*[@data-qa="item"][${number}]//*[@class="ivu-card-body"]/div[4]//input)[3]
  Click Element  ${locator}
  Sleep  1
  Input Text  ${locator}  ${text}
  Sleep  1
  Click Element  xpath=(//ul[@class="ivu-select-dropdown-list"]//li[contains(text(), '${text}')])[${number}]

Заповнити postalCode для item
  [Arguments]  ${text}  ${number}=1
  Input Text  xpath=(//*[@data-qa="item"][${number}]//*[@class="ivu-card-body"]/div[5]//input)[1]  ${text}

Заповнити countryName для item
  [Arguments]  ${text}  ${number}=1
  ${locator}  Set Variable  xpath=(//*[@data-qa="item"][${number}]//*[@class="ivu-card-body"]/div[5]//input)[3]
  Click Element  ${locator}
  Sleep  .5
  Input Text  ${locator}  ${text}
  Sleep  .5
  Wait Until Keyword Succeeds  15s  3s  Click Element  xpath=(//ul[@class="ivu-select-dropdown-list"]/li[text()="${text}"])[last()]

Заповнити locality для item
  [Arguments]  ${text}  ${number}=1
  ${locator}  Set Variable  xpath=(//*[@data-qa="item"][${number}]//*[@class="ivu-card-body"]/div[5]//input)[5]
  Click Element  ${locator}
  Sleep  .5
  Input Text  ${locator}  ${text}
  Sleep  .5
  Wait Until Keyword Succeeds  45s  3s  Click Element  xpath=//*[@data-qa="item"][${number}]//div//ul[@class="ivu-select-dropdown-list"]/li[contains(text(), "${text}")]

Заповнити streetAddress для item
  [Arguments]  ${text}  ${number}=1
  Input Text  xpath=(//*[@data-qa="item"][${number}]//*[@class="ivu-card-body"]/div[5]//input)[6]  ${text}

Заповнити registrationDetails.status для item
  [Arguments]  ${status}  ${number}=1
  ${selector}  Run Keyword If
  ...           "${status}" == "unknown"      Set Variable  xpath=(//*[@data-qa="item"][${number}]//span[@class="semibold"])[1]
  ...  ELSE IF  "${status}" == "registering"  Set Variable  xpath=(//*[@data-qa="item"][${number}]//span[@class="semibold"])[2]
  ...  ELSE IF  "${status}" == "complete"     Set Variable  xpath=(//*[@data-qa="item"][${number}]//span[@class="semibold"])[3]
  Click Element  ${selector}

Пошук об’єкта МП по ідентифікатору
  [Arguments]  ${username}  ${tender_uaid}
  [Documentation]  Шукає об’єкт МП з uaid = tender_uaid.  return: (словник з інформацією про об’єкт МП)
  Wait Until Keyword Succeeds  10 min  5 sec  Пошук об’єкта МП по ідентифікатору продовження  ${tender_uaid}  ${username}

Пошук об’єкта МП по ідентифікатору продовження
  [Arguments]  ${tender_uaid}  ${username}
  Run Keyword If  "${username}" == "SmartTender_Owner"
  ...  Go to  http://test.smarttender.biz/cabinet/registry/privatization-objects
  ...  ELSE  Go to  http://test.smarttender.biz/small-privatization/registry/privatization-objects
  Input Text  ${search input field privatization}  ${tender_uaid}
  Click Element  ${do search privatization}
  Wait Until Page Contains Element  xpath=//span[contains(text(), "${tender_uaid}")]
  ${privatization assets page}  Get Element Attribute  xpath=//p[contains(text(), "${tender_uaid}")]/..//a[@href]@href
  Go To  ${privatization assets page}
  Log  ${privatization assets page}  WARN

Знайти id активу
  [Arguments]  ${lot}=None
  ${href}  get element attribute  css=h4>a[href]@href
  ${ss_id}  get_id_from_tender_href  ${href}  ${lot}
  Set Global Variable  ${ss_id}
  [Return]  ${ss_id}

Отримати інформацію із об'єкта МП
  [Arguments]  ${username}  ${tender_uaid}  ${field_name}
  [Documentation]  Отримує значення поля field_name для об’єкту МП tender_uaid. return: tender['field_name'] (значення поля).
  ${result}  Отримати та обробити дані із об'єкта МП  ${field_name}
  [Return]  ${result}

Отримати та обробити дані із об'єкта МП
  [Arguments]  ${field_name}
  waiting skeleton
  ${selector}  object_field_info  ${field_name}
  Focus  ${selector}
  ${value}  Get Text  ${selector}
  ${length}  Get Length  ${value}
  Run Keyword If  ${length} == 0  Capture Page Screenshot  ${OUTPUTDIR}/my_screen{index}.png
  ${result}  convert_object_result  ${field_name}  ${value}
  [Return]  ${result}

Отримати інформацію з активу об'єкта МП
  [Arguments]  ${username}  ${tender_uaid}  ${item_id}  ${field_name}
  [Documentation]  Отримує значення поля field_name з активу з item_id в описі об’єкта МП tender_uaid. Return: item['field_name'] (значення поля).
  ${result}  Отримати та обробити дані з активу об'єкта МП  ${field_name}  ${item_id}
  [Return]  ${result}

Отримати та обробити дані з активу об'єкта МП
  [Arguments]  ${field_name}  ${item_id}
  ${selector}  asset_field_info  ${fieldname}  ${item_id}
  ${value}  Get Text  ${selector}
  ${length}  Get Length  ${value}
  Run Keyword If  ${length} == 0  Capture Page Screenshot  ${OUTPUTDIR}/my_screen{index}.png
  ${result}=  convert_asset_result  ${fieldname}  ${value}
  [Return]  ${result}

Внести зміни в об'єкт МП
  [Arguments]  ${username}  ${tender_uaid}  ${fieldname}  ${fieldvalue}
  [Documentation]  Змінює значення поля fieldname на fieldvalue для об’єкта МП tender_uaid.
  Натиснути Коригувати asset
  Run Keyword  Заповнити ${fieldname} для assets  ${fieldvalue}
  Зберегти об'єкт

Внести зміни в актив об'єкта МП
  [Arguments]  ${username}  ${item_id}  ${tender_uaid}  ${fieldname}  ${fieldvalue}
  [Documentation]  Змінює значення поля fieldname на fieldvalue для активу item_id об’єкта МП tender_uaid.
  Натиснути Коригувати asset
  Run Keyword  Заповнити ${fieldname} для item  ${fieldvalue}
  Зберегти об'єкт

Завантажити ілюстрацію в об'єкт МП
  [Arguments]  ${username}  ${tender_uaid}  ${filepath}
  [Documentation]  Завантажує ілюстрацію, яка знаходиться по шляху filepath і має documentType = illustration, до об’єкта МП tender_uaid користувачем username.
  Натиснути Коригувати asset
  Choose File  xpath=//input[@type='file'][1]  ${filepath}
  Вибрати тип документу для asset  illustration
  Зберегти об'єкт

Завантажити документ в об'єкт МП з типом
  [Arguments]  ${username}  ${tender_uaid}  ${filepath}  ${documentType}
  [Documentation]  Завантажує документ, який знаходиться по шляху filepath і має певний documentType (наприклад, notice і т.д), до об’єкта МП tender_uaid користувачем username.
  Натиснути Коригувати asset
  Choose File  xpath=//input[@type='file'][1]  ${filepath}
  Вибрати тип документу для asset  ${documentType}
  Зберегти об'єкт
  Run Keyword If  "${TESTNAME}" == "Можливість завантажити публічний паспорт активу об'єкта МП"  Sleep   180s

Вибрати тип документу для asset
  [Arguments]  ${documentType}
  Focus  xpath=(//*[@data-toggle="dropdown"])[last()]
  Wait Until Keyword Succeeds  15  5  Click Element  xpath=(//*[@data-toggle="dropdown"])[last()]
  log  ${mode}
  ${type}  Run Keyword If  '${mode}' == 'assets'  map_documentType  ${documentType}  reverse
  ...  ELSE IF  '${mode}' == 'lots'  map_documentType_auction  ${documentType}  reverse
  Wait Until Keyword Succeeds  15  5  Click Element  xpath=(//*[contains(text(), "${type}")])[last()]

Вибрати тип документу для auction
  [Arguments]  ${documentType}
  Focus  xpath=((//*[@class="file-container"])[1]//*[@data-toggle="dropdown"])[last()]
  Wait Until Keyword Succeeds  15  5  Click Element  xpath=((//*[@class="file-container"])[1]//*[@data-toggle="dropdown"])[last()]
  ${type}  map_documentType_auction  ${documentType}  reverse
  Wait Until Keyword Succeeds  15  5  Click Element  xpath=((//*[@class="file-container"])[1]//*[@data-toggle="dropdown"])[last()]/following-sibling::ul//*[contains(text(), "${type}")]

Додати актив до об'єкта МП
  [Arguments]  ${username}  ${tender_uaid}  ${item}
  [Documentation]  Додає дані про предмет item до об’єкта МП tender_uaid користувачем username.
  Натиснути Коригувати asset
  Click Element  xpath=//*[contains(text(), "Додати об'єкт")]/ancestor::div[@class="ivu-row"]//button
  Заповнити description для item  ${item["description"]}  2
  Заповнити classification для item  ${item.classification.id}  ${item.classification.scheme}  ${item.classification.description}  2
  Заповнити quantity для item  ${item.quantity}  2
  Заповнити items.unit для item  ${item.unit.name}  2
  Заповнити postalCode для item  ${item.address.postalCode}  2
  Заповнити countryName для item  ${item.address.countryName}  2
  Заповнити locality для item  ${item.address.locality}  2
  Заповнити streetAddress для item  ${item.address.streetAddress}  2
  Заповнити registrationDetails.status для item  ${item.registrationDetails.status}  2
  Зберегти об'єкт

Завантажити документ для видалення об'єкта МП
  [Arguments]  ${username}  ${tender_uaid}  ${filepath}
  [Documentation]  Завантажує документ, який знаходиться по шляху filepath і має documentType = cancellationDetails, до об’єкта МП tender_uaid користувачем username.
  Click Element  xpath=//button//*[contains(text(), "Виключити об'єкт з переліку")]
  Choose File    xpath=//input[1]  ${filepath}
  Page Should Contain Element  xpath=//*[contains(@class, "file")]//a

Видалити об'єкт МП
  [Arguments]  ${username}  ${tender_uaid}
  [Documentation]  Видаляє об’єкт МП tender_uaid користувачем username.
  Click Element  xpath=(//button//*[contains(text(), "Виключити об'єкт з переліку")])[last()]
  Wait Until Page Contains Element  xpath=//h4[contains(text(), "Виключено з переліку")]

Отримати кількість активів в об'єкті МП
  [Arguments]  ${username}  ${tender_uaid}
  [Documentation]  Отримує кількість активів в об’єкті МП tender_uaid. Return ${number_of_items} (кількість активів).
  ${number_of_items}  Get Matching Xpath Count  //*[@data-qa="item"]
  [Return]  ${number_of_items}


########################################################################
###                                                                  ###
###                            LOTS                                  ###
###                                                                  ###
########################################################################

Створити лот
  [Arguments]  ${username}  ${tender_data}  ${asset_uaid}
  [Documentation]  Створює лот з початковими даними tender_data і прив’язаним до нього об’єктом МП asset_uaid
  Відкрити бланк створення лоту
  Заповнити asset_uaid для lots  ${asset_uaid}
  Заповнити decisionDate для lots  ${tender_data.data.decisions[0].decisionDate}
  Заповнити decisionID для lots  ${tender_data.data.decisions[0].decisionID}
  Створити об'єкт приватизації
  ${tender_uaid}  Отримати та обробити дані із лоту  lotID
  [Return]  ${tender_uaid}

Відкрити бланк створення лоту
  Go To  http://test.smarttender.biz/cabinet/registry/privatization-objects/
  Click Element  xpath=//*[contains(text(), "Створити інформаційне повідомлення")]
  waiting skeleton

Заповнити asset_uaid для lots
  [Arguments]  ${data}
  ${selector}  Set Variable  xpath=(//*[contains(text(), "Загальна інформація")]/ancestor::*[@class="ivu-card-body"]//input)[1]
  Input Text  ${selector}  ${data}

Заповнити decisionDate для lots
  [Arguments]  ${data}
  ${selector}  Set Variable  xpath=(//*[contains(text(), "Рішення про затверждення умов продажу лоту")]/following-sibling::*//input)[3]
  ${text}  convert_datetime_to_smarttender_format_minute  ${data}
  Input Text  ${selector}  ${text}
  Press Key  ${selector}  \\09

Заповнити decisionID для lots
  [Arguments]  ${data}
  ${selector}  Set Variable  xpath=(//*[contains(text(), "Рішення про затверждення умов продажу лоту")]/following-sibling::*//input)[2]
  Input Text  ${selector}  ${data}

Пошук лоту по ідентифікатору
  [Arguments]  ${username}  ${tender_uaid}
  [Documentation]  Шукає лот з uaid = tender_uaid. return: tender_uaid (словник з інформацією про лот)
  Wait Until Keyword Succeeds  10 min  5 sec  Пошук лоту по ідентифікатору продовження  ${tender_uaid}  ${username}
  [Return]  ${tender_uaid}

Пошук лоту по ідентифікатору продовження
  [Arguments]  ${tender_uaid}  ${username}
  Run Keyword If  "${username}" == "SmartTender_Owner"
  ...  Go to        http://test.smarttender.biz/cabinet/registry/privatization-lots
  ...  ELSE  Go to  http://test.smarttender.biz/small-privatization/registry/privatization-lots
  Input Text  ${search input field privatization}  ${tender_uaid}
  Click Element  ${do search privatization}
  Wait Until Page Contains Element  xpath=//span[contains(text(), "${tender_uaid}")]
  ${privatization lot page}  Get Element Attribute  xpath=//*[contains(text(), "${tender_uaid}")]/..//a[@href]@href
  Go To  ${privatization lot page}
  Set Global Variable  ${privatization lot page}
  Log  ${privatization lot page}  WARN

Отримати інформацію із лоту
  [Arguments]  ${username}  ${tender_uaid}  ${field_name}
  [Documentation]  Отримує значення поля field_name для лоту tender_uaid. return: tender['field_name'] (значення поля).
  Reload Page
  waiting skeleton
  ${result}  Run Keyword If  "assets" in "${field_name}"  Отримати asset_id для лоту
  ...  ELSE IF  "${field_name}" == "auctions[2].minimalStep.amount"  Evaluate  float(0)
  ...  ELSE  Отримати та обробити дані із лоту  ${field_name}
  ${result}  Run Keyword If  "${username}" == "SmartTender_Viewer" and 'tenderingDuration' in '${field_name}'  Set Variable  P1M
  ...  ELSE  Set Variable  ${result}
  [Return]  ${result}

Отримати та обробити дані із лоту
  [Arguments]  ${field_name}
  Run Keyword If  '${field_name}' == 'auctions[0].auctionID'  Run Keywords
  ...  Sleep  240
  ...  AND  Reload Page
  ...  AND  waiting skeleton
  ${selector}  ss_lot_field_info  ${field_name}
  Focus  ${selector}
  ${value}  Get Text  ${selector}
  ${length}  Get Length  ${value}
  Run Keyword If  ${length} == 0  Capture Page Screenshot  ${OUTPUTDIR}/my_screen{index}.png
  ${result}=  convert_lot_result  ${fieldname}  ${value}
  [Return]  ${result}

Отримати asset_id для лоту
  Click Element  xpath=//*[contains(text(), 'Загальна інформація')]/..//*[text()="Зв'язаний об'єкт приватизації"]/../following-sibling::div
  ${href}  get element attribute  css=h4>a[href]@href
  ${ss_id}  get_id_from_tender_href  ${href}
  Go Back
  [Return]  ${ss_id}

Отримати інформацію з активу лоту
  [Arguments]  ${username}  ${tender_uaid}   ${item_id}  ${field_name}
  [Documentation]  Отримує значення поля field_name з активу з item_id в описі лоту tender_uaid. return: item['field_name'] (значення поля).
  ${result}  Отримати та обробити дані з активу об'єкта МП  ${field_name}  ${item_id}
  [Return]  ${result}

Внести зміни в лот
  [Arguments]  ${username}  ${tender_uaid}  ${fieldname}  ${fieldvalue}
  [Documentation]  Змінює значення поля fieldname на fieldvalue для лоту tender_uaid.
  Натиснути Коригувати lot
  Внести зміни в лот продовження  ${fieldname}  ${fieldvalue}
  Зберегти об'єкт

Внести зміни в лот продовження
  [Arguments]  ${fieldname}  ${fieldvalue}
  Run Keyword If
  ...  "${fieldname}" == "title"
  ...  Run Keyword  Заповнити ${fieldname} для assets  ${fieldvalue}
  ...  ELSE IF  "${fieldname}" == "description"
  ...  Input Text  xpath=//*[contains(text(), "Опис інформаційного повідомлення")]/following-sibling::div//textarea  ${fieldvalue}

Внести зміни в актив лоту
  [Arguments]  ${username}  ${item_id}   ${tender_uaid}  ${fieldname}  ${fieldvalue}
  [Documentation]  Змінює значення поля fieldname на fieldvalue для активу item_id лоту tender_uaid.
  Натиснути Коригувати lot
  Run Keyword  Заповнити ${fieldname} для item  ${fieldvalue}
  Зберегти об'єкт

Завантажити ілюстрацію в лот
  [Arguments]  ${username}  ${tender _uaid}  ${filepath}
  [Documentation]  Завантажує ілюстрацію, яка знаходиться по шляху filepath і має documentType = illustration, до лоту tender_uaid користувачем username.
  Натиснути Коригувати lot
  Choose File  xpath=(//input[@type='file'][1])[last()]  ${filepath}
  Вибрати тип документу для asset  illustration
  Зберегти об'єкт

Завантажити документ в лот з типом
  [Arguments]  ${username}  ${tender_uaid}  ${filepath}  ${documentType}
  [Documentation]  Завантажує документ, який знаходиться по шляху filepath і має певний documentType (наприклад, notice і т.д), до лоту tender_uaid користувачем username.
  ...  return: reply (словник з інформацією про документ).
  Натиснути Коригувати lot
  Choose File  xpath=(//input[@type='file'][1])[last()]  ${filepath}
  Вибрати тип документу для asset  ${documentType}
  Зберегти об'єкт
  Run Keyword If  "${TESTNAME}" == "Можливість завантажити публічний паспорт активу лоту"  Sleep  180

Завантажити документ для видалення лоту
  [Arguments]  ${username}  ${tender_uaid}  ${filepath}
  [Documentation]  Завантажує документ, який знаходиться по шляху filepath і має documentType = cancellationDetails, до лоту tender_uaid користувачем username.
  Click Element  xpath=//button//*[contains(text(), " Видалити інформаційне повідомлення")]
  Choose File    xpath=//input[1]  ${filepath}
  Page Should Contain Element  xpath=//*[contains(@class, "file")]//a

Видалити лот
  [Arguments]  ${username}  ${tender_uaid}
  [Documentation]  Видаляє лот tender_uaid користувачем username.
  Click Element  xpath=(//button//*[contains(text(), "Видалити інформаційне повідомлення")])[last()]
  Wait Until Page Contains Element  xpath=//h4[contains(text(), "Об’єкт виключено")]  60


Додати умови проведення аукціону
  [Arguments]  ${username}  ${auction}  ${auction_index}  ${tender_uaid}
  [Documentation]  Додає умови проведення аукціону auction користувачем username  return: reply (словник з інформацією про умови проведення аукціону).
  ...  (викликається двічі, окремо для вказання умов проведення першого аукціону і окремо для другого)
  Run Keyword  Додати умови проведення аукціону ${auction_index}  ${auction}  ${tender_uaid}

Додати умови проведення аукціону 0
  [Arguments]  ${auction}  ${tender_uaid}
  Натиснути Коригувати lot
  Заповнити auctionPeriod.startDate для auction    ${auction.auctionPeriod.startDate}
  Заповнити value.amount для auction               ${auction.value.amount}
  Заповнити valueAddedTaxIncluded для auction      ${auction.value.valueAddedTaxIncluded}
  Заповнити minimalStep.amount для auction         ${auction.minimalStep.amount}
  Заповнити guarantee.amount для auction           ${auction.guarantee.amount}
  Заповнити registrationFee.amount для auction     ${auction.registrationFee.amount}

  Заповнити bankName для bankAccount                             ${auction.bankAccount.bankName}
  Заповнити description для bankAccount                          ${auction.bankAccount.description}
  Заповнити accountIdentification.scheme для bankAccount         ${auction.bankAccount.accountIdentification[0].scheme}
  Заповнити accountIdentification.id для bankAccount             ${auction.bankAccount.accountIdentification[0].id}
  Заповнити accountIdentification.description для bankAccount    ${auction.bankAccount.accountIdentification[0].description}

Додати умови проведення аукціону 1
  [Arguments]  ${auction}  ${tender_uaid}
  ${duration}  Set Variable  ${auction.tenderingDuration}
  ${duration}  Run Keyword if  "${duration}" == "P1M"  Set Variable  30
  Заповнити duration для auction  ${duration}
  Зберегти об'єкт
  Wait Until Keyword Succeeds  120  5  Передати на перевірку лот

Передати на перевірку лот
  Run Keyword And Ignore Error  Click Element  xpath=//*[contains(text(), "Передати на перевірку")]
  Wait Until Page Does Not Contain Element  xpath=//*[contains(text(), "Передати на перевірку")]  10

Заповнити auctionPeriod.startDate для auction
  [Arguments]  ${data}
  Run Keyword And Ignore Error  Run Keywords
  ...       Mouse Over  xpath=//*[contains(text(), "Умови аукціону")]/..//*[contains(text(), "Дата проведення аукціону")]/..//i
  ...  AND  Click Element  xpath=//*[contains(text(), "Умови аукціону")]/..//*[contains(text(), "Дата проведення аукціону")]/..//i
  ${selector}  Set Variable  xpath=//*[contains(text(), "Умови аукціону")]/..//*[contains(text(), "Дата проведення аукціону")]/..//input
  ${text}  convert_datetime_to_kot_format  ${data}
  Input Text  ${selector}  ${text}
  Press Key  ${selector}  \\09

Заповнити duration для auction
  [Arguments]  ${data}
  ${selector}  Set Variable  xpath=//*[contains(text(), "Умови аукціону")]/..//*[contains(text(), "Період між аукціонами")]/..//input
  Input Text  ${selector}  ${data}


Заповнити value.amount для auction
  [Arguments]  ${data}
  ${text}  Evaluate  str(${data})
  ${selector}  Set Variable  xpath=(//*[contains(text(), "Умови аукціону")]/..//*[contains(text(), "Стартова ціна об’єкта")]/..//input)[1]
  Input Text  ${selector}  ${text}

Заповнити valueAddedTaxIncluded для auction
  [Arguments]  ${data}
  ${selector}  Set Variable  xpath=(//*[contains(text(), "Умови аукціону")]/..//*[contains(text(), "Стартова ціна об’єкта")]/..//input)[3]
  Run Keyword If  "${data}" == "True"    Select Checkbox    ${selector}
  ...  ELSE                              Unselect Checkbox  ${selector}

Заповнити minimalStep.amount для auction
  [Arguments]  ${data}
  ${text}  Evaluate  str(${data})
  ${selector}  Set Variable  xpath=(//*[contains(text(), "Умови аукціону")]/..//*[contains(text(), "Крок аукціону")]/..//input)[1]
  Input Text  ${selector}  ${text}

Заповнити guarantee.amount для auction
  [Arguments]  ${data}
  ${text}  Evaluate  str(${data})
  ${selector}  Set Variable  xpath=(//*[contains(text(), "Умови аукціону")]/..//*[contains(text(), "Розмір гарантійного внеску")]/..//input)[1]
  Input Text  ${selector}  ${text}

Заповнити registrationFee.amount для auction
  [Arguments]  ${data}
  ${text}  Evaluate  str(${data})
  ${selector}  Set Variable  xpath=(//*[contains(text(), "Умови аукціону")]/..//*[contains(text(), "Реєстраційний внесок")]/..//input)[1]
  Input Text  ${selector}  ${text}

Заповнити bankName для bankAccount
  [Arguments]  ${text}
  Input Text  xpath=//*[contains(text() , 'Найменування банку')]/following-sibling::div//input  ${text}

Заповнити description для bankAccount
  [Arguments]  ${text}
  Input Text  xpath=//*[contains(text() , 'Інформація про казначейські')]/following-sibling::div//textarea  ${text}

Заповнити accountIdentification.id для bankAccount
  [Arguments]  ${text}
  ${selector}  Set Variable  xpath=(//*[contains(text() , 'Реквізити')]/following-sibling::div//input)[2]
  Focus  ${selector}
  Input Text  ${selector}  ${text}

Заповнити accountIdentification.scheme для bankAccount
  [Arguments]  ${text}
  ${mapped}  Run Keyword If
  ...           '${text}' == 'UA-MFO'  Set Variable  МФО банку
  ...  ELSE IF  '${text}' == 'UA-EDR'  Set Variable  Код ЄДРПОУ
  ...  ELSE IF  '${text}' == 'accountNumber'  Set Variable  Номер рахунку
  Click Element  xpath=//*[contains(text() , 'Реквізити')]/following-sibling::div//*[contains(text(), 'Обрати')]
  Click Element  xpath=(//*[contains(text(), '${mapped}')])[last()]

Заповнити accountIdentification.description для bankAccount
  [Arguments]  ${text}
  Input Text  xpath=(//*[contains(text() , 'Реквізити')]/following-sibling::div//input)[3]  ${text}

Натиснути Коригувати lot
  Wait Until Keyword Succeeds  30s  5  Run Keywords
  ...       Click Element  xpath=//button/span[contains(text(), "Коригування інформаційного повідомлення")]
  ...  AND  Sleep  1
  ...  AND  waiting skeleton
  ...  AND  Element Should Not Be Visible  xpath=//button/span[contains(text(), "Коригування інформаційного повідомлення")]

Внести зміни в умови проведення аукціону
  [Arguments]  ${username}  ${tender_uaid}  ${fieldname}  ${fieldvalue}  ${auction_index}
  [Documentation]  Змінює значення поля fieldname на fieldvalue для аукціону auction_index лоту tender_uaid.
  Натиснути Коригувати lot
  Run Keyword  Заповнити ${fieldname} для auction  ${fieldvalue}
  Зберегти об'єкт

Завантажити документ в умови проведення аукціону
  [Arguments]  ${username}  ${tender_uaid}  ${filepath}  ${documentType}  ${auction_index}
  [Documentation]  Завантажує документ, який знаходиться по шляху filepath і має певний documentType (наприклад, notice і т.д), до умов проведення аукціону з індексом auction_index лоту tender_uaid.
  Натиснути Коригувати lot
  Choose File  xpath=//input[@type='file'][1]  ${filepath}
  Вибрати тип документу для auction  ${documentType}
  Зберегти об'єкт
  Run Keyword If  "${TESTNAME}" == "Можливість завантажити публічний паспорт до умов проведення аукціону"  Sleep  180

waiting skeleton
  ${status}  ${message}  Run Keyword And Ignore Error  Wait Until Page Contains Element  css=.skeleton-wrapper  3
  Run Keyword If  "${status}" == "PASS"  Run Keyword And Ignore Error  Wait Until Element Is Not Visible  css=.skeleton-wrapper  60

Отримати документ
  [Arguments]  ${username}  ${tender_uaid}  ${doc_id}
  [Documentation]  Завантажує файл з doc_id в заголовку з лоту tender_uaid в директорію ${OUTPUT_DIR}
  ...  для перевірки вмісту цього файлу.
  ...  [Повертає] filename (ім'я завантаженого файлу)
  Sleep  180
  Reload Page
  log  ${mode}
  ${fileUrl}=  Get Element Attribute  xpath=//*[contains(text(), '${doc_id}')]@href
  ${filename}=  Get Text  xpath=//*[contains(text(), '${doc_id}')]
  smarttender_service.download_file  ${fileUrl}  ${OUTPUT_DIR}/${filename}
  [Return]  ${filename}

########################################################################
###                          TENDER                                  ###
########################################################################
Пошук тендера по ідентифікатору
  [Arguments]  ${username}  ${tender_uaid}
  [Documentation]  Шукає лот з uaid = tender_uaid.
  ...  [Повертає] tender (словник з інформацією про лот)
  Run Keyword If  '${mode}' == 'auctions' and "${username}" == "SmartTender_Owner"  Go To  http://test.smarttender.biz/komertsiyni-torgy/
  ...  ELSE  Go To  http://test.smarttender.biz/test-tenders/?mode=prop
  Input Text  xpath=//input[@placeholder="Введіть запит для пошуку або номер тендеру"]  ${tender_uaid}
  Press Key  xpath=//input[@placeholder="Введіть запит для пошуку або номер тендеру"]  \\13
  ${search result}  Get Matching Xpath Count  xpath=//tr[@class='head']//a[@href and contains(text(), '[ТЕСТУВАННЯ]')]
  Should Be Equal  ${search result}  1
  ${href}  Get Element Attribute  xpath=//tr[@class='head']//a@href
  Go To  ${href}
  Log  ${href}  WARN

Оновити сторінку з тендером
  [Arguments]  ${username}  ${tender_uaid}
  [Documentation]  Оновлює сторінку з лотом для отримання потенційно оновлених даних.
  smarttender.Оновити сторінку з об'єктом МП  ${username}  ${tender_uaid}

Отримати інформацію із тендера
  [Arguments]  ${username}  ${tender_uaid}  ${field_name}
  [Documentation]  Отримує значення поля field_name для лоту tender_uaid.
  ${reply}  Отримати та обробити дані із тендера  ${field_name}
  [Return]  ${reply}

Отримати та обробити дані із тендера
  [Arguments]  ${field_name}
  ${selector}  object_tender_info  ${field_name}
  Focus  ${selector}
  ${value}  Get Text  ${selector}
  ${length}  Get Length  ${value}
  Run Keyword If  ${length} == 0  Capture Page Screenshot  ${OUTPUTDIR}/my_screen{index}.png
  ${result}  convert_tender_result  ${field_name}  ${value}
  ${status}  Run keyword And Ignore Error  Page Should Contain Element  xpath=//*[@contains(text(), 'Дата скасування')]
  ${result}  Run Keyword If  '${field_name}' == 'cancellations[0].status' and '${status[0]}' == 'FAIL'
  ...        Set Variable  active
  ...  ELSE  Set Variable  ${result}
  [Return]  ${result}

Отримати інформацію із предмету
  [Arguments]  ${username}  ${tender_uaid}  ${item_id}  ${field_name}
  [Documentation]  Отримує значення поля field_name з предмету з item_id в описі лоту tender_uaid.
  ...  [Повертає] item['field_name'] (значення поля).
  ${reply}  Отримати та обробити дані із предмету  ${field_name}  ${item_id}
  [Return]  ${reply}

Отримати та обробити дані із предмету
  [Arguments]  ${field_name}  ${item_id}
  ${selector}  object_item_info  ${field_name}  ${item_id}
  Focus  ${selector}
  ${value}  Get Text  ${selector}
  ${length}  Get Length  ${value}
  Run Keyword If  ${length} == 0  Capture Page Screenshot  ${OUTPUTDIR}/my_screen{index}.png
  ${result}  convert_item_result  ${field_name}  ${value}
  [Return]  ${result}


########################################################################
###                         AUCTION                                  ###
########################################################################

Отримати посилання на аукціон для глядача
  [Arguments]  ${username}  ${tender_uaid}  ${lot_id}=Empty
  [Documentation]  Отримує посилання на аукціон для лоту tender_uaid.
  ...  [Повертає] auctionUrl (посилання).
  Click Element  xpath=//*[contains(text(), 'Перегляд аукціону')]
  Sleep  5
  Wait Until Page Contains Element  xpath=//*[contains(text(), 'До аукціону') and @href]  120
  ${auctionUrl}  Get Element Attribute  xpath=//*[contains(text(), 'До аукціону') and @href]@href
  [Return]  ${auctionUrl}

Отримати посилання на аукціон для учасника
  [Arguments]  ${username}  ${tender_uaid}  ${lot_id}=Empty
  [Documentation]  Отримує посилання на участь в аукціоні для користувача username для лоту tender_uaid.
  ...  [Повертає] participationUrl (посилання).
  Click Element  xpath=//*[contains(text(), 'До аукціону')]
  Sleep  3
  Click Element  xpath=//*[contains(text(), 'Взяти участь в аукціоні')]
  Sleep  5
  Wait Until Page Contains Element  xpath=//*[contains(text(), 'До аукціону') and @href]  120
  ${participationUrl}  Get Element Attribute  xpath=//*[contains(text(), 'До аукціону') and @href]@href
  [Return]  ${participationUrl}

Скасувати закупівлю
  [Arguments]  ${username}  ${tender_uaid}  ${cancellation_reason}  ${path}  ${new_description}
  [Documentation]  Створює запит для скасування лоту tender_uaid, додає до цього запиту документ,
  ...  який знаходиться по шляху document, змінює опис завантаженого документа на new_description
  ...  і переводить скасування закупівлі в статус active. Цей ківорд реалізовуємо лише для процедур на цбд1.
  smarttender.Відкрити бланк скасування лоту
  Заповнити cancellation_reason для скасування лоту  ${cancellation_reason}
  Додати файл для скасування лоту  ${path}
  Заповнити doc.description для скасування лоту  ${new_description}
  Відправити запит на скасування лоту

Відкрити бланк скасування лоту
  Click Element  xpath=//button//*[contains(text(), 'Відмінити аукціон')]

Заповнити cancellation_reason для скасування лоту
  [Arguments]  ${cancellation_reason}
  Input Text  xpath=//*[@class='ivu-modal-content']//textarea  ${cancellation_reason}

Додати файл для скасування лоту
  [Arguments]  ${path}
  Choose File  xpath=//*[@class='file-container']/following-sibling::input[1]  ${path}

Заповнити doc.description для скасування лоту
  [Arguments]  ${new_description}
  Input Text  xpath=//*[@class='ivu-modal-content']//input[@type='text']  ${new_description}

Відправити запит на скасування лоту
  Click Element  xpath=//*[@class='ivu-modal-content']//button//*[contains(text(), 'Відмінити аукціон')]

Активувати процедуру
  [Arguments]  ${username}  ${tender_uaid}
  No Operation

########################################################################
###                        DOCUMENTS                                 ###
########################################################################

Отримати інформацію із документа
  [Arguments]  ${username}  ${tender_uaid}  ${doc_id}  ${field}
  [Documentation]  Отримує значення поля field документа doc_id з лоту tender_uaid для перевірки правильності відображення цього поля.
  ...  [Повертає] document['field'] (значення поля field)
  ${reply}  Отримати та обробити дані із документу  ${field}  ${doc_id}
  [Return]  ${reply}

Отримати та обробити дані із документу
  [Arguments]  ${field_name}  ${item_id}
  ${selector}  object_document_info  ${field_name}  ${item_id}
  Focus  ${selector}
  ${result}  Get Text  ${selector}
  [Return]  ${result}

Завантажити документ в ставку
  [Arguments]  ${username}  ${path}  ${tender_uaid}  ${doc_type}=documents
  [Documentation]  Завантажує документ типу doc_type, який знаходиться за шляхом path, до цінової пропозиції користувача username для тендера tender_uaid.
  ...  [Повертає] reply (словник з інформацією про завантажений документ).
  Відкрити сторінку подачі пропозиції
  Choose File  xpath=//input[@type='file'][1]  ${path}
  Подати пропозицію
  Go Back

Змінити документ в ставці
  [Arguments]  ${username}  ${tender_uaid}  ${path}  ${docid}
  [Documentation]  Змінює документ з doc_id в пропозиції користувача username для лоту tender_uaid на документ,
  ...  який знаходиться по шляху path.
  ...  [Повертає] uploaded_file (словник з інформацією про завантажений документ).
  Відкрити сторінку подачі пропозиції
  Mouse Over  xpath=//*[@class='ivu-tooltip-inner']
  Choose File  xpath=//input[@type='file'][2]  ${path}
  Подати пропозицію
  Go Back

########################################################################
###                       Price offers                               ###
########################################################################

Подати цінову пропозицію
  [Arguments]  ${username}  ${tender_uaid}  ${bid}
  [Documentation]  Подає цінову пропозицію bid до лоту tender_uaid користувачем username.
  ...  [Повертає] reply (словник з інформацією про цінову пропозицію).
  ${shouldQualify}=  Get Variable Value  ${bid['data'].qualified}
  Run Keyword If  '${shouldQualify}' != 'False'  Run Keywords
  #...  no operation
  ...  Пройти кваліфікацію для подачі пропозиції  ${username}  ${tender_uaid}  ${bid}
  ...  AND  Відкрити сторінку подачі пропозиції
  Заповнити value.amount для подачі пропозиції  ${bid.data.value.amount}
  Подати пропозицію
  Go Back

Подати пропозицію
  ${message}  Натиснути надіслати пропозицію та вичитати відповідь
  Виконати дії відповідно повідомленню  ${message}
  Wait Until Page Does Not Contain Element  ${ok button}

Відкрити сторінку подачі пропозиції
  ${location}  Get Location
  Run Keyword If  '/bid/' not in '${location}'  Run Keywords
  ...  Reload Page
  ...  AND  Click Element  xpath=//*[contains(text(), 'Подача пропозиції') or contains(text(), 'Змінити пропозицію')]
  ...  AND  Wait Until Page Contains Element  xpath=//button/*[contains(text(), 'Надіслати пропозицію')]

Заповнити value.amount для подачі пропозиції
  [Arguments]  ${value}
  ${value}  Evaluate  str(${value})
  Input Text  xpath=//*[contains(@id, 'lotAmount')]//input  ${value}

Натиснути надіслати пропозицію та вичитати відповідь
  Click Element  ${send offer button}
  Run Keyword And Ignore Error  Wait Until Page Contains Element  ${loading}
  Run Keyword And Ignore Error  Wait Until Element Is Not Visible  ${loading}  600
  ${status}  ${message}  Run Keyword And Ignore Error  Get Text  ${validation message}
  [Return]  ${message}

Виконати дії відповідно повідомленню
  [Arguments]  ${message}
  Run Keyword If  "${empty error}" in """${message}"""  Подати пропозицію
  ...  ELSE IF  "${error1}" in """${message}"""  Ignore error
  ...  ELSE IF  "${error2}" in """${message}"""  Ignore error
  ...  ELSE IF  "${error3}" in """${message}"""  Ignore error
  ...  ELSE IF  "${error4}" in """${message}"""  Ignore error
  ...  ELSE IF  "${succeed1}" in """${message}"""  Click Element  ${ok button}
  ...  ELSE IF  "${succeed2}" in """${message}"""  Click Element  ${ok button}
  ...  ELSE  Fail  Look to message above

Ignore error
  Click Element  ${ok button}
  Wait Until Page Does Not Contain Element  ${ok button}
  Sleep  30
  Подати пропозицію

Пройти кваліфікацію для подачі пропозиції
  [Arguments]  ${username}  ${tender_uaid}  ${bid}
  Відкрити бланк подачі заявки
  Додати файл для подачі заявки
  Підтвердити відповідність для подачі заявки
  Відправити заявку для подачі пропозиції та закрити валідаційне вікно
  Підтвердити заявку  ${tender_uaid}

Відкрити бланк подачі заявки
  Click Element  xpath=//button[@type='button']//*[contains(text(), 'Взяти участь')]

Додати файл для подачі заявки
  Wait Until Page Contains Element  xpath=//input[@type='file' and @accept]
  ${file_path}  ${file_name}  ${file_content}=  create_fake_doc
  Choose File  xpath=//input[@type='file' and @accept]  ${file_path}

Підтвердити відповідність для подачі заявки
  Select Checkbox  xpath=//*[@class="group-line"]//input

Відправити заявку для подачі пропозиції та закрити валідаційне вікно
  Click Element  xpath=//button[@class="ivu-btn ivu-btn-primary pull-right ivu-btn-large"]
  Wait Until Page Contains  Ваша заявка відправлена!
  Sleep  3
  Click Element  xpath=//*[contains(text(), 'Ваша заявка відправлена!')]/ancestor::*[@class='ivu-modal-content']//a
  Wait Until Element Is Not Visible  xpath=//*[contains(text(), 'Ваша заявка відправлена!')]/ancestor::*[@class='ivu-modal-content']//a

Підтвердити заявку
  [Arguments]  ${tender_uaid}
  Go To  http://test.smarttender.biz/ws/webservice.asmx/ExecuteEx?calcId=_QA.ACCEPTAUCTIONBIDREQUEST&args={"IDLOT":"${tender_uaid}","SUCCESS":"true"}&ticket=
  Wait Until Page Contains  True
  Go Back

Змінити цінову пропозицію
  [Arguments]  ${username}  ${tender_uaid}  ${fieldname}  ${fieldvalue}
  [Documentation]  Змінює поле fieldname на fieldvalue цінової пропозиції користувача username до лоту tender_uaid.
  ...  [Повертає] reply (словник з інформацією про цінову пропозицію).
  Відкрити сторінку подачі пропозиції
  Заповнити value.amount для подачі пропозиції  ${fieldvalue}
  Подати пропозицію
  Go Back

Отримати інформацію із пропозиції
  [Arguments]  ${username}  ${tender_uaid}  ${field}
  [Documentation]  Отримує значення поля field пропозиції користувача username для лоту tender_uaid.
  ...  [Повертає] bid['field'] (значення поля).
  Відкрити сторінку подачі пропозиції
  ${selector}  object_proposal_info  ${field}
  ${value}  Get Element Attribute  ${selector}
  ${reply}  Evaluate  float('${value}'.replace(" ", ""))
  Go Back
  [Return]  ${reply}

Скасувати цінову пропозицію
  [Arguments]  ${username}  ${tender_uaid}
  [Documentation]  Змінює статус цінової пропозиції до лоту tender_uaid користувача username на cancelled.
  ...  [Повертає] reply (словник з інформацією про цінову пропозицію).
  ...  Цей ківорд реалізовуємо лише для процедур на цбд1.
  Відкрити сторінку подачі пропозиції
  Скасувати пропозицію smart
  Go Back

Скасувати пропозицію smart
  ${message}  Скасувати пропозицію та вичитати відповідь
  Виконати дії відповідно повідомленню при скасуванні  ${message}
  Wait Until Page Does Not Contain Element   ${cancellation offers button}

Скасувати пропозицію та вичитати відповідь
  Wait Until Page Contains Element  ${cancellation offers button}
  Click Element  ${cancellation offers button}
  Click Element   ${cancel. offers confirm button}
  Run Keyword And Ignore Error  Wait Until Page Contains Element  ${loading}
  Run Keyword And Ignore Error  Wait Until Element Is Not Visible  ${loading}  600
  ${status}  ${message}  Run Keyword And Ignore Error  Get Text  ${validation message}
  [Return]  ${message}

Виконати дії відповідно повідомленню при скасуванні
  [Arguments]  ${message}
  Run Keyword If  """${message}""" == "${EMPTY}"  Fail  Message is empty
  ...  ELSE IF  "${cancellation error1}" in """${message}"""  Ignore cancellation error
  ...  ELSE IF  "${cancellation succeed}" in """${message}"""  Click Element  ${ok button}
  ...  ELSE  Fail  Look to message above

Ignore cancellation error
  Click Element  ${ok button}
  Wait Until Page Does Not Contain Element  ${ok button}
  Sleep  20
  Скасувати пропозицію smart

########################################################################
###                         QUESTIONS                                ###
########################################################################

Задати запитання на предмет
  [Arguments]  ${username}  ${tender_uaid}  ${item_id}  ${question}
  [Documentation]  Створює запитання з даними question до активу лоту з item_id
  ...  для лоту з tender_uaid користувачем username.
  ...  [Повертає] reply (словник з інформацією про запитання).
  Відкрити сторінку с запитаннями
  Відкрити бланк створення запитання
  Wait Until Keyword Succeeds  30  3  Вибрати предмет запитання  ${item_id}
  Заповнити title для запитання  ${question.data.title}
  Заповнити description для запитання  ${question.data.description}
  Wait Until Keyword Succeeds  1m  5s  Натиснути подати запитання
  Закрити сторінку із запитаннями

Вибрати предмет запитання
  [Arguments]  ${item_id}
  Click Element  xpath=//*[@class='ivu-select-selection']/input[@type='text']
  Click Element  xpath=//*[contains(text(), '${item_id}')]

Задати запитання на тендер
  [Arguments]  ${username}  ${tender_uaid}  ${question}
  [Documentation]  Створює запитання з даними question до лоту з tender_uaid користувачем username.
  ...  [Повертає] reply (словник з інформацією про запитання).
  Відкрити сторінку с запитаннями
  Відкрити бланк створення запитання
  Заповнити title для запитання  ${question.data.title}
  Заповнити description для запитання  ${question.data.description}
  Wait Until Keyword Succeeds  1m  5s  Натиснути подати запитання
  Закрити сторінку із запитаннями

Відкрити бланк створення запитання
  Click Element  xpath=//button//*[contains(text(), 'Поставити запитання')]

Заповнити title для запитання
  [Arguments]  ${text}
  ${selector}  Set Variable  xpath=//*[contains(text(), 'Тема')]/following-sibling::div//input
  Input Text  ${selector}  ${text}

Заповнити description для запитання
  [Arguments]  ${text}
  ${selector}  Set Variable  xpath=//*[contains(text(), 'Запитання')]/following-sibling::div//textarea
  Input Text  ${selector}  ${text}

Натиснути подати запитання
  Click Element  xpath=//button//*[contains(text(), 'Подати')]
  Wait Until Page Does Not Contain Element  xpath=//button//*[contains(text(), 'Подати')]

Отримати інформацію із запитання
  [Arguments]  ${username}  ${tender_uaid}  ${question_id}  ${field_name}
  [Documentation]  Отримує значення поля field_name із запитання з question_id в описі для тендера tender_uaid.
  ...  [Повертає] question['field_name'] (значення поля).
  Відкрити сторінку с запитаннями
  ${reply}  Отримати та обробити дані із запитання  ${field_name}  ${question_id}
  Закрити сторінку із запитаннями
  [Return]  ${reply}

Відкрити сторінку с запитаннями
  ${status}  Run Keyword And Return Status  Page Should Contain Element  xpath=//*[contains(text(), 'Без відповіді')]
  Run Keyword if  '${status}' == 'False'  Run Keywords
  ...  Run Keyword And Ignore Error  Click Element  xpath=//div[contains(text(), 'Запитання та відповіді')]
  ...  AND  Wait Until Page Contains Element  xpath=//*[contains(text(), 'Без відповіді')]

Закрити сторінку із запитаннями
  Reload Page

Отримати та обробити дані із запитання
  [Arguments]  ${field_name}  ${question_id}
  ${selector}  object_question_info  ${field_name}  ${question_id}
  Focus  ${selector}
  ${result}  Get Text  ${selector}
  ${length}  Get Length  ${result}
  Run Keyword If  ${length} == 0  Capture Page Screenshot  ${OUTPUTDIR}/my_screen{index}.png
  [Return]  ${result}

Відповісти на запитання
  [Arguments]  ${username}  ${tender_uaid}  ${answer_data}  ${question_id}
  [Documentation]  Надає відповідь answer_data на запитання з question_id до лоту tender_uaid.
  ...  [Повертає] reply (словник з інформацією про відповідь).
  Відкрити сторінку с запитаннями
  Wait Until Keyword Succeeds  30  3  Відкрити бланк дати відповідь для запитання  ${question_id}
  Заповнити answer для відповіді на запитання  ${answer_data.data.answer}  ${question_id}
  Wait Until Keyword Succeeds  30  3  Відправити відповідь на запитання  ${question_id}
  Закрити сторінку із запитаннями

Відкрити бланк дати відповідь для запитання
  [Arguments]  ${question_id}
  Click Element  xpath=//*[contains(text(), '${question_id}')]/ancestor::div[@class='ivu-card-body']//button
  Wait Until Page Contains Element  xpath=//*[contains(text(), 'касувати')]  3

Заповнити answer для відповіді на запитання
  [Arguments]  ${text}  ${question_id}
  Input Text  //*[contains(text(), '${question_id}')]/ancestor::*[@class='ivu-card-body']//textarea  ${text}

Відправити відповідь на запитання
  [Arguments]  ${question_id}
  ${selector}  Set Variable  xpath=//*[contains(text(), '${question_id}')]/ancestor::*[@class='ivu-card-body']//*[contains(text(), 'Дати відповідь')]
  Click Element  ${selector}
  Wait Until Page Does Not Contain Element  ${selector}