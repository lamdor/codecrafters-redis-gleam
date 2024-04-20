import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string

pub type Command {
  Ping
  Echo(string: String)
  Set(key: String, value: String, expiration_in_ms: Option(Int))
  Get(key: String)
}

pub fn from_string_list(list: List(String)) -> Result(Command, Nil) {
  use command <- result.try(list.first(list))
  case string.lowercase(command) {
    "ping" -> Ok(Ping)
    "echo" -> second_item_map(list, Echo)
    "set" -> to_set(list)
    "get" -> second_item_map(list, Get)
    _ -> Error(Nil)
  }
}

fn second_item_map(list: List(String), f: fn(String) -> a) -> Result(a, Nil) {
  use second <- result.map(list.at(list, 1))
  f(second)
}

fn to_set(list: List(String)) -> Result(Command, Nil) {
  use key <- result.try(list.at(list, 1))
  use value <- result.map(list.at(list, 2))
  let #(_, rest) = list.split(list, 3)
  let maybe_px_option =
    find_px_option(rest, "px")
    |> maybe_parse_int

  Set(key, value, maybe_px_option)
}

fn find_px_option(list: List(String), option: String) -> Option(String) {
  case list {
    [first, second, ..rest] ->
      case string.lowercase(first) == string.lowercase(option) {
        True -> Some(second)
        False -> find_px_option(rest, option)
      }
    _ -> None
  }
}

fn maybe_parse_int(a: Option(String)) -> Option(Int) {
  option.then(a, fn(v) { option.from_result(int.parse(v)) })
}
