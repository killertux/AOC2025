import gleam/dict
import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import simplifile
import utils

pub fn execute() -> Result(Nil, String) {
  io.println("Day 12")
  result.all([
    day_part1("inputs/day12/input1.txt"),
    day_part1("inputs/day12/example1.txt"),
  ])
  |> result.map(fn(_) { Nil })
}

fn day_part1(file_path: String) -> Result(Nil, String) {
  use contents <- result.try(
    simplifile.read(file_path) |> result.replace_error("Error reading file"),
  )
  use problems <- result.try(parse_problems(contents))
  problems
  |> list.filter(fn(problem) { is_solvable(problem) })
  |> list.length
  |> int.to_string
  |> io.println
  Ok(Nil)
}

fn is_solvable(problem: Problem) -> Bool {
  let blocks =
    problem.blocks
    |> list.map(fn(block) { #(block.id, block) })
    |> dict.from_list
  let blocks_to_add =
    problem.blocks_to_add
    |> list.flat_map(fn(block_to_add) {
      case block_to_add.1 == 0 {
        True -> []
        False -> {
          list.range(1, block_to_add.1)
          |> list.map(fn(_) {
            dict.get(blocks, block_to_add.0)
            |> result.lazy_unwrap(fn() { panic as "Block not found" })
          })
        }
      }
    })

  loop_is_solvable(
    blocks_to_add,
    problem.grid,
    list.range(0, problem.grid.x - 3)
      |> list.flat_map(fn(x) {
        list.range(0, problem.grid.y - 3)
        |> list.flat_map(fn(y) {
          list.range(1, 4)
          |> list.map(fn(rot) { #(x, y, rot) })
        })
      }),
  )
}

fn loop_is_solvable(
  blocks: List(Block),
  grid: Grid,
  possible_positions_and_rotations: List(#(Int, Int, Int)),
) -> Bool {
  let remaining_block_sizes =
    list.map(blocks, fn(block) { block.size })
    |> list.fold(0, fn(acc, n) { acc + n })
  case grid.empty_grid_size >= remaining_block_sizes {
    True ->
      case blocks {
        [block, ..rest] -> {
          solve_block(
            block,
            rest,
            grid,
            possible_positions_and_rotations,
            possible_positions_and_rotations,
          )
        }
        [] -> True
      }
    False -> False
  }
}

fn solve_block(
  block: Block,
  rest: List(Block),
  grid: Grid,
  pos_and_rot: List(#(Int, Int, Int)),
  possible_positions_and_rotations: List(#(Int, Int, Int)),
) -> Bool {
  case pos_and_rot {
    [position_with_rot, ..others] -> {
      case
        try_add_block(
          BlockToPosition(
            Point(position_with_rot.0, position_with_rot.1),
            apply_rot(position_with_rot.2, block),
          ),
          grid,
        )
      {
        Ok(new_grid) ->
          case
            loop_is_solvable(rest, new_grid, possible_positions_and_rotations)
          {
            True -> True
            False ->
              solve_block(
                block,
                rest,
                grid,
                others,
                possible_positions_and_rotations,
              )
          }
        Error(Nil) -> {
          solve_block(
            block,
            rest,
            grid,
            others,
            possible_positions_and_rotations,
          )
        }
      }
    }
    [] -> False
  }
}

// fn print_block(
//   block: dict.Dict(Point, Bool),
//   x_range: #(Int, Int),
//   y_range: #(Int, Int),
// ) {
//   list.range(y_range.0, y_range.1)
//   |> list.map(fn(y) {
//     list.range(x_range.0, x_range.1)
//     |> list.map(fn(x) {
//       case dict.get(block, Point(x, y)) {
//         Ok(True) -> io.print("#")
//         _ -> io.print(".")
//       }
//     })
//     io.print("\n")
//   })
//   io.print("\n")
// }

fn apply_rot(rot: Int, block: Block) -> dict.Dict(Point, Bool) {
  case rot {
    1 -> {
      block.parts
    }
    2 -> {
      list.map_fold(list.range(0, 2), dict.new(), fn(tiles, x) {
        list.map_fold(list.range(0, 2), tiles, fn(tiles, y) {
          case dict.get(block.parts, Point(x, y)) {
            Ok(True) -> #(dict.insert(tiles, Point(2 - y, x), True), y)
            _ -> #(tiles, y)
          }
        })
      }).0
    }
    3 -> {
      list.map_fold(list.range(0, 2), dict.new(), fn(tiles, x) {
        list.map_fold(list.range(0, 2), tiles, fn(tiles, y) {
          case dict.get(block.parts, Point(x, y)) {
            Ok(True) -> #(dict.insert(tiles, Point(2 - x, 2 - y), True), y)
            _ -> #(tiles, y)
          }
        })
      }).0
    }
    4 -> {
      list.map_fold(list.range(0, 2), dict.new(), fn(tiles, x) {
        list.map_fold(list.range(0, 2), tiles, fn(tiles, y) {
          case dict.get(block.parts, Point(x, y)) {
            Ok(True) -> #(dict.insert(tiles, Point(2 - y, 2 - x), True), y)
            _ -> #(tiles, y)
          }
        })
      }).0
    }
    _ -> panic as "Invalid rotation"
  }
}

fn try_add_block(
  block_with_pos: BlockToPosition,
  grid: Grid,
) -> Result(Grid, Nil) {
  block_with_pos.tiles
  |> dict.keys()
  |> list.fold(Ok(grid), fn(grid, point) {
    let point =
      Point(point.x + block_with_pos.pos.x, point.y + block_with_pos.pos.y)
    case grid {
      Ok(grid) -> {
        case dict.get(grid.tiles, point) {
          Ok(True) -> {
            // print_block(grid.tiles, #(0, grid.x - 1), #(0, grid.y - 1))
            Error(Nil)
          }
          Ok(False) -> {
            let grid =
              Grid(
                grid.x,
                grid.y,
                dict.insert(grid.tiles, point, True),
                grid.empty_grid_size - 1,
              )
            // print_block(grid.tiles, #(0, grid.x - 1), #(0, grid.y - 1))
            Ok(grid)
          }
          Error(Nil) ->
            panic as { "Point should be in grid " <> point_to_string(point) }
        }
      }
      Error(Nil) -> Error(Nil)
    }
  })
  |> result.map(fn(grid) {
    // print_block(grid.tiles, #(0, grid.x - 1), #(0, grid.y - 1))
    grid
  })
}

fn point_to_string(point: Point) -> String {
  "(" <> int.to_string(point.x) <> "," <> int.to_string(point.y) <> ")"
}

fn parse_problems(contents: String) -> Result(List(Problem), String) {
  case string.split(contents, "\n\n") |> list.reverse {
    [grids, ..rest] -> {
      use grids_with_blocks_to_add <- result.try(parse_grids(grids))
      use blocks <- result.try(parse_blocks(rest))
      Ok(
        grids_with_blocks_to_add
        |> list.map(fn(grid_with_blocks_to_add) {
          let #(grid, blocks_to_add) = grid_with_blocks_to_add
          Problem(grid, blocks_to_add, blocks)
        }),
      )
    }
    _ -> Error("Invalid input")
  }
}

fn parse_blocks(blocks_part: List(String)) -> Result(List(Block), String) {
  blocks_part |> list.try_map(parse_block)
}

fn parse_block(block_part: String) -> Result(Block, String) {
  use #(id, rest) <- result.try(
    string.split_once(block_part, ":\n")
    |> result.replace_error("Invalid block"),
  )
  int.parse(id)
  |> result.map(fn(id) {
    let tiles =
      utils.enumerate(string.split(rest, "\n"))
      |> list.flat_map(fn(line) {
        utils.enumerate(string.to_graphemes(line.1))
        |> list.filter_map(fn(c) {
          case c.1 {
            "#" -> Ok(#(Point(c.0, line.0), True))
            _ -> Error(Nil)
          }
        })
      })
      |> dict.from_list
    Block(id, tiles, dict.keys(tiles) |> list.length)
  })
  |> result.replace_error("Invalid block")
}

fn parse_grids(
  grids: String,
) -> Result(List(#(Grid, List(#(Int, Int)))), String) {
  string.split(grids, "\n")
  |> list.filter(utils.not_empty)
  |> list.try_map(parse_grid_line)
}

fn parse_grid_line(line: String) -> Result(#(Grid, List(#(Int, Int))), String) {
  use #(dimension_part, numbers_part) <- result.try(
    string.split_once(line, ": ")
    |> result.replace_error("Invalid grid line"),
  )
  use #(x, y) <- result.try(
    string.split_once(dimension_part, "x")
    |> result.replace_error("Invalid dimensions"),
  )
  use x <- result.try(
    int.parse(x) |> result.replace_error("Invalid X dimension"),
  )
  use y <- result.try(
    int.parse(y) |> result.replace_error("Invalid Y dimension"),
  )
  use blocks_to_add <- result.try(
    utils.enumerate(string.split(numbers_part, " "))
    |> list.try_map(fn(n) {
      int.parse(n.1)
      |> result.replace_error("Invalid number " <> n.1)
      |> result.map(fn(v) { #(n.0, v) })
    }),
  )
  Ok(#(
    Grid(
      x,
      y,
      list.range(0, y - 1)
        |> list.flat_map(fn(y) {
          list.range(0, x - 1) |> list.map(fn(x) { #(Point(x, y), False) })
        })
        |> dict.from_list,
      x * y,
    ),
    blocks_to_add,
  ))
}

type Problem {
  Problem(grid: Grid, blocks_to_add: List(#(Int, Int)), blocks: List(Block))
}

type Grid {
  Grid(x: Int, y: Int, tiles: dict.Dict(Point, Bool), empty_grid_size: Int)
}

type Block {
  Block(id: Int, parts: dict.Dict(Point, Bool), size: Int)
}

type Point {
  Point(x: Int, y: Int)
}

type BlockToPosition {
  BlockToPosition(pos: Point, tiles: dict.Dict(Point, Bool))
}
