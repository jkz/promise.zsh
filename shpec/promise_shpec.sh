#!/bin/zsh

mkdir -p ~/.promise/shpec

# TODO properly import
. ../promise.sh

export PROMISE_ROOT=~/.promise/shpec

describe "the truth"
  describe "promise_new"
    it "returns a promise"
      promise=$(_promise_new)
      assert match "$promise" "$PROMISE_ROOT"*
    end

    it "creates a promise"
      promise=$(_promise_new)
      assert file_present "$promise"
    end
  end

  describe "promise_resolve"
    it "resolves a value"
      promise=$(_promise_new)
      _promise_resolve $promise expected >/dev/null
      value=$(cat $promise/value)
      assert equal "$value" "expected"

      it "doesn't reject after"
        _promise_reject $promise expected >/dev/null
        assert file_absent "$promise/reason"
      end
    end
  end

  describe "promise_reject"
    it "rejects a value"
      promise=$(_promise_new)

      _promise_reject $promise expected >/dev/null
      reason=$(cat $promise/reason)
      assert equal "$reason" "expected"

      it "doesn't resolve after"
        _promise_resolve $promise unexpected >/dev/null
        assert file_absent "$promise/value"
      end
    end
  end

  describe "promise_handler"
    it "returns a handler string"
      handler=$( _promise_handler PROMISE HANDLER VALUE )
      assert equal "$handler" " \
value=\$(HANDLER \$(cat VALUE)) \
if [[ \$? -eq 0 ]] \
then \
  echo _promise_resolve \"PROMISE\" \$value \
  _promise_resolve \"PROMISE\" \$value \
else \
  echo REJECT PROMISE \
  _promise_reject PROMISE \$? \
fi \
"
    end
  end
end