#!/usr/bin/env python
from __future__ import print_function

import os
import cgi
import cgitb
import smtplib

from email.mime.text import MIMEText

SENDER_ADDRESS = 'mail@masida.nl'
RECIPIENT_ADDRESS = 'mp@mpster.nl'
REDIRECT_TO = "/index.html#success"


def send_mail(sender, recipient, subject, body):
    msg = MIMEText(body)
    msg['Subject'] = subject
    msg['From'] = sender
    msg['To'] = recipient

    smtpconn = smtplib.SMTP('localhost')
    smtpconn.sendmail(sender, [recipient], msg.as_string())
    smtpconn.quit()

def render_redirect(redirect_to):
    print("Status: 303 See Other")
    print("Location: {}".format(redirect_to))
    print()

def render_error(error_msg):
    print("Status: 500 Internal Server Error")
    print("Content-type: text/html")
    print()
    print("Error!")
    print(error_msg)

def main():
    lines = []
    form = cgi.FieldStorage()
    for var in form.keys():
        lines.append("{}: {}".format(var, form[var].value))
    lines.append("IP address: {}".format(os.environ["REMOTE_ADDR"]))

    body = """Het contact formulier op mpster.nl is verstuurd met de volgende waarden:

{}

Fijne dag!""".format("\n".join(lines))

    send_mail(
        SENDER_ADDRESS,
        RECIPIENT_ADDRESS,
        "Contact formulier mpster.nl",
        body)

    render_redirect(REDIRECT_TO)
        
if __name__ == '__main__':
    cgitb.enable(display=0, logdir="/run/cgi/")
    main()
