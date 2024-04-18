import redis/commands

pub fn from_string_list_test() {
  let assert Ok(commands.Ping) = commands.from_string_list(["ping"])
  let assert Ok(commands.Ping) = commands.from_string_list(["PING"])
  let assert Ok(commands.Echo("foo")) =
    commands.from_string_list(["echo", "foo"])
  let assert Ok(commands.Set("foo", "bar")) =
    commands.from_string_list(["set", "foo", "bar"])
  let assert Ok(commands.Get("foo")) = commands.from_string_list(["get", "foo"])
}
