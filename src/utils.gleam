import gleam/list
import gleam/string

pub fn dbg(data: a) -> a {
  echo data
  data
}

pub fn not_empty(line: String) -> Bool {
  !string.is_empty(line)
}

pub fn enumerate(list: List(a)) -> List(#(Int, a)) {
  list.map_fold(list, 0, fn(index, value) { #(index + 1, #(index, value)) }).1
}
