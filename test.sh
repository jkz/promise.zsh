.test() {
  let first=shift
  rest="$*"

  echo "first $first"
  echo "rest $rest"
}

.test one two three