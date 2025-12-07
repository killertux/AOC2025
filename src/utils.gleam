import gleam/string

pub fn dbg(data: a) -> a {
  echo data
  data
}

pub fn not_empty(line: String) -> Bool {
  !string.is_empty(line)
}
