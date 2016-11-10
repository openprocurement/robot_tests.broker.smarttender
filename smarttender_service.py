from munch import munchify as smarttender_munchify
from iso8601 import parse_date
from dateutil.parser import parse
from dateutil.parser import parserinfo
from datetime import timedelta
from datetime import datetime
from pytz import timezone
from os.path import basename
import os
TZ = timezone(os.environ['TZ'] if 'TZ' in os.environ else 'Europe/Kiev')

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
    tender_data.data.procuringEntity['name'] = u"ФОНД ГАРАНТУВАННЯ ВКЛАДІВ ФІЗИЧНИХ ОСІБ"
    tender_data.data.procuringEntity['identifier']['legalName'] = u"ФОНД ГАРАНТУВАННЯ ВКЛАДІВ ФІЗИЧНИХ ОСІБ"
    tender_data.data.procuringEntity['identifier']['id'] = u"111111111111111"
    tender_data.data['items'][0].deliveryAddress.locality = u"Київ"
    unitname = tender_data.data['items'][0].unit['name']
    if unitname == u"послуга":
        tender_data.data['items'][0].unit['name'] = u"усл."
    elif unitname == u"метри квадратні":
        tender_data.data['items'][0].unit['name'] = u"м.кв."   
    elif unitname == u"штуки":
        tender_data.data['items'][0].unit['name'] = u"шт"
    return tender_data
    
def convert_date(s):
    dt = parse(s, parserinfo(True, False))
    return dt.strftime('%Y-%m-%dT%H:%M:%S.%f+02:00')

def get_bid_response(value):
    return smarttender_munchify({'data': {'value': {'amount': value}}})

def get_lot_response(value):
    return smarttender_munchify({'data': {'value': {'amount': value}, 'id': 'bcac8d2ceb5f4227b841a2211f5cb646' }})
    
def get_claim_response(id, title, description):
    return smarttender_munchify({ 'data': { 'id' : int(id), 'title': title, 'description': description}, 'access': { 'token': '' } })
    
def get_bid_status(status):
    return smarttender_munchify({ 'data': { 'status': status }})
    
def get_question_data(id):
    return smarttender_munchify({ 'data': { 'id': id }})
    
def convert_unit_to_smarttender_format(unit):
    map = {
        u"кілограми": u"кг",
        u"послуга": u"умов.",
        u"усл.": u"умов.",
        u"метри квадратні": u"м.кв.",
        u"м.кв.": u"м.кв.",
        u"шт":u"шт"
    }
    return map[unit]

def convert_edi_from_starttender_format(edi):
    map = {
        u"166": u"KGM",
        u"992": u"E48",
        u"12": u"MTK",
        u"796":u"H87"
    }
    return map[edi]
    
def convert_unit_from_smarttender_format(unit):
    map = {
        u"кг": u"кілограми",
        u"умов.": u"усл.",
        u"усл.": u"послуга",
        u"м.кв.": u"м.кв.",
        u"шт":u"шт"
    }
    return map[unit]
    
def convert_currency_from_smarttender_format(currency):
    map = {
        u"980" : "UAH"
    }
    return map[currency]
    
def convert_country_from_smarttender_format(country):
    map = {
         u"УКРАЇНА" : u"Україна"
    }
    return map[country]
    
def convert_cpv_from_smarttender_format(cpv):
    map = {
        u"ДК 021:2015" : "CPV"
    }
    return map[cpv]

def auction_field_info(field):
    map = {
        "dgfID": "span.info_dgfId",
        "title": "span.info_orderItem",
        "description": ".container-fluid .page-header .col-sm-7 span:eq(0)",
        "value.amount": "span.info_budget:eq(0)",
        "value.currency": "span.info_currencyId",
        "value.valueAddedTaxIncluded": "span.info_withVat",
        "auctionID": "span.info_tendernum",
        "procuringEntity.name": "span.info_organization",
        "enquiryPeriod.startDate": "span.info_enquirysta",
        "enquiryPeriod.endDate": "span.info_ddm",
        "tenderPeriod.startDate": "span.info_enquirysta",
        "tenderPeriod.endDate": "span.info_ddm",
        "auctionPeriod.startDate": "span.info_dtauction:eq(0)",
        "auctionPeriod.endDate": "span.info_dtauctionEnd:eq(0)",
        "status": "span.info_tender_status:eq(0)",
        "minimalStep.amount": "span.info_minstep",
        "items[0].description": "span[data-itemid]:eq(0) span.info_name",
        "items[0].classification.scheme": "span[data-itemid]:eq(0) span.info_cpv",
        "items[0].classification.id": "span[data-itemid]:eq(0) span.info_cpv_code",
        "items[0].classification.description": "span[data-itemid]:eq(0) span.info_cpv_name",
        "items[0].unit.name": "span[data-itemid]:eq(0) span.info_snedi",
        "items[0].unit.code": "span[data-itemid]:eq(0) span.info_edi",
        "items[0].quantity": "span[data-itemid]:eq(0) span.info_count",
        "cancellations[0].reason": "span.info_cancellation_reason",
        "cancellations[0].status": "span.info_cancellation_status"
    }
    return map[field]

def document_fields_info(field):
    map = {
        "description": "span.info_cancellation_attachment_description",
        "title": "span.info_cancellation_attachment_name"
    }
    return map[field]

def string_contains_cancellation(value):
    if "cancellations" in value:
        ret = "true"
    else:
        ret = "false"
    return ret

def convert_result(field, value):
    if field == "value.amount" or field == "minimalStep.amount":
        ret = float(value)
    elif "quantity" in field:
        ret = int(value)
    elif field == "value.valueAddedTaxIncluded":
        ret = value == "True"
    elif field == "value.currency":
        ret = convert_currency_from_smarttender_format(value)
    elif "unit.code" in field:
        ret = convert_edi_from_starttender_format(value)
    elif "unit.name" in field:
        ret = convert_unit_from_smarttender_format(value)
    elif "auctionPeriod.startDate" in field:
        ret = convert_date(value)
    elif "tenderPeriod.endDate" in field:
        ret = convert_date(value)
    else:
        ret = value
    return ret