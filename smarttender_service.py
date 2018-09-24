#!/usr/bin/env python
# -*- coding: utf-8 -*-
# ==============
#      Main script file
# ==============
import sys

reload(sys)
sys.setdefaultencoding('utf-8')

from munch import munchify as smarttender_munchify
from iso8601 import parse_date
from dateutil.parser import parse
from dateutil.parser import parserinfo
from pytz import timezone
import urllib2
import os
import re
import requests
import ast


def get_tender_data(link):
    r = requests.get(link).text
    return r


TZ = timezone(os.environ['TZ'] if 'TZ' in os.environ else 'Europe/Kiev')
number_of_tabs = 1


def convert_datetime_to_smarttender_format_minute(isodate):
    iso_dt = parse_date(isodate)
    date_string = iso_dt.strftime("%d.%m.%Y %H:%M")
    return date_string


def convert_datetime_to_kot_format(isodate):
    iso_dt = parse_date(isodate)
    date_string = iso_dt.strftime("%d.%m.%Y %H:%M:%S")
    return date_string


def convert_date(s):
    dt = parse(s, parserinfo(True, False))
    return dt.strftime('%Y-%m-%dT%H:%M:%S+03:00')


def convert_tzdate_synch(isodate):
    iso_dt = parse_date(isodate)
    date_string = iso_dt.strftime('%Y-%m-%d %H:%M:%S')
    return date_string


def adapt_data_assets(tender_data):
    tender_data.data.assetCustodian.name = u'ТОВАРИСТВО З ОБМЕЖЕНОЮ ВІДПОВІДАЛЬНІСТЮ "ЕКСПРІМ"'
    tender_data.data.assetCustodian.identifier.legalName = u'ТОВАРИСТВО З ОБМЕЖЕНОЮ ВІДПОВІДАЛЬНІСТЮ "ЕКСПРІМ"'
    tender_data.data.assetCustodian.identifier.id = "30441106"
    tender_data.data.assetCustodian.contactPoint.name = u"Прохоров И.А."
    tender_data.data.assetCustodian.contactPoint.telephone = "044-222-15-48"
    tender_data.data.assetCustodian.contactPoint.email = "kliukvin@it.ua"
    return tender_data


def map_to_smarttender_document_type(doctype):
    map = {
        u"x_presentation": u"Презентація",
        u"tenderNotice": u"Паспорт торгів",
        u"x_nda": u"Договір NDA",
        u"technicalSpecifications": u"Публічний паспорт активу",
        u"financial_documents": u"Цінова пропозиція",
        u"qualification_documents": u"Документи, що підтверджують кваліфікацію",
        u"eligibility_documents": u"Документи, що підтверджують відповідність",
    }
    return map[doctype]


def map_from_smarttender_document_type(doctype):
    map = {
        u"Презентація": u"x_presentation",
        u"Паспорт торгів": u"tenderNotice",
        u"Договір NDA": u"x_nda",
        u"Технические спецификации": u"technicalSpecifications",
        u"Порядок ознайомлення з майном/активом у кімнаті даних": u"x_dgfAssetFamiliarization",
        u"Посиланння на Публічний Паспорт Активу": u"x_dgfPublicAssetCertificate",
        u"Місце та форма прийому заявок на участь, банківські реквізити для зарахування гарантійних внесків":
            u"x_dgfPlatformLegalDetails",
        u"\u2015": u"none",
        u"Ілюстрація": u"illustration",
        u"Віртуальна кімната": u"vdr",
        u"Публічний паспорт активу": u"x_dgfPublicAssetCertificate"
    }
    return map[doctype]


def download_file(url, download_path):
    response = urllib2.urlopen(url)
    file_content = response.read()
    open(download_path, 'a').close()
    f = open(download_path, 'w')
    f.write(file_content)
    f.close()


def synchronization(string):
    list = re.search(u'{"DateStart":"(?P<date_start>[\d\s\:\.]+?)",'
                     u'"DateEnd":"(?P<date_end>[\d\s\:\.]*?)",'
                     u'"WorkStatus":"(?P<work_status>[\w+]+?)",'
                     u'"Success":(?P<success>[\w+]+?)}', string)
    date_start = list.group('date_start')
    date_end = list.group('date_end')
    work_status = list.group('work_status')
    success = list.group('success')
    return date_start, date_end, work_status, success


