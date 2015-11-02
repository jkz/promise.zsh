# ZSH Promises

Promises as specified for [javascript](https://promisesaplus.com/)

## Usage

```
$ promise my_resolving_promise | .then echo On resolved:, echo On rejected:
$ resolve my_resolving_promise the value
On resolved: value

$ promise my_rejecting_promise | .then echo On resolved:, echo On rejected: |
.then echo Chained:
$ resolve my_rejecting_promise the reason
On rejected: reason
Chained: On rejected: reason
```

