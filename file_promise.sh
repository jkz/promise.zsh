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

promise::path() {
  local name

  name=$1

  echo $PROMISE_ROOT/$name
}

promise::is_promise() {
  local name
  local promise

  name=$1
  promise=$(promise::path $name)

  [[ -z "$name" ]] && [[ -f "$promise" ]]
}

promise::state() {
  local promise

  promise=$1

  [[ -f $promise/value ]] && echo "resolved" && return 0
  [[ -f $promise/reason ]] && echo "rejected" && return 0
  echo "pending"
}

promise::new() {
  local name
  local callbacks
  local on_fulfilled
  local on_rejected
  local promise

  name=$1
  # TODO reroll for clashes
  [[ -n "$name" ]] || name=$(random_string)

  promise=$(promise::path $name)

  [[ -f "$promise" ]] && echo "Promise $name exists" && return 1

  mkdir -p $promise
  touch $promise/on_fulfilled
  touch $promise/on_rejected

  echo $promise
}

promise::resolve() {
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

promise::reject() {
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

promise::handler() {
  local promise
  local action
  local value

  promise=$1
  action=$2
  value=$3

  # TODO wrap this in a "try/catch block" so it doesn't break the chain

  echo "value=\$($action \$(cat $value))"
  # TODO make sure that this gets the exit status of the value action
  echo "if \$?"
  echo "then"
  echo "  resolve "$promise" \$value"
  echo "else"
  echo "  reject "$promise" \$?"
  echo "fi"
}


promise::then() {
  local promise
  local new_promise
  local on_fulfilled
  local on_rejected

  promise=$1
  new_promise=$(promise::new)

  shift

  echo $* | cut -d ',' -f1 | read on_fulfilled
  echo $* | cut -d ',' -f2 | read on_rejected

  if [[ -n $promise/value ]]
  then
    promise::resolve $new_promise $($on_resolved $(cat $promise/value))
  elif [[ -n $promise/reason ]]
  then
    promise::reject $new_promise $($on_rejected $(cat $promise/reason))
  else
  then
    [[ -n "$on_fulfilled" ]] && handler "$new_promise" "$on_fulfilled" "$promise/value" >> $promise/on_fulfilled
    [[ -n "$on_rejected" ]] && handler "$new_promise" "$on_rejected" "$promise/reason" >> $promise/on_rejected
  fi

  echo $new_promise
}

promise() {
  local name

  name=$1

  promise::is_promise $name && promise::path $name || promise::new $name
}

resolve() {
  local name

  name=$1
  shift

  promise $name | .resolve $*
}

reject() {
  local name

  name=$1

  promise $name | .reject $*
}

.then() {
  local promise

  read promise

  promise::then $promise $*
}

.catch() {
  .then , $*
}

.always() {
  .then $*, $*
}

.resolve() {
  local promise

  read promise

  promise::resolve $promise $*
}

.reject() {
  local promise

  read promise

  promise::reject $promise $*
}

.state() {
  local promise

  read promise

  promise::state $promise $*
}