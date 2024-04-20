import gleam/option.{None, Some}
import redis/commands
import gleeunit/should

pub fn from_string_list_test() {
  // ping
  should.equal(commands.from_string_list(["ping"]), Ok(commands.Ping))
  should.equal(commands.from_string_list(["PING"]), Ok(commands.Ping))

  // echo
  should.equal(
    commands.from_string_list(["echo", "foo"]),
    Ok(commands.Echo("foo")),
  )

  // set
  should.equal(
    commands.from_string_list(["set", "foo", "bar"]),
    Ok(commands.Set("foo", "bar", None)),
  )
  should.equal(
    commands.from_string_list(["set", "foo", "bar", "px", "100"]),
    Ok(commands.Set("foo", "bar", Some(100))),
  )
  should.equal(
    commands.from_string_list(["set", "foo", "bar", "PX", "100"]),
    Ok(commands.Set("foo", "bar", Some(100))),
  )

  // get
  should.equal(
    commands.from_string_list(["get", "foo"]),
    Ok(commands.Get("foo")),
  )
}