def object_field_info(field):
    map = {
        "assetID": "css=[data-qa='cdbNumber']",
        "date": "xpath=//*[contains(text(), 'Дата створення')]/../../div[2]/span",
        "rectificationPeriod.endDate": "xpath=//*[@class='key' and contains(text(), 'Період коригування')]/../../div[2]/span",
        "status": "css=.action-block-item.text-center.bold",
        "title": "css=h3>span",
        "description": "css=div.ivu-card-body .ivu-row>span",
        "decisions[0].title": """xpath=//*[contains(text(), "Загальна інформація")]/..//*[contains(text(), "Рішення про приватизацію об'єкту")]/../following-sibling::div""",
        "decisions[0].decisionDate": """xpath=//*[contains(text(), "Загальна інформація")]/..//*[contains(text(), "Рішення про приватизацію об'єкту")]/../following-sibling::div""",
        "decisions[0].decisionID": """xpath=//*[contains(text(), "Загальна інформація")]/..//*[contains(text(), "Рішення про приватизацію об'єкту")]/../following-sibling::div""",
        "assetHolder.name": """xpath=//*[contains(text(), "Балансоутримувач")]/..//*[contains(text(), "Назва")]/..//following-sibling::div""",
        "assetHolder.identifier.scheme": """xpath=//*[contains(text(), "Балансоутримувач")]/..//*[contains(text(), "Код агентства реєстрації")]/..//following-sibling::div""",
        "assetHolder.identifier.id": """xpath=//*[contains(text(), "Балансоутримувач")]/..//*[contains(text(), "Код ЄДРПОУ")]/..//following-sibling::div""",
        "assetCustodian.identifier.scheme": """xpath=//*[contains(text(), "Орган приватизації")]/..//*[contains(text(), "Код агентства реєстрації")]/..//following-sibling::div""",
        "assetCustodian.identifier.id": """xpath=//*[contains(text(), "Орган приватизації")]/..//*[contains(text(), "Код ЄДРПОУ")]/..//following-sibling::div""",
        "assetCustodian.identifier.legalName": """xpath=//*[contains(text(), "Орган приватизації")]/..//*[contains(text(), "Назва")]/..//following-sibling::div""",
        "assetCustodian.contactPoint.name": """xpath=//*[contains(text(), "Орган приватизації")]/..//*[contains(text(), "ПІБ")]/..//following-sibling::div""",
        "assetCustodian.contactPoint.telephone": """xpath=//*[contains(text(), "Орган приватизації")]/..//*[contains(text(), "Телефон")]/..//following-sibling::div""",
        "assetCustodian.contactPoint.email": """xpath=//*[contains(text(), "Орган приватизації")]/..//*[contains(text(), "Email")]/..//following-sibling::div""",
        "assetCustodian.address.countryName": """xpath=//*[contains(text(), "Орган приватизації")]/..//*[contains(text(), "Адреса")]/..//following-sibling::div""",
        "documents[0].documentType": "xpath=//*[contains(text(), 'Загальна інформація')]/../div[6]/div[1]",
        "items[0].address.countryName": "xpath=(//*[contains(text(), 'Документи')]/..//*[@class='ivu-row']//p)[3]",
        "dateModified": """xpath=//*[contains(text(), "Загальна інформація")]/ancestor::*[@class="ivu-card-body"]//*[contains(text(), "Дата модифікації у ЦБД")]/../following-sibling::div""",
    }
    return map[field]


def convert_object_result(field, value):
    global response
    if field == "rectificationPeriod.endDate":
        list = re.search(u'з\s(?P<start_date>[\d\.\s:]+)\sпо\s(?P<end_date>[\d\.\s:]+)', value)
        end_date = list.group('end_date')
        if 'endDate' in field:
            response = convert_date(end_date)
    elif field == "status":
        response = map_object_status(value)
    elif "decisions[0]" in field:
        list = re.search(u'(?P<decisions>.+\.)\s(?P<decisionID>[\d\-]+)\sвід\s(?P<date>[\d\.\s\:]+)\.', value)
        if "title" in field:
            response = list.group("decisions")
        elif "decisionDate" in field:
            date = list.group("date")
            response = convert_date(date)
        elif "decisionID" in field:
            response = list.group("decisionID")
    elif "documentType" in field:
        response = map_documentType(value)
    elif "dateModified" == field:
        response = convert_date(value)
    else:
        response = value
    return response


