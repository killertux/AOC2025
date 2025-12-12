import gleam/dict
import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import simplifile
import utils

pub fn execute() -> Result(Nil, String) {
  io.println("Day 11")
  result.all([
    day_part1("inputs/day11/example1.txt"),
    day_part1("inputs/day11/input1.txt"),
    day_part2("inputs/day11/example2.txt"),
    day_part2("inputs/day11/input1.txt"),
  ])
  |> result.map(fn(_) { Nil })
}

fn day_part1(file_path: String) -> Result(Nil, String) {
  use contents <- result.try(
    simplifile.read(file_path) |> result.replace_error("Error reading file"),
  )
  use devices <- result.try(parse_devices(contents))
  find_n_paths(devices) |> int.to_string |> io.println
  Ok(Nil)
}

fn day_part2(file_path: String) -> Result(Nil, String) {
  use contents <- result.try(
    simplifile.read(file_path) |> result.replace_error("Error reading file"),
  )
  use devices <- result.try(parse_devices(contents))
  find_n_paths_from_svr(devices) |> int.to_string |> io.println
  Ok(Nil)
}

fn find_n_paths(devices: dict.Dict(String, List(String))) -> Int {
  loop_find_n_paths("you", "out", devices, dict.new()).1
}

fn loop_find_n_paths_with_fft_and_dac(
  pos: String,
  end: String,
  devices: dict.Dict(String, List(String)),
  memoization: dict.Dict(String, #(Int, Int, Int, Int)),
) -> #(dict.Dict(String, #(Int, Int, Int, Int)), #(Int, Int, Int, Int)) {
  case dict.get(memoization, pos) {
    Ok(n) -> #(memoization, n)

    Error(_) -> {
      case dict.get(devices, pos) {
        Error(_) -> {
          #(memoization, #(0, 0, 0, 0))
        }
        Ok(outputs) -> {
          case outputs |> list.first() {
            Ok(value) -> {
              case value == end {
                True -> {
                  #(dict.insert(memoization, pos, #(1, 0, 0, 0)), #(1, 0, 0, 0))
                }
                False -> {
                  let paths =
                    outputs
                    |> list.map_fold(memoization, fn(memoization, output) {
                      loop_find_n_paths_with_fft_and_dac(
                        output,
                        end,
                        devices,
                        memoization,
                      )
                    })
                  let n_paths =
                    list.fold(paths.1, #(0, 0, 0, 0), fn(acc, n) {
                      let count = acc.0 + n.0
                      let count_fft = acc.1 + n.1
                      let count_dac = acc.2 + n.2

                      case pos {
                        "fft" -> {
                          #(
                            count,
                            acc.1 + n.0,
                            count_dac,
                            count_dac + count - acc.1 - n.0,
                          )
                        }
                        "dac" -> {
                          #(
                            count,
                            count_fft,
                            acc.2 + n.0,
                            count_fft + count - acc.2 - n.0,
                          )
                        }
                        _ -> {
                          #(acc.0 + n.0, acc.1 + n.1, acc.2 + n.2, acc.3 + n.3)
                        }
                      }
                    })

                  let memoization = dict.insert(paths.0, pos, n_paths)
                  #(memoization, n_paths)
                }
              }
            }
            Error(_) -> #(memoization, #(0, 0, 0, 0))
          }
        }
      }
    }
  }
}

fn loop_find_n_paths(
  pos: String,
  end: String,
  devices: dict.Dict(String, List(String)),
  memoization: dict.Dict(String, Int),
) -> #(dict.Dict(String, Int), Int) {
  case dict.get(memoization, pos) {
    Ok(n) -> #(memoization, n)

    Error(_) -> {
      case dict.get(devices, pos) {
        Error(_) -> {
          #(memoization, 0)
        }
        Ok(outputs) -> {
          case outputs |> list.first() {
            Ok(value) -> {
              case value == end {
                True -> {
                  #(dict.insert(memoization, pos, 1), 1)
                }
                False -> {
                  let paths =
                    outputs
                    |> list.map_fold(memoization, fn(memoization, output) {
                      loop_find_n_paths(output, end, devices, memoization)
                    })
                  let n_paths = list.fold(paths.1, 0, fn(acc, n) { acc + n })

                  let memoization = dict.insert(paths.0, pos, n_paths)
                  #(memoization, n_paths)
                }
              }
            }
            Error(_) -> #(memoization, 0)
          }
        }
      }
    }
  }
}

fn find_n_paths_from_svr(devices: dict.Dict(String, List(String))) -> Int {
  loop_find_n_paths_with_fft_and_dac("svr", "out", devices, dict.new()).1.3
}

fn parse_devices(
  contents: String,
) -> Result(dict.Dict(String, List(String)), String) {
  use devices <- result.try(
    contents
    |> string.split("\n")
    |> list.filter(utils.not_empty)
    |> list.try_map(parse_device),
  )
  Ok(dict.from_list(devices))
}

fn parse_device(line: String) -> Result(#(String, List(String)), String) {
  use #(name, outputs) <- result.try(
    string.split_once(line, ": ")
    |> result.replace_error("Invalid line " <> line),
  )

  Ok(#(name, outputs |> string.split(" ")))
}
