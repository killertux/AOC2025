import gleam/dict
import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import simplifile
import utils

pub fn execute() -> Result(Nil, String) {
  io.println("Day 7")
  result.all([
    day_part1("inputs/day7/example1.txt"),
    day_part1("inputs/day7/input1.txt"),
    day_part2("inputs/day7/example1.txt"),
    day_part2("inputs/day7/input1.txt"),
  ])
  |> result.map(fn(_) { Nil })
}

fn day_part1(file_path: String) -> Result(Nil, String) {
  use contents <- result.try(
    simplifile.read(file_path) |> result.replace_error("Error reading file"),
  )
  use map <- result.try(parse_map(contents))
  let start_beam = Pos(map.start.x, map.start.y + 1)
  let result =
    list.range(start_beam.y, map.n_rows - 1)
    |> list.fold(#([start_beam], 0), fn(beams, row) {
      let #(updated_beams, n_splits) =
        simulate_row_and_count_splits(beams.0, map, row)
      #(updated_beams, n_splits + beams.1)
    })

  result.1 |> int.to_string |> io.println

  Ok(Nil)
}

fn day_part2(file_path: String) -> Result(Nil, String) {
  use contents <- result.try(
    simplifile.read(file_path) |> result.replace_error("Error reading file"),
  )
  use map <- result.try(parse_map(contents))
  let start_beam = Pos(map.start.x, map.start.y + 1)
  count_timelines(start_beam, map, dict.new()).0 |> int.to_string |> io.println

  Ok(Nil)
}

fn count_timelines(
  beam: Pos,
  map: Map,
  memoization: dict.Dict(Pos, Int),
) -> #(Int, dict.Dict(Pos, Int)) {
  case dict.get(memoization, beam) {
    Ok(n) -> #(n, memoization)
    Error(_) -> {
      case beam.y == map.n_rows {
        True -> #(1, memoization)
        False -> {
          case dict.get(map.splitters, Pos(beam.x, beam.y + 1)) {
            Ok(_) -> {
              let #(split_1, memoization) =
                count_timelines(Pos(beam.x - 1, beam.y + 1), map, memoization)
              let #(split_2, memoization) =
                count_timelines(Pos(beam.x + 1, beam.y + 1), map, memoization)
              #(
                split_1 + split_2,
                memoization |> dict.insert(beam, split_1 + split_2),
              )
            }
            Error(_) -> {
              let #(n_split, memoization) =
                count_timelines(Pos(beam.x, beam.y + 1), map, memoization)
              #(n_split, memoization |> dict.insert(beam, n_split))
            }
          }
        }
      }
    }
  }
}

fn simulate_row_and_count_splits(
  beams: List(Pos),
  map: Map,
  row: Int,
) -> #(List(Pos), Int) {
  let beams_in_row =
    beams
    |> list.filter(fn(beam) { beam.y == row })
  let #(new_beams, n_splitters) =
    beams_in_row
    |> list.fold(#([], 0), fn(state, beam) {
      case dict.get(map.splitters, Pos(beam.x, beam.y + 1)) {
        Ok(_splitter) -> {
          #(
            [
              Pos(beam.x - 1, beam.y + 1),
              Pos(beam.x + 1, beam.y + 1),
              ..state.0
            ],
            state.1 + 1,
          )
        }
        Error(_) -> {
          #([Pos(beam.x, beam.y + 1), ..state.0], state.1)
        }
      }
    })

  #(list.unique(new_beams), n_splitters)
}

fn parse_map(contents: String) -> Result(Map, String) {
  let rows = string.split(contents, "\n") |> list.filter(utils.not_empty)
  case rows {
    [first, ..rest] -> {
      use start <- result.try(find_start(first, 0))
      use splitters <- result.try(parse_splitters(rest, dict.new(), 1))
      Ok(Map(start, splitters, rows |> list.length))
    }
    [] -> Error("Invalid map")
  }
}

fn find_start(first: String, x: Int) -> Result(Pos, String) {
  case first {
    "S" <> _ -> Ok(Pos(x, 0))
    "." <> rest -> find_start(rest, x + 1)
    "" -> Error("Line with no start")
    _ -> Error("Invalid line " <> first)
  }
}

fn parse_splitters(
  lines: List(String),
  dict: dict.Dict(Pos, Bool),
  y: Int,
) -> Result(dict.Dict(Pos, Bool), String) {
  case lines {
    [head, ..rest] -> {
      use line_dict <- result.try(parse_line(head, dict, y, 0))
      parse_splitters(rest, line_dict, y + 1)
    }
    [] -> Ok(dict)
  }
}

fn parse_line(
  line: String,
  dict: dict.Dict(Pos, Bool),
  y: Int,
  x: Int,
) -> Result(dict.Dict(Pos, Bool), String) {
  case line {
    "^" <> rest -> {
      let dict = dict |> dict.insert(Pos(x, y), True)
      parse_line(rest, dict, y, x + 1)
    }
    "." <> rest -> parse_line(rest, dict, y, x + 1)
    "" -> Ok(dict)
    _ -> Error("Invalid line " <> line)
  }
}

type Map {
  Map(start: Pos, splitters: dict.Dict(Pos, Bool), n_rows: Int)
}

type Pos {
  Pos(x: Int, y: Int)
}
