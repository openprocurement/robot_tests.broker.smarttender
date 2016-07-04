# -*- coding: utf-8 -
from munch import *
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

def get_filename_from_path(path):
    return  basename(path)
	
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

def convert_date(s):
    dt = parse(s, parserinfo(True, False))
    return dt.strftime('%Y-%m-%dT%H:%M:%S.%f+03:00')

def get_bid_response(value):
    return munchify({'data': {'value': {'amount': value}}})

def get_lot_response(value):
	return munchify({'data': {'value': {'amount': value}, 'id': 'bcac8d2ceb5f4227b841a2211f5cb646' }})
	
def get_claim_response(id, title, description):
    return munchify({ 'data': { 'id' : int(id), 'title': title, 'description': description}, 'access': { 'token': '' } })
	
def get_bid_status(status):
	return munchify({ 'data': { 'status': status }})
	
def get_question_data(id):
    return munchify({ 'data': { 'id': id }})
	
def convert_unit_from_smarttender_format(unit):
    map = {
        u"кг": u"кілограми"
    }
    return map[unit]

def convert_unit_to_smarttender_format(unit):
    map = {
        u"кілограми": u"кг"
    }
    return map[unit]

def convert_edi_from_starttender_format(edi):
    map = {
        u"166": u"KGM"    
    }
    return map[edi]
	
def convert_currency_from_smarttender_format(currency):
    map = {
        u"грн" : "UAH"
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