def asset_field_info(field, id):
    map = {
        "address.countryName": "xpath=//*[contains(text(), '{0}')]/../../../div[4]/div[2]".format(id),
        "description": """xpath=//*[contains(text(), "{0}")]/ancestor::*[@class="ivu-card-body"]//*[text()="Опис об'єкту"]/../following-sibling::div""".format(id),
        "classification.scheme": """xpath=//*[contains(text(), "{0}")]/ancestor::*[@class="ivu-card-body"]//*[text()="Класифікація"]/../following-sibling::div""".format(id),
        "classification.id": """xpath=//*[contains(text(), "{0}")]/ancestor::*[@class="ivu-card-body"]//*[text()="Класифікація"]/../following-sibling::div""".format(id),
        "unit.name": """xpath=//*[contains(text(), "{0}")]/ancestor::*[@class="ivu-card-body"]//*[text()="Обсяг"]/../following-sibling::div""".format(id),
        "quantity": """xpath=//*[contains(text(), "{0}")]/ancestor::*[@class="ivu-card-body"]//*[text()="Обсяг"]/../following-sibling::div""".format(id),
        "registrationDetails.status": """xpath=//*[contains(text(), "{0}")]/ancestor::*[@class="ivu-card-body"]//*[text()="Реєстрація"]/../following-sibling::div""".format(id),
    }
    return map[field]


def convert_asset_result(field, value):
    global response
    if "address" in field:
        list = re.search(
            u'(?P<countryName>.+)\.\s(?P<region>.+\.)\.\s(?P<locality>.+)\.\s(?P<postalCode>\d+)\.\s(?P<streetAddress>.+)\.',
            value)
        if "countryName" in field:
            response = list.group("countryName")
    elif "unit" in field or "quantity" == field:
        list = re.search(u'(?P<quantity>[\d\.]+)\s(?P<name>.+)', value)
        if "name" in field:
            response = list.group("name")
        else:
            response = float(list.group("quantity"))
    elif "registrationDetails.status" == field:
        response = map_object_status(value)
    elif "classification" in field:
        list = re.search(u'((?P<scheme>.+)\:\s+)+(?P<id>[\d\-]+)\s\-\s(?P<description>.+)', value)
        if "scheme" in field:
            response = list.group("scheme")
        elif "id" in field:
            response = list.group("id")
        elif "description" in field:
            response = list.group("description")
    else:
        response = value
    return response


