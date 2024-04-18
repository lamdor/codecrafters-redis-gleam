pub type Command {
  Ping
  Echo(string: String)
}

pub fn from_string_list(list: List(String)) -> Result(Command, Nil) {
  case list {
    ["ping"] -> Ok(Ping)
    ["echo", str] -> Ok(Echo(str))
    _ -> Error(Nil)
  }
}
