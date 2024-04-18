import gleam/string
import gleam/list
import gleam/result

pub type Command {
  Ping
  Echo(string: String)
  Set(key: String, value: String)
  Get(key: String)
}

pub fn from_string_list(list: List(String)) -> Result(Command, Nil) {
  use command <- result.try(list.first(list))
  case string.lowercase(command) {
    "ping" -> Ok(Ping)
    "echo" -> second_item_map(list, Echo)
    "set" -> second_third_item_map(list, Set)
    "get" -> second_item_map(list, Get)
    _ -> Error(Nil)
  }
}

fn second_item_map(list: List(String), f: fn(String) -> a) -> Result(a, Nil) {
  use second <- result.map(list.at(list, 1))
  f(second)
}

fn second_third_item_map(
  list: List(String),
  f: fn(String, String) -> a,
) -> Result(a, Nil) {
  use second <- result.try(list.at(list, 1))
  use third <- result.map(list.at(list, 2))
  f(second, third)
}
