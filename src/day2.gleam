import gleam/float
import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import gleam_community/maths
import simplifile

pub fn execute() -> Result(Nil, String) {
  io.println("Day 2")
  result.all([
    day_part1("inputs/day2/example1.txt"),
    day_part1("inputs/day2/input1.txt"),
    day_part2("inputs/day2/example1.txt"),
    day_part2("inputs/day2/input1.txt"),
  ])
  |> result.map(fn(_) { Nil })
}

fn day_part1(file_path: String) -> Result(Nil, String) {
  use contents <- result.try(
    simplifile.read(file_path) |> result.replace_error("Error reading file"),
  )
  use ranges <- result.try(parse_ranges(contents))
  ranges
  |> list.flat_map(fn(range) { list.range(range.start, range.end) })
  |> list.filter(fn(id) { is_invalid_part_1(id) })
  |> list.fold(0, fn(acc, id) { acc + id })
  |> int.to_string
  |> io.println

  Ok(Nil)
}

fn day_part2(file_path: String) -> Result(Nil, String) {
  use contents <- result.try(
    simplifile.read(file_path) |> result.replace_error("Error reading file"),
  )
  use ranges <- result.try(parse_ranges(contents))
  ranges
  |> list.flat_map(fn(range) { list.range(range.start, range.end) })
  |> list.filter(fn(id) { is_invalid_part_2(id) })
  |> list.fold(0, fn(acc, id) { acc + { id } })
  |> int.to_string
  |> io.println

  Ok(Nil)
}

fn parse_ranges(contents: String) -> Result(List(Range), String) {
  contents
  |> string.split(",")
  |> list.try_map(fn(part) {
    case part |> string.split("-") {
      [start, end] -> {
        use start <- result.try(
          int.parse(start |> string.trim)
          |> result.replace_error("Invalid start"),
        )
        use end <- result.try(
          int.parse(end |> string.trim)
          |> result.replace_error("Invalid end"),
        )
        Ok(Range(start, end))
      }
      _ -> Error("Error parsing range")
    }
  })
}

fn is_invalid_part_1(id: Int) -> Bool {
  let n_digits =
    id
    |> int.to_float
    |> maths.logarithm_10()
    |> result.unwrap(0.0)
    |> float.floor()
    |> float.truncate()
    |> int.add(1)
  case n_digits % 2 != 0 {
    True -> False
    False -> {
      let mid = n_digits / 2
      let base =
        int.power(10, mid |> int.to_float)
        |> result.unwrap(0.0)
        |> float.truncate
      let first_part = id / base
      let second_part = id % base
      first_part == second_part
    }
  }
}

fn is_invalid_part_2(id: Int) -> Bool {
  let id_as_graphemes = id |> int.to_string |> string.to_graphemes
  let mid = id_as_graphemes |> list.length |> int.divide(2) |> result.unwrap(0)

  list.range(1, mid)
  |> list.map(fn(n) { list.sized_chunk(id_as_graphemes, n) })
  |> list.any(fn(chunks) {
    let assert [first, ..rest] = chunks
    case rest |> list.is_empty {
      True -> False
      False -> list.all(rest, fn(chunk) { chunk == first })
    }
  })
}

type Range {
  Range(start: Int, end: Int)
}
