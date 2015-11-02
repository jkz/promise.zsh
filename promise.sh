# TODO send error messages to the right stream
PROMISE_ROOT=~/.promises

join() {
  echo "$*"
}

split() {
  read str

  saveIFS="$IFS"
  IFS="$delimiter"
  splits=($str)
  IFS="$saveIFS"

  echo $splits
}

random_string() {
  # Linux
  # cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1

  # OSX
  cat /dev/urandom | env LC_CTYPE=C tr -cd 'a-f0-9' | head -c 32
}

_promise_path() {
  local name

  name=$1

  echo $PROMISE_ROOT/$name
}

_promise_is_promise() {
  local name
  local promise

  name=$1
  promise=$(_promise_path $name)

  [[ -z "$name" ]] && [[ -f "$promise" ]]
}

_promise_state() {
  local promise

  promise=$1

  [[ -f $promise/value ]] && echo "resolved" && return 0
  [[ -f $promise/reason ]] && echo "rejected" && return 0
  echo "pending"
}

_promise_new() {
  local name
  local callbacks
  local on_fulfilled
  local on_rejected
  local promise

  name=$1
  # TODO reroll for clashes
  [[ -n "$name" ]] || name=$(random_string)

  promise=$(_promise_path $name)

  [[ -f "$promise" ]] && echo "Promise $name exists" && return 1

  mkdir -p $promise
  touch $promise/on_fulfilled
  touch $promise/on_rejected

  echo $promise
}

_promise_resolve() {
  # TODO run this async
  local promise
  local value

  promise=$1
  shift
  value="$*"

  [[ -f $promise/value ]] && echo "Already resolved" && return 1
  [[ -f $promise/reason ]] && echo "Already rejected" && return 2
  [[ "$value" == "$promise" ]] && echo "Can't resolve self" && return 3

  echo $value > $promise/value

  [[ -f $promise/on_fulfilled ]] || return 0
  . $promise/on_fulfilled

  echo $promise
}

_promise_reject() {
  local promise
  local reason

  promise=$1
  shift
  reason="$*"

  [[ -f $promise/value ]] && echo "Already resolved" && return 1
  [[ -f $promise/reason ]] && echo "Already rejected" && return 2
  [[ "$reason" == "$promise" ]] && echo "Can't reject self" && return 3

  echo $reason > $promise/reason

  [[ -f $promise/on_rejected ]] || return 0
  . $promise/on_rejected

  echo $promise
}

_promise_handler() {
  local promise
  local action
  local value

  promise=$1
  action=$2
  value=$3

  # TODO wrap this in a "try/catch block" so it doesn't break the chain
  # TODO make sure that this gets the exit status of the value action
  echo " \
value=\$($action \$(cat $value)) \
if [[ \$? -eq 0 ]] \
then \
  echo _promise_resolve \"$promise\" \$value \
  _promise_resolve \"$promise\" \$value \
else \
  echo REJECT $promise \
  _promise_reject "$promise" \$? \
fi \
"
}


_promise_then() {
  local promise
  local new_promise
  local on_fulfilled
  local on_rejected
  local value
  local reason

  promise=$1
  new_promise=$(_promise_new)

  shift

  echo $* | cut -d ',' -f1 | read on_fulfilled
  echo $* | cut -d ',' -f2 | read on_rejected

  if [[ -f "$promise/value" ]]
  then
    value=$(cat $promise/value)
    [[ -n $on_fulfilled ]] && value=$($on_fulfilled $value)
    _promise_resolve $new_promise value
  elif [[ -f $promise/reason ]]
  then
    reason=$(cat $promise/reason)
    [[ -n $on_rejected ]] && _promise_resolve $new_promise $($on_rejected $reason) || _promise_reject $new_promise reason
  else
    [[ -n "$on_fulfilled" ]] && _promise_handler "$new_promise" "$on_fulfilled" "$promise/value" >> $promise/on_fulfilled
    [[ -n "$on_rejected" ]] && _promise_handler "$new_promise" "$on_rejected" "$promise/reason" >> $promise/on_rejected
  fi

  echo $new_promise
}

_promise_cat() {
  local promise

  promise=$1

  echo $promise && echo
  [[ -f $promise/value ]] && echo $promise/value && cat $promise/value && echo
  [[ -f $promise/reason ]] && echo $promise/reason && cat $promise/reason && echo
  [[ -f $promise/on_resolved ]] && echo $promise/on_resolved && cat $promise/on_resolved && echo
  [[ -f $promise/on_fulfilled ]] && echo $promise/on_fulfilled && cat $promise/on_fulfilled && echo
}

promise() {
  local name

  name=$1

  _promise_is_promise $name && _promise_path $name || _promise_new $name
}

resolve() {
  local name

  name=$1
  shift

  promise $name | _resolve $*
}

reject() {
  local name

  name=$1

  promise $name | _reject $*
}

promise_cat() {
  local name

  name=$1

  promise $name | _promise_cat $*
}

_then() {
  local promise

  read promise

  _promise_then $promise $*
}

_catch() {
  _then , $*
}

_always() {
  _then $*, $*
}

_resolve() {
  local promise

  read promise

  _promise_resolve $promise $*
}

_reject() {
  local promise

  read promise

  _promise_reject $promise $*
}

_state() {
  local promise

  read promise

  _promise_state $promise $*
}
