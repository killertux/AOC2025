import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import simplifile

pub fn day1() -> Result(Nil, String) {
  io.println("Day 1")
  result.all([
    day_part1("inputs/day1/example1.txt"),
    day_part1("inputs/day1/input1.txt"),
    day_part2("inputs/day1/example1.txt"),
    day_part2("inputs/day1/input1.txt"),
  ])
  |> result.map(fn(_) { Nil })
}

fn day_part1(file_path: String) -> Result(Nil, String) {
  use contents <- result.try(
    simplifile.read(file_path) |> result.replace_error("Error reading file"),
  )
  use instructions <- result.try(parse_instructions(contents))
  let applied_instructions =
    instructions
    |> list.map_fold(50, apply_instruction)
  applied_instructions.1
  |> list.filter(fn(positions) { positions == 0 })
  |> list.length
  |> int.to_string
  |> io.println
  Ok(Nil)
}

fn day_part2(file_path: String) -> Result(Nil, String) {
  use contents <- result.try(
    simplifile.read(file_path) |> result.replace_error("Error reading file"),
  )
  use instructions <- result.try(parse_instructions(contents))

  let applied_instructions =
    instructions
    |> list.fold(#(50, 0), apply_instruction_and_count_zeroes)
  applied_instructions.1 |> int.to_string |> io.println

  Ok(Nil)
}

fn parse_instructions(contents: String) -> Result(List(Instruction), String) {
  contents
  |> string.split("\n")
  |> list.filter(fn(line) { !string.is_empty(line) })
  |> list.try_map(parse_instruction)
}

fn parse_instruction(line: String) -> Result(Instruction, String) {
  case line {
    "R" <> distance ->
      int.parse(distance)
      |> result.map(fn(distance) { Instruction(Right, distance:) })
      |> result.replace_error("Failed to parse distance")
    "L" <> distance ->
      int.parse(distance)
      |> result.map(fn(distance) { Instruction(Left, distance:) })
      |> result.replace_error("Failed to parse distance")
    _ -> Error("Invalid direction")
  }
}

fn apply_instruction(position: Int, instruction: Instruction) -> #(Int, Int) {
  case instruction.direction {
    Left -> {
      let position = correct_position(position - instruction.distance)
      #(position, position)
    }
    Right -> {
      let position = correct_position(position + instruction.distance)
      #(position, position)
    }
  }
}

fn apply_instruction_and_count_zeroes(
  value: #(Int, Int),
  instruction: Instruction,
) -> #(Int, Int) {
  case instruction.direction {
    Left -> {
      let new_position = value.0 - instruction.distance
      let position = correct_position(new_position)
      let zeroes = case new_position == 0 {
        True -> 1
        False -> 0
      }
      let zeroes = case new_position < 0 && value.0 == 0 {
        True -> zeroes - 1
        False -> zeroes
      }
      let zeroes = case new_position < 0 {
        True -> zeroes + 1
        False -> zeroes
      }
      let zeroes = zeroes + int.absolute_value(new_position) / 100
      #(position, value.1 + zeroes)
    }
    Right -> {
      let new_position = value.0 + instruction.distance
      let position = correct_position(new_position)
      #(position, value.1 + new_position / 100)
    }
  }
}

fn correct_position(position: Int) -> Int {
  case position < 0 {
    True -> correct_position(100 + position)
    False ->
      case position > 99 {
        True -> correct_position(position - 100)
        False -> position
      }
  }
}

type Instruction {
  Instruction(direction: Direction, distance: Int)
}

type Direction {
  Left
  Right
}
