#! /usr/bin/env python
# -- coding: utf-8 --


from munch import munchify as smarttender_munchify
from iso8601 import parse_date
from dateutil.parser import parse
from dateutil.parser import parserinfo
from datetime import timedelta
from datetime import datetime
from pytz import timezone
from os.path import basename
import urllib2
import os
import string
import re

TZ = timezone(os.environ['TZ'] if 'TZ' in os.environ else 'Europe/Kiev')
number_of_tabs = 1


def get_number_of_tabs():
    return number_of_tabs


def reset_number_of_tabs():
    global number_of_tabs
    number_of_tabs = 1


def add_to_number_of_tabs(value):
    global number_of_tabs
    number_of_tabs = number_of_tabs + value


def get_now():
    return datetime.now(TZ)


def convert_datetime_to_smarttender_format(isodate):
    iso_dt = parse_date(isodate)
    date_string = iso_dt.strftime("%d.%m.%Y %H:%M")
    return date_string


def convert_date_to_smarttender_format(isodate):
    iso_dt = parse_date(isodate)
    date_string = iso_dt.strftime("%d.%m.%Y")
    return date_string


def get_minutes_to_add(date_end):
    date = parse(date_end)
    now = get_now()
    seconds = (date - now).total_seconds()
    minutes = (seconds % 3600) // 60
    if minutes < 7:
        return 7
    return 0


def strip_string(s):
    return s.strip()


def adapt_data(tender_data):
    tender_data.data.procuringEntity['name'] = u"PROZORRO. Продажі"
    tender_data.data.procuringEntity['identifier']['legalName'] = u"PROZORRO. Продажі"
    tender_data.data.procuringEntity['identifier']['id'] = u"111111111111111"
    for item in tender_data.data['items']:
        if item.unit['name'] == u"метри квадратні":
            item.unit['name'] = u"м.кв."
        elif item.unit['name'] == u"штуки":
            item.unit['name'] = u"шт"
    return tender_data


def convert_date(s):
    dt = parse(s, parserinfo(True, False))
    return dt.strftime('%Y-%m-%dT%H:%M:%S.%f+03:00')


def convert_date_offset_naive(s):
    dt = parse(s, parserinfo(True, False))
    return dt.strftime('%Y-%m-%d')


def get_bid_response(value):
    return smarttender_munchify({'data': {'value': {'amount': value}}})


def get_lot_response(value):
    return smarttender_munchify({'data': {'value': {'amount': value}, 'id': 'bcac8d2ceb5f4227b841a2211f5cb646'}})


def get_claim_response(id, title, description):
    return smarttender_munchify({'data': {'id': int(id), 'title': title, 'description': description}, 'access': {'token': ''}})


def get_bid_status(status):
    return smarttender_munchify({'data': {'status': status}})


def get_question_data(id):
    return smarttender_munchify({'data': {'id': id}})


def convert_unit_to_smarttender_format(unit):
    map = {
        u"кілограми": u"кг",
        u"послуга": u"умов.",
        u"умов.": u"умов.",
        u"усл.": u"умов.",
        u"метри квадратні": u"м.кв.",
        u"м.кв.": u"м.кв.",
        u"шт": u"шт"
    }
    return map[unit]


def convert_edi_from_starttender_format(edi):
    map = {
        u"166": u"KGM",
        u"992": u"E48",
        u"12": u"MTK",
        u"796": u"H87"
    }
    return map[edi]


def convert_unit_from_smarttender_format(unit):
    map = {
        u"кг": u"кілограми",
        u"умов.": u"усл.",
        u"усл.": u"усл.",
        u"м.кв.": u"м.кв.",
        u"шт": u"шт"
    }
    return map[unit]


def convert_currency_from_smarttender_format(currency):
    map = {
        u"980": "UAH"
    }
    return map[currency]


def convert_country_from_smarttender_format(country):
    map = {
        u"УКРАЇНА": u"Україна"
    }
    return map[country]


def convert_cpv_from_smarttender_format(cpv):
    map = {
        u"ДК 021:2015": "CPV"
    }
    return map[cpv]


