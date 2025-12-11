import gleam/dict
import gleam/float
import gleam/int
import gleam/io
import gleam/list
import gleam/option
import gleam/result
import gleam/string
import simplifile
import utils

pub fn execute() -> Result(Nil, String) {
  io.println("Day 10")
  result.all([
    // day_part1("inputs/day10/example1.txt"),
    // day_part1("inputs/day10/input1.txt"),
    // day_part2("inputs/day10/example1.txt"),
    // day_part2("inputs/day10/input1.txt"),
    day_part2("inputs/day10/test.txt"),
  ])
  |> result.map(fn(_) { Nil })
}

fn day_part1(file_path: String) -> Result(Nil, String) {
  use contents <- result.try(
    simplifile.read(file_path) |> result.replace_error("Error reading file"),
  )
  use machine <- result.try(parse_machines(contents))
  machine
  |> list.map(discover_least_steps_to_match_lights)
  |> list.fold(0, fn(acc, n) { acc + n })
  |> int.to_string
  |> io.println
  Ok(Nil)
}

fn day_part2(file_path: String) -> Result(Nil, String) {
  use contents <- result.try(
    simplifile.read(file_path) |> result.replace_error("Error reading file"),
  )
  use machine <- result.try(parse_machines(contents))
  machine
  |> list.map(solve_machine)
  |> list.fold(0, fn(acc, n) { acc + n })
  |> int.to_string
  |> io.println
  Ok(Nil)
}

fn solve_machine(machine: Machine) -> Int {
  utils.dbg(machine)
  let expressions =
    list.map(utils.enumerate(machine.joltage), fn(joltage) {
      list.append(
        list.map(machine.buttons, fn(button) {
          case list.contains(button.number, joltage.0) {
            True -> 1.0
            False -> 0.0
          }
        }),
        [joltage.1 |> int.to_float],
      )
    })
    |> apply_gauss()
    |> list.filter(fn(row) { row |> list.any(fn(v) { v != 0.0 }) })
    |> replace_vars()

  let result_expression =
    Expr(machine.buttons |> list.map(fn(_) { 1.0 }), 0.0)
    |> do_replacement(expressions)

  let expressions = dict.values(expressions)
  let free_variables_n = list.length(expressions)
  let tableau = [
    list.append(
      result_expression.vars |> list.map(fn(v) { v }),
      list.range(0, free_variables_n - 1) |> list.map(fn(_) { 0.0 }),
    )
      |> list.append([0.0]),
    ..utils.enumerate(
      expressions
      |> list.filter(fn(expr) {
        !{ expr.vars |> list.all(fn(v) { v == 0.0 || v == -0.0 }) }
      }),
    )
    |> list.map(fn(expr) {
      { expr.1 }.vars
      |> list.map(fn(v) { v *. -1.0 })
      |> list.append(
        list.range(0, free_variables_n - 1)
        |> list.map(fn(n) {
          case n == expr.0 {
            True -> 1.0
            False -> 0.0
          }
        }),
      )
      |> list.append([{ expr.1 }.constant])
    })
  ]
  let n = solve_tableau(tableau)
  float.round({ result_expression.constant } -. n)
}

fn solve_tableau(tableau: List(List(Float))) -> Float {
  case loop_solve_tableau(loop_solve_tableau_dual(tableau)) {
    [first, ..] -> {
      list.last(first)
      |> result.lazy_unwrap(fn() { panic as "Invalid tableau" })
    }
    [] -> panic as "Tableau should not be empty"
  }
}

fn loop_solve_tableau_dual(tableau: List(List(Float))) -> List(List(Float)) {
  let tableau =
    list.map(tableau, fn(row) {
      list.map(row, fn(column) { float.to_precision(column, 5) })
    })
  case tableau {
    [first, ..] -> {
      case
        list.all(first |> list.reverse() |> list.drop(1), fn(n) { n >=. 0.0 })
        && list.any(tableau |> list.drop(1), fn(row) {
          { list.last(row) |> result.unwrap(0.0) } <. 0.0
        })
      {
        True -> {
          let #(pivot_row, pivot_column, pivot) = find_dual_pivot(tableau)
          loop_solve_tableau_dual(apply_modifications(
            tableau,
            pivot_row,
            pivot_column,
            pivot,
          ))
        }
        False -> {
          tableau
        }
      }
    }
    [] -> panic as "Tableau should not be empty"
  }
}