def ss_lot_field_info(field):
    id = 1
    if "auctions[" in field:
        list = re.search('auctions\[(?P<id>\d)\]\.(?P<field>.+)', field)
        field = "auctions." + list.group('field')
        id = int(list.group('id')) + 1
    map = {
        "lotID": "css=[data-qa='cdbNumber']",
        "title": "css=h3>span",
        "status": "css=.action-block-item.text-center.bold",
        "description": "css=div.ivu-card-body .ivu-row>span",
        "date": """xpath=//*[contains(text(), 'Загальна інформація')]/..//*[text()="Дата створення лоту"]/../following-sibling::div""",
        "rectificationPeriod.endDate": """xpath=//*[contains(text(), 'Загальна інформація')]/..//*[text()="Період коригування"]/../following-sibling::div""",
        "dateModified": """xpath=//*[contains(text(), "Загальна інформація")]/ancestor::*[@class="ivu-card-body"]//*[text()="Дата модифікації у ЦБД"]/../following-sibling::div""",

        "lotHolder.name": 'xpath=//*[text()="Балансоутримувач"]/..//*[text()="Назва"]/../following-sibling::div',
        "lotHolder.identifier.scheme": 'xpath=//*[text()="Балансоутримувач"]/..//*[text()="Код агентства реєстрації"]/../following-sibling::div',
        "lotHolder.identifier.id": 'xpath=//*[text()="Балансоутримувач"]/..//*[text()="Код ЄДРПОУ"]/../following-sibling::div',

        "lotCustodian.identifier.scheme": 'xpath=//*[text()="Орган приватизації"]/..//*[text()="Код агентства реєстрації"]/../following-sibling::div',
        "lotCustodian.identifier.id": 'xpath=//*[text()="Орган приватизації"]/..//*[text()="Код ЄДРПОУ"]/../following-sibling::div',
        "lotCustodian.identifier.legalName": 'xpath=//*[text()="Орган приватизації"]/..//*[text()="Назва"]/../following-sibling::div',
        "lotCustodian.contactPoint.name": 'xpath=//*[text()="Орган приватизації"]/..//*[text()="ПІБ"]/../following-sibling::div',
        "lotCustodian.contactPoint.telephone": 'xpath=//*[text()="Орган приватизації"]/..//*[text()="Телефон"]/../following-sibling::div',
        "lotCustodian.contactPoint.email": 'xpath=//*[text()="Орган приватизації"]/..//*[text()="Email"]/../following-sibling::div',

        "decisions[0].decisionDate": """xpath=//*[text()="Загальна інформація"]/..//*[text()="Рішення про затверждення умов продажу лоту"]/../following-sibling::div""",
        "decisions[0].decisionID": """xpath=//*[text()="Загальна інформація"]/..//*[text()="Рішення про затверждення умов продажу лоту"]/../following-sibling::div""",
        "decisions[1].title": """xpath=//*[text()="Загальна інформація"]/..//*[text()="Рішення про приватизацію об'єкту"]/../following-sibling::div""",
        "decisions[1].decisionDate": """xpath=//*[text()="Загальна інформація"]/..//*[text()="Рішення про приватизацію об'єкту"]/../following-sibling::div""",
        "decisions[1].decisionID": """xpath=//*[text()="Загальна інформація"]/..//*[text()="Рішення про приватизацію об'єкту"]/../following-sibling::div""",

        "auctions.procurementMethodType": """xpath=//*[contains(text(), 'Умови') and contains(text(), 'аукціону')][{0}]/following-sibling::div//*[contains(text(), "Тип торгів")]/../following-sibling::div""".format(
            id),
        "auctions.status": """xpath=//*[contains(text(), 'Умови') and contains(text(), 'аукціону')][{0}]/following-sibling::div//*[contains(text(), "Статус")]/../following-sibling::div""".format(
            id),
        "auctions.tenderAttempts": """xpath=//*[contains(text(), 'Умови') and contains(text(), 'аукціону')][{0}]""".format(
            id),
        "auctions.value.amount": """xpath=//*[contains(text(), 'Умови') and contains(text(), 'аукціону')][{0}]/following-sibling::div//*[contains(text(), "Стартова ціна об’єкта")]/../following-sibling::div""".format(
            id),
        "auctions.minimalStep.amount": """xpath=//*[contains(text(), 'Умови') and contains(text(), 'аукціону')][{0}]/following-sibling::div//*[contains(text(), "Крок аукціону")]/../following-sibling::div""".format(
            id),
        "auctions.guarantee.amount": """xpath=//*[contains(text(), 'Умови') and contains(text(), 'аукціону')][{0}]/following-sibling::div//*[contains(text(), "Розмір гарантійного внеску")]/../following-sibling::div""".format(
            id),
        "auctions.registrationFee.amount": """xpath=//*[contains(text(), 'Умови') and contains(text(), 'аукціону')][{0}]/following-sibling::div//*[contains(text(), "Реєстраційний внесок")]/../following-sibling::div""".format(
            id),
        "auctions.tenderingDuration": """xpath=//*[contains(text(), 'Умови') and contains(text(), 'аукціону')][{0}]/following-sibling::div//*[contains(text(), "Період між аукціонами")]/../following-sibling::div""".format(
            id),
        "auctions.auctionPeriod.startDate": """xpath=//*[contains(text(), 'Умови') and contains(text(), 'аукціону')][{0}]/following-sibling::div//*[contains(text(), "Дата проведення аукціону")]/../following-sibling::div""".format(
            id),
        "auctions.auctionID": "xpath=//*[text()='Посилання на процедуру']/../following-sibling::div",
    }
    return map[field]