def auction_field_info(field):
    if "items" in field:
        item_id = int(re.search("\d",field).group(0)) + 1
        splitted = field.split(".")
        splitted.remove(splitted[0])
        result = string.join(splitted, '.')
        map = {
            "description": u"""(//*[@data-qa="page-block-auction-items"]//*[contains(@class, "margin-top-")])[{}]/div//span[@class="key key-value" and text()="Назва позиції"]/../following-sibling::div[contains(@class, "second")]/span""",
            "classification.scheme": u"""(//*[@data-qa="page-block-auction-items"]//*[contains(@class, "margin-top-")])[{}]/div//span[@class="key key-value" and text()="Класифікація"]/../following-sibling::div[contains(@class, "second")]/span""",
            "classification.id": u"""(//*[@data-qa="page-block-auction-items"]//*[contains(@class, "margin-top-")])[{}]/div//span[@class="key key-value" and text()="Класифікація"]/../following-sibling::div[contains(@class, "second")]/span""",
            "classification.description": u"""(//*[@data-qa="page-block-auction-items"]//*[contains(@class, "margin-top-")])[{}]/div//span[@class="key key-value" and text()="Класифікація"]/../following-sibling::div[contains(@class, "second")]/span""",
            "unit.name": u"""(//*[@data-qa="page-block-auction-items"]//*[contains(@class, "margin-top-")])[{}]/div//span[@class="key key-value" and text()="Кількість"]/../following-sibling::div[contains(@class, "second")]/span""",
            "quantity": u"""(//*[@data-qa="page-block-auction-items"]//*[contains(@class, "margin-top-")])[{}]/div//span[@class="key key-value" and text()="Кількість"]/../following-sibling::div[contains(@class, "second")]/span""",
        }
        return (map[result]).format(item_id)
    elif "questions" in field:
        question_id = re.search("\d",field).group(0)
        splitted = field.split(".")
        splitted.remove(splitted[0])
        result = string.join(splitted, '.')
        map = {
            "description": "div.q-content",
            "title": """qqqqq""""",
            "answer": "div.answer div:eq(2)"
        }
        return ("div.question:Contains('{0}') ".format(question_id)) + map[result]
    elif "awards" in field:
        award_id = re.search("\d",field).group(0)
        splitted = field.split(".")
        splitted.remove(splitted[0])
        result = string.join(splitted, '.')
        map = {
            "status": "div#auctionResults div.row.well:eq({0}) span.info_award_status:eq(0)"
        }
        return map[result].format(award_id)
    else:
        map = {
            "dgfID": """//*[@data-qa="auction-dgfId"]""",
            "title": """//*[@data-qa="auction-title"]""",
            "description": """//*[@data-qa="auction-description"]""",
            "value.amount": """//*[@data-qa="initial-amount"]""",
            "value.currency": """//*[@data-qa="initial-amount"]""",
            "value.valueAddedTaxIncluded": """//*[@data-qa="initial-amount"]""",
            "auctionID": """//*[@data-qa="cdbNumber"]""",
            "procuringEntity.name": """//*[@data-qa="auction-seller"]/../div[@class="ivu-poptip"]""",
            "enquiryPeriod.startDate": "span.info_enquirysta",
            "enquiryPeriod.endDate": u"""//*[@data-qa="page-block-conditions"]//*[@class="margin-bottom-16 ivu-row with-border" and contains(., "Період уточнень")]//span[not(@data-qa)]""",
            "tenderPeriod.startDate": "span.info_enquirysta",
            "tenderPeriod.endDate": u"""//*[@data-qa="page-block-conditions"]//*[@class="margin-bottom-16 ivu-row with-border" and contains(., "Прийом пропозицій")]//span[not(@data-qa)]""",
            "auctionPeriod.startDate": "span.info_dtauction:eq(0)",
            "auctionPeriod.endDate": "span.info_dtauctionEnd:eq(0)",
            "status": "span.info_tender_status:eq(0)",
            "minimalStep.amount": u"""//*[@data-qa="page-block-conditions"]//*[@class="margin-bottom-16 ivu-row with-border" and contains(., "Мінімальний крок аукціону")]//span[not(@data-qa)]""",
            "cancellations[0].reason": "span.info_cancellation_reason",
            "cancellations[0].status": "span.info_cancellation_status",
            "eligibilityCriteria": "span.info_eligibilityCriteria",
            "contracts[-1].status": "span.info_contractStatus",
            "dgfDecisionID": "span.info_dgfDecisionId",
            "dgfDecisionDate": "span.info_dgfDecisionDate",
            "tenderAttempts": "span.info_tenderAttempts",
            "procurementMethodType": """//*[contains(@data-qa, "bidding-type")]/div"""
        }
        return map[field]


def document_fields_info(field,docId,is_cancellation_document):
    map = {
        "description": "span.info_attachment_description:eq(0)",
        "title": "span.info_attachment_title:eq(0)",
        "content": "span.info_attachment_title:eq(0)",
        "type": "span.info_attachment_type:eq(0)"
    }
    if str(is_cancellation_document) == "True":
        result = map[field]
    else:
        result = ("div.row.document:contains('{0}') ".format(docId))+map[field]
    return result


def map_to_smarttender_document_type(doctype):
    map = {
        u"x_presentation": u"Презентація",
        u"tenderNotice": u"Паспорт торгів",
        u"x_nda": u"Договір NDA",
        u"technicalSpecifications": u"Публічний паспорт активу",
        u"x_dgfAssetFamiliarization": u"",
        u"x_dgfPublicAssetCertificate": u""
    }
    return map[doctype]


