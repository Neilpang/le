#!/usr/bin/env sh

#Support local mail app

#MAIL_FROM="yyyy@gmail.com"
#MAIL_TO="yyyy@gmail.com"

mail_send() {
  _subject="$1"
  _content="$2"
  _statusCode="$3" #0: success, 1: error 2($RENEW_SKIP): skipped
  _debug "_subject" "$_subject"
  _debug "_content" "$_content"
  _debug "_statusCode" "$_statusCode"

  if _exists "sendmail"; then
    _MAIL_BIN="sendmail"
  elif _exists "ssmtp"; then
    _MAIL_BIN="ssmtp"
  elif _exists "mutt"; then
    _MAIL_BIN="mutt"
  elif _exists "mail"; then
    _MAIL_BIN="mail"
  else
    _err "Please install sendmail, ssmtp, mutt or mail first."
    return 1
  fi

  MAIL_FROM="${MAIL_FROM:-$(_readaccountconf_mutable MAIL_FROM)}"
  if [ -n "$MAIL_FROM" ]; then
    if ! _contains "$MAIL_FROM" "@"; then
      _err "It seems that the MAIL_FROM=$MAIL_FROM is not a valid email address."
      return 1
    fi

    _saveaccountconf_mutable MAIL_FROM "$MAIL_FROM"
  fi

  MAIL_TO="${MAIL_TO:-$(_readaccountconf_mutable MAIL_TO)}"
  if [ -z "$MAIL_TO" ]; then
    MAIL_TO="$(_readaccountconf ACCOUNT_EMAIL)"
    _info "The MAIL_TO is not set, so use the account email: $MAIL_TO"
  fi
  _saveaccountconf_mutable MAIL_TO "$MAIL_TO"

  contenttype="text/plain; charset=utf-8"
  subject="=?UTF-8?B?$(echo "$_subject" | _base64)?="
  result=$({ _mail_body | _mail_send; } 2>&1)

  if [ $? -ne 0 ]; then
    _debug "mail send error."
    _err "$result"
    return 1
  fi

  _debug "mail send success."
  return 0
}

_mail_send() {
  case "$_MAIL_BIN" in
    sendmail)
      if [ -n "$MAIL_FROM" ]; then
        "$_MAIL_BIN" -f "$MAIL_FROM" "$MAIL_TO"
      else
        "$_MAIL_BIN" "$MAIL_TO"
      fi
      ;;
    ssmtp)
      "$_MAIL_BIN" "$MAIL_TO"
      ;;
    mutt | mail)
      "$_MAIL_BIN" -s "$_subject" "$MAIL_TO"
      ;;
  esac
}

_mail_body() {
  if [ "$_MAIL_BIN" = "sendmail" ] || [ "$_MAIL_BIN" = "ssmtp" ]; then
    if [ -n "$MAIL_FROM" ]; then
      echo "From: $MAIL_FROM"
    fi

    echo "To: $MAIL_TO"
    echo "Subject: $subject"
    echo "Content-Type: $contenttype"
    echo
  fi

  echo "$_content"
}
