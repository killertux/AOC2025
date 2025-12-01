import argv
import day1
import gleam/io

pub fn main() -> Nil {
  case
    case argv.load().arguments {
      ["1"] -> day1.day1()
      _ -> Ok(io.println("You need to pass the day to run"))
    }
  {
    Ok(_) -> Nil
    Error(err) -> io.println("Error: " <> err)
  }
}
