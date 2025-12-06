import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import simplifile

pub fn execute() -> Result(Nil, String) {
  io.println("Day 6")
  result.all([
    day_part1("inputs/day6/example1.txt"),
    day_part1("inputs/day6/input1.txt"),
    day_part2("inputs/day6/example1.txt"),
    day_part2("inputs/day6/input1.txt"),
  ])
  |> result.map(fn(_) { Nil })
}

fn day_part1(file_path: String) -> Result(Nil, String) {
  resolve(file_path, parse_numbers)
}

fn day_part2(file_path: String) -> Result(Nil, String) {
  resolve(file_path, parse_cephalopod_number)
}

fn resolve(
  file_path: String,
  number_parser: fn(List(String)) -> Result(List(List(Int)), String),
) -> Result(Nil, String) {
  use contents <- result.try(
    simplifile.read(file_path) |> result.replace_error("Error reading file"),
  )
  use math_problems <- result.try(parse_math_problems(contents, number_parser))
  math_problems
  |> list.try_map(fn(problem) {
    list.reduce(problem.numbers, fn(acc, numb) {
      apply_operation(problem.operation, acc, numb)
    })
    |> result.replace_error("No numbers")
  })
  |> result.map(fn(numbers) {
    numbers
    |> list.fold(0, fn(acc, num) { acc + num })
    |> int.to_string
    |> io.println
  })
}

fn apply_operation(operation: Operation, num_a: Int, num_b: Int) -> Int {
  case operation {
    Add -> num_a + num_b
    Multiply -> num_a * num_b
  }
}

fn parse_math_problems(
  contents: String,
  number_parser: fn(List(String)) -> Result(List(List(Int)), String),
) -> Result(List(Problem), String) {
  let assert [operations, ..numbers] =
    contents
    |> string.split("\n")
    |> list.filter(not_empty)
    |> list.reverse

  use operations <- result.try(parse_operations(operations))
  use numbers <- result.try(number_parser(numbers |> list.reverse))

  Ok(
    list.zip(operations, numbers)
    |> list.map(fn(data) { Problem(operation: data.0, numbers: data.1) }),
  )
}

fn parse_cephalopod_number(
  lines: List(String),
) -> Result(List(List(Int)), String) {
  lines
  |> list.map(fn(line) { string.to_graphemes(line) })
  |> list.transpose
  |> list.map(fn(chars) {
    int.parse(
      list.fold(chars, "", fn(acc, char) {
        case char {
          " " -> acc
          other -> acc <> other
        }
      }),
    )
  })
  |> list.fold([], fn(acc, number_or_error) {
    case number_or_error {
      Ok(number) ->
        case acc {
          [] -> [[number]]
          [current, ..rest] -> [[number, ..current], ..rest]
        }
      Error(_) -> [[], ..acc]
    }
  })
  |> list.reverse
  |> Ok
}

fn parse_operations(operations: String) -> Result(List(Operation), String) {
  string.split(operations, " ")
  |> list.filter(not_empty)
  |> list.try_map(fn(op) {
    case op {
      "+" -> Ok(Add)
      "*" -> Ok(Multiply)
      other -> Error("Invalid operation " <> other)
    }
  })
}

fn parse_numbers(numbers: List(String)) -> Result(List(List(Int)), String) {
  list.try_map(numbers, fn(line) {
    string.split(line, " ")
    |> list.filter(not_empty)
    |> list.try_map(fn(number) {
      int.parse(number)
      |> result.replace_error("Failed to parse number " <> number)
    })
  })
  |> result.map(fn(numbers) { list.transpose(numbers) })
}

type Problem {
  Problem(numbers: List(Int), operation: Operation)
}

type Operation {
  Add
  Multiply
}

fn not_empty(line: String) -> Bool {
  !string.is_empty(line)
}
