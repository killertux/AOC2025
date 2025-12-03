import argv
import day1
import day2
import day3
import gleam/io

pub fn main() -> Nil {
  case
    case argv.load().arguments {
      ["1"] -> day1.execute()
      ["2"] -> day2.execute()
      ["3"] -> day3.execute()
      _ -> Ok(io.println("You need to pass the day to run"))
    }
  {
    Ok(_) -> Nil
    Error(err) -> io.println("Error: " <> err)
  }
}