def convert_lot_result(field, value):
    response_ = value
    if "rectificationPeriod" in field:
        list = re.search(u"з (?P<startDate>[\d\s:.]+) по (?P<endDate>[\d\s:.]+)", value)
        if "endDate" in field:
            date = list.group("endDate")
        elif "startDate" in field:
            date = list.group("startDate")
        response_ = convert_date(date)
    elif "date" in field:
        response_ = convert_date(value)
    elif "status" in field:
        response_ = map_object_status(value)
    elif "decisions" in field:
        list = re.search(u'(?P<title>.+\.)? ?(?P<decisionID>[\d-]+) від (?P<decisionDate>[\d\s:.]+)\.', value)
        if "title" in field:
            response_ = list.group("title")
        elif "decisionID" in field:
            response_ = list.group("decisionID")
        elif "decisionDate" in field:
            value = list.group("decisionDate")
            response_ = convert_date(value)
    elif "auctions" in field:
        if "procurementMethodType" in field:
            response_ = map_object_status(value)
        elif "status" in field:
            response_ = map_object_status(value)
        elif "tenderAttempts" in field:
            list = re.search(u"Умови\s(?P<id>\d)\sаукціону", value)
            response_ = int(list.group('id'))
        elif "amount" in field:
            value = value.replace(",", "")
            list = re.search(u"(?P<amount>[\d.]+) UAH[ без ПДВ]?", value)
            response_ = float(list.group('amount'))
        elif "tenderingDuration" in field:
            if "30" in value:
                response_ = "P30D"
        elif "auctionPeriod.startDate" in field:
            response_ = convert_date(value)
        elif "auctionID" in field:
            response_ = re.findall('UA.+', value)[0]
    elif "dateModified" == field:
        response_ = convert_date(value)
    return response_


def map_object_status(doctype):
    map = {
        u"Опубліковано. Очікування інформаційного повідомлення": "pending",
        u"Опубліковано": "pending",
        u"Перевірка доступності об'єкту": "verification",
        u"Об'єкт реєструється.": "registering",
        u"Об'єкт зареєстровано": "complete",
        u"Виключено з переліку": "deleted",

        # procurementMethodType
        u"Аукціон з умовами, без умов за методом покрокового зниження стартової ціни та подальшого подання цінових пропозицій": "sellout.insider",
        u"Аукціон з умовами, без умов": "sellout.english",

        # Condition Auction
        u"Заплановано": "scheduled",
        u"Відбувається": "active",
        u"Аукціон відбувся": "complete",
        u"Торги скасовано": "cancelled",
        u"Торги не відбулися": "unsuccessful",
        u"Оренда майна": "deleted",

        # Auction
        u"Прийняття заяв на участь": "pending.activation",
        u"Аукціон": 'active.auction',
        u"Очікується опублікування протоколу": "active.qualification",
        u"Очікується опублікування договору": "active.awarded",
        u"Аукціон відмінено": "cancelled",
        u"Аукціон не відбувся": "unsuccessful",

        # Lots
        u"Об’єкт виставлено на продаж": "active.salable",
        u"Об’єкт продано": "sold",
        u"Аукціон завершено. Об’єкт не продано": "pending.dissolution",
        u"Об’єкт не продано": "dissolved",
        u"Об’єкт виключено": "deleted",
        u"Аукціон завершено": "pending.sold",
        u"Публікація інформаційного повідомлення": "composing",
        u"Відхилений після перевірки": "invalid",
        u"Аукціон відбувся. Кваліфікація": "active.contracting",
        u"Відправлено на видалення": "pending.deleted",
    }
    return map[doctype]


def map_documentType(doctype, reverse=None):
    map = {
        u"Ілюстрація": "illustration",
        u"Інформація про об’єкт малої приватизації": "technicalSpecifications",
        u"Рішення про затвердження переліку об’єктів, що підлягають приватизації (внесення змін до переліку об’єктів)": "notice",
        u"Інформація про оприлюднення інформаційного повідомлення": "informationDetails",
        u"Презентація": "x_presentation",
    }
    if reverse is not None:
        for key, value in map.items():
            if value == doctype:
                return key
    else:
        return map[doctype]


def map_documentType_auction(doctype, reverse=None):
    map = {
        u"Умови продажу та/або експлуатації об’єкта приватизації": "evaluationCriteria",
        u"Рішення аукціонної комісії": "notice",
        u"Інформація про об’єкт малої приватизації": "technicalSpecifications",
        u"Ілюстрація": "illustration",
        u"Презентація": "x_presentation",
    }
    if reverse is not None:
        for key, value in map.items():
            if value == doctype:
                return key
    else:
        return map[doctype]


def get_id_from_tender_href(href, lot=None):
    if lot == None:
        list = re.search(u'.+?/assets/(?P<id>.{32})[\?opt_pretty=1]?', href)
    else:
        list = re.search(u'.+?/lots/(?P<id>.{32})[\?opt_pretty=1]?', href)
    id = list.group('id')
    return id


