import argv
import day1
import day10
import day11
import day2
import day3
import day4
import day5
import day6
import day7
import day8
import day9
import gleam/io

pub fn main() -> Nil {
  case
    case argv.load().arguments {
      ["1"] -> day1.execute()
      ["2"] -> day2.execute()
      ["3"] -> day3.execute()
      ["4"] -> day4.execute()
      ["5"] -> day5.execute()
      ["6"] -> day6.execute()
      ["7"] -> day7.execute()
      ["8"] -> day8.execute()
      ["9"] -> day9.execute()
      ["10"] -> day10.execute()
      ["11"] -> day11.execute()
      _ -> Ok(io.println("You need to pass the day to run"))
    }
  {
    Ok(_) -> Nil
    Error(err) -> io.println("Error: " <> err)
  }
}
