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
  io.println("Day 8")
  result.all([
    day_part1("inputs/day8/example1.txt", 10),
    day_part1("inputs/day8/input1.txt", 1000),
    day_part2("inputs/day8/example1.txt"),
    day_part2("inputs/day8/input1.txt"),
  ])
  |> result.map(fn(_) { Nil })
}

fn day_part1(file_path: String, n: Int) -> Result(Nil, String) {
  use contents <- result.try(
    simplifile.read(file_path) |> result.replace_error("Error reading file"),
  )
  use junction_boxes <- result.try(parse_junction_boxes(contents))
  let distances = calculate_distances(junction_boxes)
  let connections =
    distances
    |> list.take(n)
    |> list.fold(dict.new(), fn(acc, pair) {
      dict.upsert(acc, pair.1, fn(existing) {
        case existing {
          option.Some(value) -> [pair.2, ..value]
          option.None -> [pair.2]
        }
      })
      |> dict.upsert(pair.2, fn(existing) {
        case existing {
          option.Some(value) -> [pair.1, ..value]
          option.None -> [pair.1]
        }
      })
    })

  calculate_circuit_size(connections)
  |> list.sort(fn(a, b) { int.compare(b, a) })
  |> list.take(3)
  |> list.fold(1, fn(acc, n) { acc * n })
  |> int.to_string
  |> io.println
  Ok(Nil)
}

fn day_part2(file_path: String) -> Result(Nil, String) {
  use contents <- result.try(
    simplifile.read(file_path) |> result.replace_error("Error reading file"),
  )
  use junction_boxes <- result.try(parse_junction_boxes(contents))
  let distances = calculate_distances(junction_boxes)
  let #(a, b) =
    get_last_connection(distances, dict.new(), list.length(junction_boxes))

  io.println(int.to_string(a.x * b.x))
  Ok(Nil)
}

fn get_last_connection(
  distances: List(#(Float, JunctionBox, JunctionBox)),
  visited: dict.Dict(JunctionBox, Bool),
  n_junctions: Int,
) -> #(JunctionBox, JunctionBox) {
  case distances {
    [head, ..rest] -> {
      let visited = dict.insert(visited, head.1, True)
      let visited = dict.insert(visited, head.2, True)
      case dict.keys(visited) |> list.length == n_junctions {
        True -> #(head.1, head.2)
        False -> {
          get_last_connection(rest, visited, n_junctions)
        }
      }
    }
    [] -> panic as "Connected everything to everything"
  }
}

fn calculate_distances(
  junction_boxes: List(JunctionBox),
) -> List(#(Float, JunctionBox, JunctionBox)) {
  list.combination_pairs(junction_boxes)
  |> list.map(fn(pair) { #(calculate_distance(pair.0, pair.1), pair.0, pair.1) })
  |> list.sort(fn(a, b) { float.compare(a.0, b.0) })
}

fn calculate_distance(
  junction_box_1: JunctionBox,
  junction_box_2: JunctionBox,
) -> Float {
  let delta =
    result.unwrap(int.power(junction_box_2.x - junction_box_1.x, 2.0), 0.0)
    +. result.unwrap(int.power(junction_box_2.y - junction_box_1.y, 2.0), 0.0)
    +. result.unwrap(int.power(junction_box_2.z - junction_box_1.z, 2.0), 0.0)

  result.unwrap(float.square_root(delta), 0.0)
}

fn calculate_circuit_size(
  connections: dict.Dict(JunctionBox, List(JunctionBox)),
) -> List(Int) {
  get_all_circuits(connections).0
  |> list.map(fn(circuit) { list.length(circuit) })
}

fn get_all_circuits(
  connections: dict.Dict(JunctionBox, List(JunctionBox)),
) -> #(List(List(JunctionBox)), dict.Dict(JunctionBox, List(JunctionBox))) {
  case dict.keys(connections) {
    [head, ..] -> {
      let circuit = get_circuit(head, connections, dict.new())
      let connections =
        list.fold(circuit, connections, fn(connections, junction_box) {
          dict.delete(connections, junction_box)
        })
      let all_circuits = get_all_circuits(connections)
      #([circuit, ..all_circuits.0], all_circuits.1)
    }
    [] -> #([], connections)
  }
}

fn get_circuit(
  head: JunctionBox,
  connections: dict.Dict(JunctionBox, List(JunctionBox)),
  visited: dict.Dict(JunctionBox, Bool),
) -> List(JunctionBox) {
  case dict.get(visited, head) {
    Ok(_) -> []
    Error(_) -> {
      case dict.get(connections, head) {
        Ok(junction_boxes) -> {
          let visited = dict.insert(visited, head, True)
          [
            head,
            ..list.flat_map(junction_boxes, fn(junction_box) {
              get_circuit(junction_box, connections, visited)
            })
          ]
          |> list.unique
        }
        Error(_) -> []
      }
    }
  }
}

fn parse_junction_boxes(contents: String) -> Result(List(JunctionBox), String) {
  string.split(contents, "\n")
  |> list.filter(utils.not_empty)
  |> list.try_map(parse_junction_box)
}

fn parse_junction_box(line: String) -> Result(JunctionBox, String) {
  case string.split(line, ",") {
    [x, y, z] -> {
      use x <- result.try(int.parse(x) |> result.replace_error("Invalid X pos"))
      use y <- result.try(int.parse(y) |> result.replace_error("Invalid Y pos"))
      use z <- result.try(int.parse(z) |> result.replace_error("Invalid Z pos"))
      Ok(JunctionBox(x, y, z))
    }
    _ -> Error("Invalid line " <> line)
  }
}

type JunctionBox {
  JunctionBox(x: Int, y: Int, z: Int)
}
