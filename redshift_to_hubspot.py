import calendar
import json
import logging
# import psycopg2
import psycopg2.extras
import pytz
import requests
import sys
import time

from airflow.hooks.postgres_hook import PostgresHook
from airflow.models import BaseOperator
from airflow.plugins_manager import AirflowPlugin
from airflow.utils.decorators import apply_defaults
from datetime import datetime, timedelta, date

logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)
handler = logging.StreamHandler(sys.stdout)
handler.setLevel(logging.INFO)
formatter = logging.Formatter(
    '%(asctime)s - %(name)s - %(levelname)s - %(message)s'
    )
handler.setFormatter(formatter)
logger.addHandler(handler)
todaytimestamp = int(datetime.now().timestamp() * 1000)

def check_postgres():
    src = PostgresHook(postgres_conn_id="dw03", schema="shipstation");
    src_conn = src.get_conn()
    cursor = src_conn.cursor(cursor_factory=psycopg2.extras.DictCursor)
    cursor.execute(sql)
    results = cursor.fetchall()

class change_manager(object):

    changequeue = []
    lastid = ""

    def queue_acct_changes(self, id, payload):
        # Changes sent to this get formatted into a variable that's identical
        # to the list/dict combo found on the batch_create_or_update
        # example @ hubspot docs. It will later get sent as a dict in
        # send_contacts.

        # This fires one time per unique ID
        change_counter = 0

        for property in payload:
            if change_counter == 0 and len(manager.changequeue) == 0:
                manager.changequeue = [{
                    "vid": str(id),
                    'properties': [{
                        'property':  property,
                        'value': payload[property]
                        }]
                    }]
                change_counter += 1
            elif change_counter == 0 and len(manager.changequeue) > 0:
                manager.changequeue.append({
                    'vid': str(id),
                    'properties': [{
                        'property': property,
                        'value': payload[property]
                    }]
                })
                logger.debug("Manager.changequeue length: '{0}'"
                             .format(len(manager.changequeue)))
                logger.debug("Change counter: ".format(change_counter))
                change_counter += 1
            elif change_counter > 0:
                manager.changequeue[len(manager.changequeue)-1]['properties']\
                                    .append({
                                            'property': property,
                                            'value': payload[property]
                                            })
                change_counter += 1

            else:
                logger.error("problem with the changequeue logic. Current " +
                             "variable: '{0}'".format(manager.changequeue))
                quit()

        if len(manager.changequeue) == 100:
            logger.debug("Changequeue @ 100: ".format(manager.changequeue))
            client.send_contacts(manager.changequeue)
        else:
            logger.debug("Change length: '{0}'"
                         .format(len(manager.changequeue)))


class hs(object):
    rate = 9
    # How often do we get to make more API calls, in seconds.
    callsperrate = 9
    # how many calls are we allowed to send per the rate above
    bucket = callsperrate
    # How many calls are left within the time period
    lasttime = int(time.time())
    # When did we last reset the API call timer
    hsapikey = ""

    def check_the_bucket(self):
        # Our account is limited to 10 calls per 10 seconds.
        # This is a call throttler function
        while True:
            if hs.bucket == 0:
                timenow = int(time.time())
                if timenow >= hs.lasttime + hs.rate:
                    hs.lasttime = timenow
                    hs.bucket = hs.callsperrate
                time.sleep(1)
            else:
                break
        hs.bucket -= 1
        logger.debug("Bucket used: '{0}'".format(hs.bucket))

    def send_contacts(self, contactdict):

        if len(contactdict) > 100:
            logger.error("More than 100 contacts sent to send_contacts")
            sys.exit("Exiting")

        url = "https://api.hubapi.com/contacts/v1/contact/batch"
        headers = {
            'Content-Type': "application/json",
            }
        auth = {"hapikey": client.hsapikey}

        response = requests.post(
            url,
            json=contactdict,
            headers=headers,
            params=auth)

        if response.status_code != 202:
            logger.warning("Response Text: '{0}'".format(response.text))
            logger.warning("Response Code: '{0}'".format(response.status_code))
            logger.warning("Url: '{0}'".format(response.url))
            logger.warning("Contactdict: '{0}'".format(contactdict))
            exit("Cannot continue, see logs.")
        manager.changequeue = []

    def get_contact(self, email):

        client.check_the_bucket()

        hssearch = requests.get(
            "https://api.hubapi.com/contacts/v1/contact/email/" +
            email + "/profile?hapikey=" + client.hsapikey)
        logger.debug(hssearch.status_code)
        logger.debug(hssearch.text)
        if hssearch.status_code > 200:

            logger.debug(
                "Probably a redacted account, not processing: '{0}'"
                .format(email))
            logger.debug("Text: '{0}'".format(hssearch.text))
            logger.debug("Status code: '{0}'".format(hssearch.status_code))
            return None
        else:
            hsjson = hssearch.json()
            results = {
                'id': hsjson.get('vid'),
                'canceldate': hsjson.get('properties', {})
                                    .get('cancel_date', {})
                                    .get('value'),
                'actdate': hsjson.get('properties', {})
                                 .get('trial_activation_date', {})
                                 .get('value'),
                'affcode': hsjson.get('properties', {})
                                 .get('affiliate_code', {})
                                 .get('value'),
                'refcode': hsjson.get('properties', {})
                                 .get('referral_code', {})
                                 .get('value'),
                'plan': hsjson.get('properties', {})
                              .get('plan', {})
                              .get('value'),
                'sellerid': hsjson.get('properties', {})
                            .get('seller_id', {})
                            .get('value'),
                'trialenddate': hsjson.get('properties', {})
                                      .get('trial_end_date', {})
                                      .get('value'),
                'couponcode': hsjson.get('properties', {})
                                    .get('offer_code', {})
                                    .get('value'),
                'country': hsjson.get('properties', {})
                                 .get('country', {})
                                 .get('value'),
                'subscribedate': hsjson.get('properties', {})
                                       .get('subscribe_date', {})
                                       .get('value'),
                'verified': hsjson.get('properties', {})
                                  .get('account_email_verified', {})
                                  .get('value'),
                'intrial': hsjson.get('properties', {})
                                 .get('in_trial', {})
                                 .get('value')
            }
            return results


