import gleam/erlang/process
import gleam/option.{None}
import redis/commands
import redis/database

pub fn set_get_test() {
  let ack = process.new_subject()
  let db = database.start()
  process.send(db, database.Set(commands.Set("foo", "bar", None), ack))
  let assert Ok(database.Acknowledged) = process.receive(ack, 1000)

  let val = process.new_subject()
  process.send(db, database.Get(commands.Get("foo"), val))
  let assert Ok(database.Value(option.Some("bar"))) = process.receive(val, 1000)
}