def map_from_smarttender_document_type(doctype):
    map = {
        u"Презентація" : u"x_presentation",
        u"Паспорт торгів" : u"tenderNotice",
        u"Договір NDA": u"x_nda",
        u"Технические спецификации": u"technicalSpecifications",
        u"Порядок ознайомлення з майном/активом у кімнаті даних": u"x_dgfAssetFamiliarization",
        u"Посиланння на Публічний Паспорт Активу": u"x_dgfPublicAssetCertificate",
        u"Місце та форма прийому заявок на участь, банківські реквізити для зарахування гарантійних внесків": u"x_dgfPlatformLegalDetails",
        u"\u2015": u"none",
        u"Ілюстрація": u"illustration",
        u"Віртуальна кімната": u"vdr",
        u"Публічний паспорт активу": u"x_dgfPublicAssetCertificate"
    }
    return map[doctype]


def string_contains(check_string,value):
    if value in check_string:
        ret = "true"
    else:
        ret = "false"
    return ret


def convert_result(field, value):
    if "value." in field:
        search = re.search(u"(?P<amount>.+,[0-9]{2}) (?P<currency>[^\.]+)\. (?P<VAT>(без ПДВ)|(з ПДВ))", value)
        if field == "value.amount":
            ret = float(search.group("amount").replace(" ", "").replace(",", "."))
        elif field == "value.currency":
            currency = search.group("currency")
            ret = "UAH" if currency == u"грн" else u"ошибка"
        elif field == "value.valueAddedTaxIncluded":
            vat = search.group("VAT").replace(" ", "").replace(",", ".")
            ret = False if vat == u"без ПДВ" else True
    elif "classification." in field:
        search = re.search("^(?P<scheme>.+): (?P<id>[0-9]+-[0-9]+) . (?P<description>.+)$", value)
        if "classification.id" in field:
            ret = search.group("id")
        elif "classification.scheme" in field:
            ret = search.group("scheme")
        elif "classification.description" in field:
            ret = search.group("description")
    elif field == "minimalStep.amount":
        search = re.search(u"^(?P<percent>[^%]+)% або (?P<amount>.+) грн", value)
        ret = float(search.group("amount").replace(" ", "").replace(",", "."))
    elif "quantity" in field:
        search = re.search("^(?P<quantity>[^ ]+) (?P<unit>.*)$", value)
        ret = int(search.group("quantity"))
    elif "unit.name" in field:
        search = re.search("^(?P<quantity>[^ ]+) (?P<unit>.*)$", value)
        ret = search.group("unit")
    elif "auctionPeriod.startDate" in field:
        ret = convert_date(value)
    elif "tenderPeriod." in field:
        search = re.search(u"з (?P<startDate>.+) по (?P<endDate>.+)", value)
        if "startDate" in field:
            ret = convert_date(search.group("startDate"))
        elif "endDate" in field:
            ret = convert_date(search.group("endDate"))
    elif "tenderAttempts" in field:
        ret = int(value)
    elif "dgfDecisionDate" in field:
        ret = convert_date_offset_naive(value)
    elif "procurementMethodType" in field:
        ret = u"dgfFinancialAssets" if value == u"Продаж права вимоги за кредитними договорами" else u"aaaaaaaaaaaaaaa"
    else:
        ret = value
    return ret


def auction_screen_field_selector(field):
    map = {
        "value.amount": "table[data-name='INITAMOUNT'] input",
        "minimalstep.amount": "table[data-name='MINSTEP'] input",
        "auctionPeriod.startDate": "table[data-name='DTAUCTION'] input",
        "eligibilityCriteria": "",
        "guarantee": "table[data-name='GUARANTEE_AMOUNT'] input",
        "dgfDecisionID": "table[data-name='DGFDECISION_NUMBER'] input",
        "dgfDecisionDate": "table[data-name='DGFDECISION_DATE'] input",
        "tenderAttempts":"table[data-name='ATTEMPT'] input:eq(1)",
        "title":"table[data-name='TITLE'] input",
        "description":"table[data-name='DESCRIPT'] textarea",
        "procuringEntity.identifier.legalName":"div[data-name='ORG_GPO_2'] input:eq(0)",
        "tenderPeriod.startDate":"",
        "guarantee.amount":"table[data-name='GUARANTEE_AMOUNT'] input",
        "procuringEntity.address.postalCode": "table[data-name='POSTALCODE'] input",
        "procuringEntity.address.streetAddress": "table[data-name='STREETADDR'] input",
        "procuringEntity.address.region": "table[data-name='CITY_KOD''] input"
    }
    return map[field]


def question_field_info(field, id):
    map = {
        "description": "div.q-content",
        "title": "div.title-question span.question-title-inner",
        "answer": "div.answer div:eq(2)"
    }
    return ("div.question:Contains('{0}') ".format(id)) + map[field]


def convert_bool_to_text(variable):
    return str(variable).lower()


def download_file(url,download_path):
    response = urllib2.urlopen(url)
    file_content = response.read()
    open(download_path, 'a').close()
    f = open(download_path, 'w')
    f.write(file_content)
    f.close()


def unescape_link(link):
    return str(link).replace("%20"," ")


def normalize_index(first,second):
    if first == "-1":
        return "2"
    else:
        return str(int(first) + int(second))
