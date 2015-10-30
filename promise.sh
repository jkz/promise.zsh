# A promise is a file
# The promise state is the first line
# All handlers are appended to the file
# Resolving the file runs the file with a state variable

# A promise is a file with a .promise extension

# promise commmand arg1 arg2 | then arg3 | catch arg4

# FOO = promise
SCRIPT=`basename "$0"`
PROMISE_HOME=~/.promise

function new_descriptor() {
}

function promise(callback) {
    # An array of handlers
    queue=()
    return pid
}

function handle(promise, func, value) {
    # TODO get the reason from a failed func eval
    eval $func $value && resolve $promise $value || reject $promise, $reason
}

function _resolve(promise, func, value) {
    [[ -z $func ]] && handle $promise $func $value || _resolve $value
}

function _reject(promise, func, reason) {
    [[ -z $func ]] && handle $promise $func $reason || _reject $reason
}

function promise_state(promise) {
    $(head -n 1 $promise)
}

function is_promise(promise) {
    [[ $promise=$PROMISE_HOME/* ]]
}

# This appends lines to the promise script which will execute when the promise
# is resolved
function then(promise, on_fulfilled, on_rejected) {
    _promise=promise "$on_fulfilled" "$on_rejected"

    case promise_state $promise in
        PENDING)
            "
            if [[ $STATE = "RESOLVED" ]]
            then
                if [[ ! -z on_fulfilled ]]
                    VALUE = eval "$on_fulfilled $VALUE"
                fi
            elif [[ $STATE = "REJECTED" ]]
                eval "$on_rejected $REASON" || STATE=REJECTED
            then
            fi
            " >> promise
        ;;
        RESOLVED) eval "$on_fulfilled $VALUE" ;;
        REJECTED) eval "$on_rejected $REASON" ;;
    esac
}

function resolve(promise, value) {
    [[ $promise=$value ]] && exit $(reject "Can't resolve self")
    [[ ! $state="PENDING" ]] && echo $promise && exit
    is_promise && then $promise "resolve $promise" "reject $promise"

    # Change the state and value of this file
    . promise
}

function reject(promise_pid, reason) {
    return
}