def object_tender_info(field):
    map = {
        "auctionID": "xpath=//h4/following-sibling::a",
        "title": "xpath=//h3[contains(text(), '[ТЕСТУВАННЯ]')]",
        "description": "css=.text-justify",
        "minNumberOfQualifiedBids": "xpath=//*[contains(text(), 'Мінімальна кількість учасників')]/../following-sibling::div",
        "procurementMethodType": "xpath=//h5[text()='Тип процедури']//following-sibling::p",
        "procuringEntity.name": "xpath=//h5[text()='Продавець']//following-sibling::div",
        "value.amount": "css=.action-block-item h4",
        "minimalStep.amount": "xpath=//*[contains(text(), 'Мінімальний крок аукціону')]/../following-sibling::div",
        "guarantee.amount": "xpath=//*[contains(text(), 'Гарантійний внесок')]/../following-sibling::div",
        "registrationFee.amount": "xpath=//*[contains(text(), 'Оплата за участь')]/../following-sibling::div",
        "tenderPeriod.endDate": "xpath=//*[contains(text(), 'Прийом пропозицій')]/../following-sibling::div",
        "cancellations[0].status": "xpath=//*[@class='ivu-card-body']/h4",
        "status": "xpath=//*[@class='ivu-card-body']/h4",
        "cancellations[0].reason": "xpath=//*[contains(text(), 'Причина скасування')]/../following-sibling::div",

    }
    return map[field]


def convert_tender_result(field, value):
    if field == "procurementMethodType":
        response = map_object_status(value)
    elif field == 'date':
        response = convert_date(value)
    elif "amount" in field:
        if "value" in field:
            list = re.search(u'(?P<value>[\d\s\.]+) (?P<tr>.+)\. (?P<ty>з ПДВ)', value)
        elif "minimalStep" in field:
            list = re.search(u'.+ або (?P<value>[\d\s\.,]+) грн.', value)
        elif "guarantee" in field or "registrationFee" in field:
            list = re.search(u'(?P<value>[\d\s\.]+) грн.', value)
        value = list.group('value')
        response = float((value.replace(" ", "")).replace(",", "."))
    elif field == 'tenderPeriod.endDate':
        list = re.search(u'з (?P<startDate>[\d\.\s\:]+) по (?P<endDate>[\d\.\s\:]+)', value)
        value = list.group('endDate')
        response = convert_date(value)
    elif field == 'minNumberOfQualifiedBids':
        response = int(value)
    elif field == 'status':
        response = map_object_status(value)
    else:
        response = value
    return response


def object_item_info(field, id):
    map = {
        "description": """xpath=//*[contains(text(), '{0}')]""".format(id),
        "unit.name": """xpath=//*[contains(text(), '{0}')]/ancestor::div[@class='ivu-card-body']//*[text()='Кількість']/../following-sibling::div""".format(id),
        "quantity": """xpath=//*[contains(text(), '{0}')]/ancestor::div[@class='ivu-card-body']//*[text()='Кількість']/../following-sibling::div""".format(id),
    }
    return map[field]


def convert_item_result(field, value):
    if field == "unit.name" or field == 'quantity':
        list = re.search(u'(?P<value>[\d\s\.]+) (?P<name>.+)', value)
        if field == "unit.name":
            response = list.group('name')
        elif field == 'quantity':
            response = float(list.group('value'))
    else:
        response = value
    return response


def object_question_info(field, id):
    map = {
        "title": "xpath=//*[contains(text(), '{0}')]".format(id),
        "description": "xpath=//*[contains(text(), '{0}')]/../../following-sibling::div".format(id),
        "answer": "xpath=(//*[contains(text(), '{0}')]/ancestor::div[@class='ivu-row']/following-sibling::div)[3]".format(
            id),
    }
    return map[field]


def object_proposal_info(field):
    map = {
        "value.amount": "xpath=//*[contains(@id, 'lotAmount')]//input@value",
    }
    return map[field]


def object_document_info(field, id):
    map = {
        "title": "xpath=//a[contains(text(), '{0}') and @class]".format(id),
        "description": "xpath=//*[contains(text(), '{0}')]/following-sibling::*[contains(text(), 'Опис документу')]/span".format(
            id),
    }
    return map[field]


