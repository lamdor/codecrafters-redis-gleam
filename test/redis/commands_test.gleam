import redis/commands

pub fn from_string_list_test() {
  let assert Ok(commands.Ping) = commands.from_string_list(["ping"])
  let assert Ok(commands.Ping) = commands.from_string_list(["PING"])
  let assert Ok(commands.Echo("foo")) =
    commands.from_string_list(["echo", "foo"])
}