fn find_dual_pivot(tableau: List(List(Float))) -> #(Int, Int, Float) {
  {
    utils.enumerate(tableau |> list.drop(1))
    |> list.fold(#(#(0, 0, 0.0), 10_000.0), fn(best, row) {
      let last = list.last(row.1) |> result.unwrap(0.0)
      case last <. best.1, last != 0.0 {
        True, True -> {
          let #(pivot_row, pivot) =
            utils.enumerate(row.1)
            |> list.fold(#(0, 100_000.0), fn(best, col) {
              let n = col.1 /. last
              case n <. best.1, col.1 != 0.0 {
                True, True -> col
                _, _ -> best
              }
            })
          #(#(row.0 + 1, pivot_row, pivot), last)
        }
        _, _ -> best
      }
    })
  }.0
}

fn loop_solve_tableau(tableau: List(List(Float))) -> List(List(Float)) {
  let tableau =
    list.map(tableau, fn(row) {
      list.map(row, fn(column) { float.to_precision(column, 4) })
    })
  utils.dbg(tableau)
  case tableau {
    [first, ..rest] -> {
      let min_from_header =
        utils.enumerate(
          first |> list.reverse() |> list.drop(1) |> list.reverse(),
        )
        |> list.fold(#(10_000, 10_000.0), fn(acc, n) {
          case n.1 <. acc.1 {
            True -> n
            False -> acc
          }
        })
      case min_from_header.1 >=. 0.0 {
        True -> tableau
        False -> {
          let pivot_column = min_from_header.0
          let #(pivot_row, pivot) = find_pivot_row(rest, pivot_column)
          // utils.dbg(pivot_row)
          // utils.dbg(pivot_column)
          // utils.dbg(pivot)

          loop_solve_tableau(apply_modifications(
            tableau,
            pivot_row,
            pivot_column,
            pivot,
          ))
        }
      }
    }
    [] -> panic as "Invalid tableau"
  }
}

fn apply_modifications(
  tableau: List(List(Float)),
  pivot_row: Int,
  pivot_column: Int,
  pivot: Float,
) -> List(List(Float)) {
  let tableau_enumerated = utils.enumerate(tableau)
  let pivot_row_transformed =
    tableau_enumerated
    |> list.find_map(fn(row) {
      case row.0 == pivot_row {
        True -> Ok(row.1)
        False -> Error(Nil)
      }
    })
    |> result.unwrap([])
    |> list.map(fn(n) { n /. pivot })
  utils.dbg(pivot_row_transformed)

  tableau_enumerated
  |> list.map(fn(row) {
    case row.0 == pivot_row {
      True -> pivot_row_transformed
      False -> {
        let scale =
          utils.enumerate(row.1)
          |> list.find_map(fn(col) {
            case col.0 == pivot_column {
              True -> Ok(col.1)
              False -> Error(Nil)
            }
          })
          |> result.unwrap(0.0)
        case scale != 0.0 {
          True -> {
            let scale = scale *. -1.0
            row.1
            |> list.zip(pivot_row_transformed)
            |> list.map(fn(zipped) {
              let #(original, pivot) = zipped
              pivot *. scale +. original
            })
          }
          False -> {
            row.1
          }
        }
      }
    }
  })
}

fn find_pivot_row(rest: List(List(Float)), pivot_column: Int) -> #(Int, Float) {
  let result =
    list.fold(utils.enumerate(rest), #(0, 0.0, 10_000.0), fn(pivot_row, n) {
      let pivot =
        utils.enumerate(n.1)
        |> list.find_map(fn(c) {
          case c.0 == pivot_column {
            True -> Ok(c.1)
            False -> Error(Nil)
          }
        })
        |> result.unwrap(0.0)
      case pivot != 0.0 {
        True -> {
          let val = { list.last(n.1) |> result.unwrap(0.0) } /. pivot
          case val <. pivot_row.2 {
            True -> #(n.0, pivot, val)
            False -> pivot_row
          }
        }
        False -> {
          pivot_row
        }
      }
    })
  #(result.0 + 1, result.1)
}

fn replace_vars(matrix: List(List(Float))) -> dict.Dict(Int, Expr) {
  list.reverse(matrix)
  |> list.fold(dict.new(), fn(vars: dict.Dict(Int, Expr), row) {
    let #(pivot_var, expr) = row_into_expr(row, [])

    let expr = do_replacement(expr, vars)
    case
      list.all(expr.vars, fn(v) {
        case v != 0.0 {
          True -> False
          False -> True
        }
      })
      && expr.constant == 0.0
    {
      True -> vars
      False -> dict.insert(vars, pivot_var, expr)
    }
  })
}