def get_number_of_days_to_sync(weekday):
    return 1000
    if weekday == 5:
        return 180
    elif weekday == 6:
        return 0
    else:
        return 1


def get_active_major_accounts(sync_days):
    # Get all active major accounts
    src = PostgresHook(postgres_conn_id='dw03', schema='shipstation')
    src_conn = src.get_conn()

    cursor = src_conn.cursor(cursor_factory=psycopg2.extras.DictCursor)

    sql = "SELECT seller.canceldate AS canceldate, \
        seller.companyname AS company, \
        seller.contactname AS contactname, \
        seller.privateemail AS email, \
        billingplan.name AS planname, \
        seller.phone AS phone, \
        seller.sellerid AS sellerid, \
        billingplan.code AS plan, \
        seller.trialenddate AS trialenddate, \
        seller.homecountry AS country, \
        seller.referralcode AS refcode, \
        seller.affiliatecode AS affcode, \
        seller.couponcode AS couponcode, \
        seller.activationdate AS actdate, \
        seller.subscribedate AS subscribedate \
        FROM seller \
        INNER JOIN billingplan on \
        seller.billingplanid=billingplan.billingplanid \
        WHERE canceldate is null AND \
        seller.active='true' AND \
        seller.excludereasonid is null AND \
        billingplan.billingplanid < 98 AND\
        seller.createdate > current_date - INTERVAL '" + \
        str(sync_days) + " days' limit 1000"

    try:
        cursor.execute(sql)
        results = cursor.fetchall()
        logger.info("SQL was successful, '{0}' results".format(len(results)))
        return results
    except Exception as e:
        logger.error(e)
        sys.exit("Problem with database connection, exiting")


def pst_datetime_to_cstdate_epoch(inputdate):
    # Mgmt stores in PST datetime while hubspot stores in CST date (no time).
    # We convert PST to CST and then chop off the time. It's rough but it's
    # good enough for now. Hubspot also stores in microseconds, hence the *1000
    if inputdate is None:
        logger.debug("Inputdate is none")
        return None
    else:
        timezone = pytz.timezone('US/Pacific')
        date_with_timezone = timezone.localize(inputdate)
        targettz = pytz.timezone('UTC')
        utcdatetime = date_with_timezone.astimezone(targettz)
        utcdate = utcdatetime.date()
        midnightutc = datetime.combine(utcdate, datetime.min.time())
        midnightutctimestamp = int(
            calendar.timegm(midnightutc.utctimetuple()) * 1000
            )
        logger.debug("returning midnightutctimestamp: '{0}'"
                     .format(midnightutctimestamp))
        return midnightutctimestamp


def compare_integers(hubspot, mgmt, fieldname=None):
    try:
        hubspot = int(hubspot)
    except ValueError as e:
        logger.debug("compare_integers: Changing hubspot input to None: '{0}'"
                     .format(e))
        hubspot = None
    except TypeError as e:
        logger.debug("compare_integers: Hubspot already None '{0}'".format(e))
    try:
        mgmt = int(mgmt)
    except ValueError as e:
        logger.debug("compare_integers: Changing mgmt input to None: '{0}'"
                     .format(e))
        mgmt = ""
    except TypeError as e:
        logger.debug("compare_integers: Mgmt already none: '{0}'".format(e))

    logger.debug("Mgmt: '{0}', HS:{1}".format(mgmt, hubspot))

    if hubspot != mgmt:
        return mgmt
    else:
        return "No Change"