def ret_scheme(id):
    scheme = {
        "101": {
            "title": "101 - окреме нерухоме майно",
            "classifier": [
                "CAV-PS"
            ],
            "classifierId": [
                "04000000-8"
            ],
            "detailedClassification": True,
            "additionalClassifier": "DK018",
            "additionalClassifierId": "125"
        },
        "102": {
            "title": "102 - окреме рухоме майно",
            "classifier": [
                "CPV"
            ],
            "classifierId": [
                "42990000-2"
            ],
            "detailedClassification": False,
            "additionalClassifier": "",
            "additionalClassifierId": ""
        },
        "200": {
            "title": "200 - єдині майнові комплекси державних підприємств, їх структурні підрозділи",
            "classifier": [
                "CAV-PS"
            ],
            "classifierId": [
                "05100000-6"
            ],
            "detailedClassification": True,
            "additionalClassifier": "DK018",
            "additionalClassifierId": "230"
        },
        "301": {
            "title": "301 - пакети акцій акціонерних товариств, утворених у процесі приватизації або корпоратизації",
            "classifier": [
                "CAV-PS"
            ],
            "classifierId": [
                "08110000-0"
            ],
            "detailedClassification": False,
            "additionalClassifier": "",
            "additionalClassifierId": ""
        },
        "302": {
            "title": "302 - акції (частки), що належать державі у статутному капіталі господарських організацій, заснованих на базі об'єднання майна різних форм власності",
            "classifier": [
                "CAV-PS"
            ],
            "classifierId": [
                "08160000-5"
            ],
            "detailedClassification": False,
            "additionalClassifier": "",
            "additionalClassifierId": ""
        },
        "400": {
            "title": "400 - об’єкти незавершеного будівництва, законсервовані об’єкти",
            "classifier": [
                "CAV-PS"
            ],
            "classifierId": [
                "04000000-8"
            ],
            "detailedClassification": True,
            "additionalClassifier": "DK018",
            "additionalClassifierId": "242"
        },
        "500": {
            "title": "500 - об’єкти соціально-культурного призначення",
            "classifier": [
                "CAV-PS"
            ],
            "classifierId": [
                #"04200000-0"
            ],
            "detailedClassification": False,
            "additionalClassifier": "DK018",
            "additionalClassifierId": "126"
        },
        "900": {
            "title": "900 - інші об'єкти",
            "classifier": [
                "CPV",
                "CAV-PS"
            ],
            "classifierId": [
                "06000000-2",
                "03000000-1",
                "09000000-3",
                "14000000-1",
                "15000000-8",
                "16000000-5",
                "18000000-9",
                "19000000-6",
                "22000000-0",
                "24000000-4",
                "30000000-9",
                "31000000-6",
                "32000000-3",
                "33000000-0",
                "34000000-7",
                "35000000-4",
                "37000000-8",
                "38000000-5",
                "39000000-2",
                "41000000-9",
                "42000000-6",
                "43000000-3",
                "44000000-0"
            ],
            "detailedClassification": True,
            "additionalClassifier": "DK018",
            "additionalClassifierId": "127"
        }
    }

    ret_key = id
    ret_bool = None

    for key, value in scheme.iteritems():
        for j in scheme[key]['classifierId']:
            if j == id:
                ret_key = key
                ret_bool = scheme[key]['detailedClassification']
                break

    if ret_bool is None:
        sep_id = id[0:3]
        if sep_id == '041':
            sep_id = '040'
        elif sep_id == '042':
            sep_id = '040'
        for key, value in scheme.iteritems():
            for j in scheme[key]['classifierId']:
                if j.startswith(sep_id):
                    ret_key = key
                    ret_bool = scheme[key]['detailedClassification']
                    break

    return ret_key, ret_bool


def object_contract_info(field):
    map = {
        "status": "//*[@data-qa='contractStatus']",
        "status_in_contract": "//*[@data-qa='contractStatus']",
        "description_in_contract": "//*[@data-qa='contractDescription']",
    }
    return map[field]


def convert_contract_result(field, value):
    if "status" in field:
        response = map_contract_status(value)
    else:
        response = value
    return response


def map_contract_status(doctype):
    map = {
        u"Очікується оплата": "active.confirmation",
        u"Очікується оплата": "active.payment",
        u"Договір оплачено. Очікується наказ": "active.approval",
        u"Період виконання умов продажу (період оскарження)": "active",
        u"Приватизація об’єкта завершена": "pending.terminated",
        u"Приватизація об’єкта завершена": "terminated",
        u"Приватизація об’єкта неуспішна": "pending.unsuccessful",
        u"Приватизація об’єкта неуспішна": "unsuccessful",
    }
    return map[doctype]