fn do_replacement(expr: Expr, vars: dict.Dict(Int, Expr)) -> Expr {
  list.fold(utils.enumerate(expr.vars), expr, fn(expr, var) {
    case dict.get(vars, var.0) {
      Ok(var_expr) -> {
        let var_scaled = apply_row_scale(var_expr.vars, var.1)
        let const_scaled = var_expr.constant *. var.1
        let var_add =
          add_rows(
            var_scaled,
            expr.vars
              |> utils.enumerate()
              |> list.map(fn(var_with_n) {
                case var_with_n.0 == var.0 {
                  True -> 0.0
                  False -> var_with_n.1
                }
              }),
          )
        let const_add = expr.constant +. const_scaled
        Expr(var_add, const_add)
      }
      Error(_) -> expr
    }
  })
}

fn row_into_expr(row: List(Float), vars: List(Float)) -> #(Int, Expr) {
  case row {
    [0.0, ..rest] -> row_into_expr(rest, [0.0, ..vars])
    [pivot, ..rest] -> {
      let #(nvars, constant) = list.split(rest, list.length(rest) - 1)
      let constant =
        constant
        |> list.first()
        |> result.lazy_unwrap(fn() { panic as "Row without constant" })

      #(
        list.length(vars),
        Expr(
          list.append([0.0, ..vars], nvars)
            |> list.map(fn(var) { var *. -1.0 /. pivot }),
          constant,
        ),
      )
    }
    [] -> panic as "Row without a pivot"
  }
}

fn apply_gauss(matrix: List(List(Float))) -> List(List(Float)) {
  case matrix {
    [first_row, ..rest] -> {
      case first_row {
        [0.0, ..] -> {
          case find_first_row_without_zero_pivot(rest) {
            Ok(row) -> apply_gauss([row, ..swap_row(rest, row, first_row)])
            Error(_) -> [
              first_row,
              ..apply_gauss(rest |> list.map(fn(row) { list.drop(row, 1) }))
              |> list.map(fn(row) { [0.0, ..row] })
            ]
          }
        }
        [pivot, ..] -> {
          let transformed_rows =
            list.map(rest, fn(row) {
              case row {
                [first_element, ..] -> {
                  let scale = first_element /. pivot
                  let scaled_row = apply_row_scale(first_row, scale *. -1.0)
                  add_rows(scaled_row, row)
                  |> list.drop(1)
                }
                [] -> panic as "Invalid row"
              }
            })
          [
            apply_row_scale(first_row, 1.0 /. pivot),
            ..list.map(apply_gauss(transformed_rows), fn(row) { [0.0, ..row] })
          ]
        }
        [] -> []
      }
    }
    _ -> []
  }
}

type Expr {
  Expr(vars: List(Float), constant: Float)
}

fn swap_row(
  matrix: List(List(Float)),
  row_to_be_replaced: List(Float),
  row: List(Float),
) -> List(List(Float)) {
  case matrix {
    [first_row, ..rest] -> {
      case first_row == row_to_be_replaced {
        True -> [row, ..rest]
        False -> [first_row, ..swap_row(rest, row_to_be_replaced, row)]
      }
    }
    [] -> panic as "We know that the row_to_be_replaced exists"
  }
}

fn find_first_row_without_zero_pivot(
  matrix: List(List(Float)),
) -> Result(List(Float), Nil) {
  case matrix {
    [first_row, ..rest] -> {
      case first_row {
        [0.0, ..] -> {
          find_first_row_without_zero_pivot(rest)
        }
        [_, ..] -> {
          Ok(first_row)
        }
        [] -> Error(Nil)
      }
    }
    [] -> Error(Nil)
  }
}

fn add_rows(row_a: List(Float), row_b: List(Float)) -> List(Float) {
  list.zip(row_a, row_b) |> list.map(fn(elements) { elements.0 +. elements.1 })
}

fn apply_row_scale(row: List(Float), scale: Float) -> List(Float) {
  row |> list.map(fn(element) { element *. scale })
}

fn discover_least_steps_to_match_joltage(machine: Machine) -> Int {
  let state = [BFSNode(machine.joltage, 0)]

  let zeroed = machine.joltage |> list.map(fn(_) { 0 })
  do_bfs(
    state,
    machine,
    dict.new(),
    fn(joltage) { list.any(joltage, fn(n) { n < 0 }) },
    apply_buttons_to_joltage,
    fn(joltage, _) { joltage == zeroed },
  )
}

