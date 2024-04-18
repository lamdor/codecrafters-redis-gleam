import gleam/string
import gleam/list
import gleam/result

pub type Command {
  Ping
  Echo(string: String)
}

pub fn from_string_list(list: List(String)) -> Result(Command, Nil) {
  use command <- result.try(list.first(list))
  case string.lowercase(command) {
    "ping" -> Ok(Ping)
    "echo" -> second_item_map(list, Echo)
    _ -> Error(Nil)
  }
}

fn second_item_map(list: List(String), f: fn(String) -> a) -> Result(a, Nil) {
  result.map(result.try(list.rest(list), list.first), f)
}
