import gleam/dict
import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import simplifile

pub fn execute() -> Result(Nil, String) {
  io.println("Day 4")
  result.all([
    day_part1("inputs/day4/example1.txt"),
    day_part1("inputs/day4/input1.txt"),
    day_part2("inputs/day4/example1.txt"),
    day_part2("inputs/day4/input1.txt"),
  ])
  |> result.map(fn(_) { Nil })
}

fn day_part1(file_path: String) -> Result(Nil, String) {
  use contents <- result.try(
    simplifile.read(file_path) |> result.replace_error("Error reading file"),
  )
  let paper_map = parse_paper_map(contents)

  dict.keys(paper_map.dict)
  |> list.map(fn(paper_pos) { n_neighbours_papers(paper_pos, paper_map) })
  |> list.filter(fn(n) { n < 4 })
  |> list.length
  |> int.to_string
  |> io.println

  Ok(Nil)
}

fn day_part2(file_path: String) -> Result(Nil, String) {
  use contents <- result.try(
    simplifile.read(file_path) |> result.replace_error("Error reading file"),
  )
  let paper_map = parse_paper_map(contents)
  count_all_possible_to_remove_part_2(paper_map)
  |> int.to_string
  |> io.println

  Ok(Nil)
}

fn count_all_possible_to_remove_part_2(paper_map: PaperMap) -> Int {
  let possible_to_remove =
    dict.keys(paper_map.dict)
    |> list.filter(fn(paper_pos) {
      dict.get(paper_map.dict, paper_pos) |> result.unwrap(False)
    })
    |> list.filter_map(fn(paper_pos) {
      case n_neighbours_papers(paper_pos, paper_map) < 4 {
        True -> Ok(paper_pos)
        False -> Error(Nil)
      }
    })
  let n_possible_to_remove = list.length(possible_to_remove)
  case n_possible_to_remove {
    0 -> 0
    _ -> {
      let removed_map =
        PaperMap(
          possible_to_remove
          |> list.fold(paper_map.dict, fn(map, pos) {
            dict.insert(map, pos, False)
          }),
        )
      n_possible_to_remove + count_all_possible_to_remove_part_2(removed_map)
    }
  }
}

fn n_neighbours_papers(paper_pos: Pos, paper_map: PaperMap) -> Int {
  [
    Pos(paper_pos.x - 1, paper_pos.y - 1),
    Pos(paper_pos.x - 1, paper_pos.y),
    Pos(paper_pos.x - 1, paper_pos.y + 1),
    Pos(paper_pos.x, paper_pos.y - 1),
    Pos(paper_pos.x, paper_pos.y + 1),
    Pos(paper_pos.x + 1, paper_pos.y - 1),
    Pos(paper_pos.x + 1, paper_pos.y),
    Pos(paper_pos.x + 1, paper_pos.y + 1),
  ]
  |> list.filter(fn(pos) {
    dict.get(paper_map.dict, pos) |> result.unwrap(False)
  })
  |> list.length
}

fn parse_paper_map(contents: String) -> PaperMap {
  PaperMap(
    contents
    |> string.split("\n")
    |> list.filter(fn(line) { !string.is_empty(line) })
    |> parse_rows(0)
    |> list.map(fn(pos) { #(pos, True) })
    |> dict.from_list,
  )
}

fn parse_rows(rows: List(String), row: Int) -> List(Pos) {
  case rows {
    [current, ..rest] ->
      parse_column(current, row, 0)
      |> list.append(parse_rows(rest, row + 1))
    [] -> []
  }
}

fn parse_column(current: String, row: Int, column: Int) -> List(Pos) {
  case current {
    "@" <> rest -> [Pos(column, row), ..parse_column(rest, row, column + 1)]
    "." <> rest -> parse_column(rest, row, column + 1)
    "" -> []
    other -> panic as { "Invalid map: " <> other }
  }
}

type PaperMap {
  PaperMap(dict: dict.Dict(Pos, Bool))
}

type Pos {
  Pos(x: Int, y: Int)
}
