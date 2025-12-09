import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import simplifile
import utils

pub fn execute() -> Result(Nil, String) {
  io.println("Day 9")
  result.all([
    day_part1("inputs/day9/example1.txt"),
    day_part1("inputs/day9/input1.txt"),
    day_part2("inputs/day9/example1.txt"),
    day_part2("inputs/day9/input1.txt"),
  ])
  |> result.map(fn(_) { Nil })
}

fn day_part1(file_path: String) -> Result(Nil, String) {
  use contents <- result.try(
    simplifile.read(file_path) |> result.replace_error("Error reading file"),
  )
  use red_corners <- result.try(parse_red_corners(contents))
  list.combination_pairs(red_corners)
  |> list.map(fn(pairs) {
    { int.absolute_value({ pairs.0 }.x - { pairs.1 }.x) + 1 }
    * { int.absolute_value({ pairs.0 }.y - { pairs.1 }.y) + 1 }
  })
  |> list.max(int.compare)
  |> result.unwrap(0)
  |> int.to_string
  |> io.println
  Ok(Nil)
}

fn day_part2(file_path: String) -> Result(Nil, String) {
  use contents <- result.try(
    simplifile.read(file_path) |> result.replace_error("Error reading file"),
  )
  use red_corners <- result.try(parse_red_corners(contents))
  let vertical_lines =
    list.window_by_2([
      list.last(red_corners)
        |> result.lazy_unwrap(fn() { panic as "No corners" }),
      ..red_corners
    ])
    |> list.filter(fn(segment) { { segment.0 }.x == { segment.1 }.x })

  list.combination_pairs(red_corners)
  |> list.filter(fn(pairs) {
    let min_x = int.min({ pairs.0 }.x, { pairs.1 }.x)
    let max_x = int.max({ pairs.0 }.x, { pairs.1 }.x)
    let min_y = int.min({ pairs.0 }.y, { pairs.1 }.y)
    let max_y = int.max({ pairs.0 }.y, { pairs.1 }.y)
    !list.any(red_corners, fn(pos) {
      pos.x > min_x && pos.x < max_x && pos.y > min_y && pos.y < max_y
    })
    && check_line_is_in_polygon(pairs, vertical_lines)
  })
  |> list.map(fn(pairs) {
    { int.absolute_value({ pairs.0 }.x - { pairs.1 }.x) + 1 }
    * { int.absolute_value({ pairs.0 }.y - { pairs.1 }.y) + 1 }
  })
  |> list.max(int.compare)
  |> result.unwrap(0)
  |> int.to_string
  |> io.println
  Ok(Nil)
}

fn check_line_is_in_polygon(
  pairs: #(Pos, Pos),
  vertical_lines: List(#(Pos, Pos)),
) -> Bool {
  let line = calculate_line(pairs)
  let diff = case { pairs.0 }.x > { pairs.1 }.x {
    True -> 1
    False -> -1
  }

  list.range({ pairs.0 }.x - diff, { pairs.1 }.x + diff)
  |> list.map(fn(x) { #(x, int.to_float(x) *. line.0 +. line.1) })
  |> list.all(fn(point) {
    let result =
      vertical_lines
      |> list.filter(fn(segment) { { segment.0 }.x > point.0 })
      |> list.filter(fn(segment) {
        let y1 = int.to_float({ segment.0 }.y)
        let y2 = int.to_float({ segment.1 }.y)

        case y1 <. y2 {
          True -> {
            point.1 <=. y2 && point.1 >=. y1
          }
          False -> {
            point.1 <=. y1 && point.1 >=. y2
          }
        }
      })
      |> list.length()
      |> int.modulo(2)
      |> result.unwrap(0)

    result == 1
  })
}

fn calculate_line(pairs: #(Pos, Pos)) -> #(Float, Float) {
  let m =
    int.to_float({ { pairs.1 }.y - { pairs.0 }.y })
    /. int.to_float({ { pairs.1 }.x - { pairs.0 }.x })
  let n = int.to_float({ pairs.0 }.y) -. m *. int.to_float({ pairs.0 }.x)
  #(m, n)
}

fn parse_red_corners(contents: String) -> Result(List(Pos), String) {
  string.split(contents, "\n")
  |> list.filter(utils.not_empty)
  |> list.try_map(fn(line) {
    case string.split_once(line, ",") {
      Ok(#(x, y)) -> {
        use x <- result.try(
          int.parse(x) |> result.replace_error("Failed to parse X"),
        )
        use y <- result.try(
          int.parse(y) |> result.replace_error("Failed to parse X"),
        )
        Ok(Pos(x, y))
      }
      Error(_) -> Error("Failed to parse line")
    }
  })
}

type Pos {
  Pos(x: Int, y: Int)
}
