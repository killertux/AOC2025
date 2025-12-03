import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import simplifile

pub fn execute() -> Result(Nil, String) {
  io.println("Day 3")
  result.all([
    day_part1("inputs/day3/example1.txt"),
    day_part1("inputs/day3/input1.txt"),
    day_part2("inputs/day3/example1.txt"),
    day_part2("inputs/day3/input1.txt"),
  ])
  |> result.map(fn(_) { Nil })
}

fn day_part1(file_path: String) -> Result(Nil, String) {
  use contents <- result.try(
    simplifile.read(file_path) |> result.replace_error("Error reading file"),
  )
  use batteries <- result.try(parse_batteries(contents))

  batteries
  |> list.map(get_highest_joltage(_, 2))
  |> list.fold(0, fn(acc, joltage) { acc + joltage })
  |> int.to_string
  |> io.println
  Ok(Nil)
}

fn day_part2(file_path: String) -> Result(Nil, String) {
  use contents <- result.try(
    simplifile.read(file_path) |> result.replace_error("Error reading file"),
  )
  use batteries <- result.try(parse_batteries(contents))

  batteries
  |> list.map(get_highest_joltage(_, 12))
  |> list.fold(0, fn(acc, joltage) { acc + { joltage } })
  |> int.to_string
  |> io.println
  Ok(Nil)
}

fn parse_batteries(contents: String) -> Result(List(List(Int)), String) {
  contents
  |> string.split("\n")
  |> list.filter(fn(line) { !string.is_empty(line) })
  |> list.try_map(fn(line) {
    string.to_graphemes(line)
    |> list.try_map(fn(c) {
      int.parse(c) |> result.replace_error("Failed to parse " <> c)
    })
  })
}

fn get_highest_joltage(list: List(Int), n_batteries: Int) -> Int {
  let result =
    list.range(1, n_batteries)
    |> list.fold(#(-1, 0), fn(acc, battery) {
      let list = list.drop(list, acc.0 + 1)
      let list = list.take(list, list.length(list) - { n_batteries - battery })
      let #(number, pos) = get_highest_number(list)
      #(pos + acc.0 + 1, acc.1 * 10 + number)
    })
  result.1
}

fn get_highest_number(list: List(Int)) -> #(Int, Int) {
  list.fold(list, #(#(0, 0), 0), fn(acc, number) {
    let current_max_number = acc.0.0
    case current_max_number < number {
      True -> #(#(number, acc.1), acc.1 + 1)
      False -> #(acc.0, acc.1 + 1)
    }
  }).0
}