def compare_strings(hubspot, mgmt, fieldname=None):

    try:
        hubspot = str(hubspot)
    except ValueError as e:
        logger.debug("Compare strings: Changing hubspot input to empty: '{0}'"
                     .format(ValueError))
        hubspot = ""
    try:
        mgmt = str(mgmt)
    except ValueError as e:
        logger.debug("Compare strings: Changing mgmt input to empty: '{0}'"
                     .format(ValueError))
        mgmt = ""

    if fieldname == "plan":
        mgmt = "_" + mgmt

    if mgmt == "None":
        mgmt = ""

    if hubspot != mgmt:
        return mgmt
    else:
        return "No Change"


def is_mgmt_email_verified():
    if mgmtacct['actdate']:
        is_verified = "true"
    pass


def is_mgmt_in_trial(subscribedate, canceldate, trialenddate, hstrialend):
    # Little bit different because mgmt doesn't have in_trial
    try:
        if subscribedate is None and \
                canceldate is None and \
                todaytimestamp < pst_datetime_to_cstdate_epoch(trialenddate):
            return "true"
        else:
            return "false"
    except Exception as e:
        return "false"


def analyze_hubspot_and_redshift_differences(majoraccounts):
    # builds a dictionary of changes needed, discarding non-changes
    # If there's a needed change in a single account, sends it to
    # manager.changequeue
    for mgmtacct in majoraccounts:
        logger.debug("Current account: '{0}'".format(mgmtacct['email']))
        if mgmtacct['email'] is not None:

            hsacct = client.get_contact(mgmtacct['email'])

            if hsacct is not None:
                analysis = {
                    'seller_id': compare_integers(
                        hsacct['sellerid'],
                        mgmtacct['sellerid']
                        ),
                    'country': compare_strings(
                        hsacct['country'],
                        mgmtacct['country']
                        ),
                    'plan': compare_strings(
                        hsacct['plan'],
                        mgmtacct['plan'],
                        "plan"
                        ),
                    'referral_code': compare_strings(
                        hsacct['refcode'],
                        mgmtacct['refcode'],
                        "referral code"
                        ),
                    'affiliate_code': compare_strings(
                        hsacct['affcode'],
                        mgmtacct['affcode'],
                        "affiliate code"
                        ),
                    'offer_code': compare_strings(
                        hsacct['couponcode'],
                        mgmtacct['couponcode']
                        ),
                    'trial_activation_date': compare_integers(
                        hsacct['actdate'],
                        pst_datetime_to_cstdate_epoch(mgmtacct['actdate'])
                        ),
                    'cancel_date': compare_integers(
                        hsacct['canceldate'],
                        pst_datetime_to_cstdate_epoch(mgmtacct['canceldate']),
                        ),
                    'trial_end_date': compare_integers(
                        hsacct['trialenddate'],
                        pst_datetime_to_cstdate_epoch(mgmtacct['trialenddate'])
                    ),
                    'in_trial': compare_strings(
                        hsacct['intrial'],
                        is_mgmt_in_trial(
                            mgmtacct['subscribedate'],
                            mgmtacct['canceldate'],
                            mgmtacct['trialenddate'],
                            hsacct['intrial']
                            )
                    )
                }
                account_changes = {}
                logger.debug("Analysis: '{0}'".format(analysis))
                for setting in analysis:
                    if analysis[setting] != "No Change":
                        if len(account_changes) == 0:
                            account_changes = {
                                setting: analysis[setting]
                            }
                        else:
                            account_changes[setting] = analysis[setting]
                if len(account_changes) > 1:
                    logger.debug("Number of account changes: '{0}', " +
                                 "change list: '{1}'"
                                 .format(len(account_changes), account_changes)
                                 )
                    manager.queue_acct_changes(hsacct['id'], account_changes)
    if len(manager.changequeue) > 0:
        # If everything's done, make sure we send the remainder of the
        # queued changes.
        client.send_contacts(manager.changequeue)
    logger.info("Completed successfully.")


class HubspotOperator(BaseOperator):
    @apply_defaults
    def __init__(self, apikey, *args, **kwargs):
        self.apikey = apikey
        super(HubspotOperator, self).__init__(*args, **kwargs)

    def execute(self, context):

        client.hsapikey = self.apikey
        main_process()


def main_process():

    results = check_postgres()
    for x in results:
        print (x)
    # sync_days = get_number_of_days_to_sync(datetime.today().weekday())
    # majoraccounts = get_active_major_accounts(sync_days)
    # logger.info("Mgmt reports '{0}' accounts within the last '{1}' days."
    #             .format(len(majoraccounts), sync_days))
    # analyze_hubspot_and_redshift_differences(majoraccounts)


client = hs()
manager = change_manager()


if __name__ == "__main__":
    main_process()