fn discover_least_steps_to_match_lights(machine: Machine) -> Int {
  let state = [BFSNode(machine.lights |> list.map(fn(_) { Off }), 0)]
  do_bfs(
    state,
    machine,
    dict.new(),
    fn(_) { False },
    apply_buttons_to_light,
    fn(lights, machine) { lights == machine.lights },
  )
}

fn apply_buttons_to_joltage(button: Button, joltage: List(Int)) -> List(Int) {
  list.map_fold(joltage, 0, fn(acc, n) {
    case list.contains(button.number, acc) {
      True -> #(acc + 1, n - 1)
      False -> #(acc + 1, n)
    }
  }).1
}

fn do_bfs(
  state: List(BFSNode(a)),
  machine: Machine,
  checked_state: dict.Dict(#(a, Button), Bool),
  is_invalid_state: fn(a) -> Bool,
  generate_new_state: fn(Button, a) -> a,
  check_finished: fn(a, Machine) -> Bool,
) -> Int {
  case state {
    [head, ..rest] -> {
      let steps = head.steps + 1
      let #(checked_state, new_nodes) =
        list.map_fold(machine.buttons, checked_state, fn(checked_state, button) {
          case dict.get(checked_state, #(head.state, button)) {
            Ok(_) -> #(checked_state, Error(Nil))
            Error(_) -> {
              let new_state =
                BFSNode(generate_new_state(button, head.state), steps)
              case is_invalid_state(new_state.state) {
                True -> #(checked_state, Error(Nil))
                False -> #(
                  dict.insert(checked_state, #(head.state, button), True),
                  Ok(new_state),
                )
              }
            }
          }
        })
      let new_nodes = list.filter_map(new_nodes, fn(node) { node })
      case
        list.any(new_nodes, fn(node) { check_finished(node.state, machine) })
      {
        True -> steps
        False ->
          do_bfs(
            list.append(rest, new_nodes),
            machine,
            checked_state,
            is_invalid_state,
            generate_new_state,
            check_finished,
          )
      }
    }
    [] -> panic as "We checked all combinations without arriving to a solution"
  }
}

fn apply_buttons_to_light(button: Button, lights: List(Light)) -> List(Light) {
  list.map_fold(lights, 0, fn(acc, light) {
    case list.contains(button.number, acc) {
      True -> #(acc + 1, toggle_light(light))
      False -> #(acc + 1, light)
    }
  }).1
}

fn toggle_light(light: Light) -> Light {
  case light {
    On -> Off
    Off -> On
  }
}

fn parse_machines(contents: String) -> Result(List(Machine), String) {
  string.split(contents, "\n")
  |> list.filter(utils.not_empty)
  |> list.try_map(parse_machine)
}

fn parse_machine(line: String) -> Result(Machine, String) {
  let assert Ok(#(lights_part, rest)) = string.split_once(line, "] ")
  let assert Ok(#(buttons_part, joltage_part)) = string.split_once(rest, " {")
  use lights <- result.try(parse_lights(lights_part))
  use buttons <- result.try(parse_buttons(buttons_part))
  use joltage <- result.try(parse_joltage(joltage_part))
  Ok(Machine(lights, buttons, joltage))
}

fn parse_lights(lights_part: String) -> Result(List(Light), String) {
  string.replace(lights_part, "[", "")
  |> string.to_graphemes()
  |> list.try_map(fn(char) {
    case char {
      "." -> Ok(Off)
      "#" -> Ok(On)
      _ -> Error("Invalid light " <> char)
    }
  })
}

fn parse_buttons(buttons_part: String) -> Result(List(Button), String) {
  string.split(buttons_part, " ")
  |> list.map(fn(part) {
    string.replace(part, "(", "") |> string.replace(")", "")
  })
  |> list.try_map(fn(part) {
    string.split(part, ",")
    |> list.try_map(fn(n) {
      int.parse(n) |> result.replace_error("Failed to parse number " <> n)
    })
    |> result.map(fn(numbers) { Button(numbers) })
  })
}

fn parse_joltage(joltage_part: String) -> Result(List(Int), String) {
  string.replace(joltage_part, "}", "")
  |> string.split(",")
  |> list.try_map(fn(n) {
    int.parse(n) |> result.replace_error("Error parsing number " <> n)
  })
}

type BFSNode(a) {
  BFSNode(state: a, steps: Int)
}

type Machine {
  Machine(lights: List(Light), buttons: List(Button), joltage: List(Int))
}

type Light {
  On
  Off
}

type Button {
  Button(number: List(Int))
}
