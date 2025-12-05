import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import simplifile

pub fn execute() -> Result(Nil, String) {
  io.println("Day 5")
  result.all([
    day_part1("inputs/day5/example1.txt"),
    day_part1("inputs/day5/input1.txt"),
    day_part2("inputs/day5/example1.txt"),
    day_part2("inputs/day5/input1.txt"),
  ])
  |> result.map(fn(_) { Nil })
}

fn day_part1(file_path: String) -> Result(Nil, String) {
  use contents <- result.try(
    simplifile.read(file_path) |> result.replace_error("Error reading file"),
  )
  use database <- result.try(parse_database(contents))
  database.ingredients
  |> list.filter(fn(ingredient) {
    database.ranges
    |> list.any(fn(range) {
      range.start <= ingredient && range.end >= ingredient
    })
  })
  |> list.length
  |> int.to_string
  |> io.println()
  Ok(Nil)
}

fn day_part2(file_path: String) -> Result(Nil, String) {
  use contents <- result.try(
    simplifile.read(file_path) |> result.replace_error("Error reading file"),
  )
  use database <- result.try(parse_database(contents))
  database.ranges
  |> list.fold([], fn(acc, range) { add_or_merge(acc, range) })
  |> list.map(fn(range) { range.end - range.start + 1 })
  |> list.fold(0, fn(acc, n) { acc + n })
  |> int.to_string
  |> io.println

  Ok(Nil)
}

fn add_or_merge(list: List(Range), range: Range) -> List(Range) {
  case list {
    [] -> [range]
    [start, ..rest] ->
      case try_merge(range, start) {
        Ok(range) -> add_or_merge(rest, range)
        Error(Nil) -> [start, ..add_or_merge(rest, range)]
      }
  }
}

fn try_merge(range_a: Range, range_b: Range) -> Result(Range, Nil) {
  case range_a.start <= range_b.start && range_a.end >= range_b.end {
    True -> Ok(range_a)
    False ->
      case range_a.start >= range_b.start && range_a.end <= range_b.end {
        True -> Ok(range_b)
        False ->
          case range_a.start <= range_b.start && range_a.end >= range_b.start {
            True -> Ok(Range(range_a.start, range_b.end))
            False ->
              case range_a.start <= range_b.end && range_a.end >= range_b.end {
                True -> Ok(Range(range_b.start, range_a.end))
                False -> Error(Nil)
              }
          }
      }
  }
}

fn parse_database(contents: String) -> Result(Database, String) {
  use #(ranges_part, ids_part) <- result.try(
    string.split_once(contents, "\n\n")
    |> result.replace_error("Failed to parse database"),
  )
  use ranges <- result.try(parse_ranges(ranges_part))
  use ids <- result.try(parse_ids(ids_part))
  Ok(Database(ranges, ids))
}

fn parse_ranges(ranges_part: String) -> Result(List(Range), String) {
  string.split(ranges_part, "\n")
  |> list.try_map(fn(line) { parse_range(line) })
}

fn parse_range(line: String) -> Result(Range, String) {
  use #(start, end) <- result.try(
    string.split_once(line, "-")
    |> result.replace_error("Failed to parse range " <> line),
  )
  use start <- result.try(
    int.parse(start) |> result.replace_error("Failed to parse start " <> start),
  )
  use end <- result.try(
    int.parse(end) |> result.replace_error("Failed to parse end " <> end),
  )
  Ok(Range(start, end))
}

fn parse_ids(ids_part: String) -> Result(List(Int), String) {
  string.split(ids_part, "\n")
  |> list.filter(fn(line) { !string.is_empty(line) })
  |> list.try_map(fn(line) {
    int.parse(line) |> result.replace_error("Failed to parse id " <> line)
  })
}

type Database {
  Database(ranges: List(Range), ingredients: List(Int))
}

type Range {
  Range(start: Int, end: Int)
}
