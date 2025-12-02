import argv
import day1
import day2
import gleam/io

pub fn main() -> Nil {
  case
    case argv.load().arguments {
      ["1"] -> day1.day1()
      ["2"] -> day2.day2()
      _ -> Ok(io.println("You need to pass the day to run"))
    }
  {
    Ok(_) -> Nil
    Error(err) -> io.println("Error: " <> err)
  }
}
