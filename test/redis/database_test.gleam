import gleam/erlang/process
import gleam/option.{None, Some}
import gleeunit/should
import redis/commands
import redis/database

pub fn set_get_test() {
  let db = database.start()

  let ack = process.new_subject()
  process.send(db, database.Set(commands.Set("foo", "bar", None), ack))
  let assert Ok(database.AcknowledgedReply) = process.receive(ack, 1000)

  let val = process.new_subject()
  process.send(db, database.Get(commands.Get("foo"), val))
  should.equal(
    process.receive(val, 1000),
    Ok(database.ValueReply(option.Some("bar"))),
  )
}

pub fn get_no_value_test() {
  let db = database.start()

  let val = process.new_subject()
  process.send(db, database.Get(commands.Get("foo"), val))
  should.equal(process.receive(val, 1000), Ok(database.ValueReply(None)))
}

pub fn set_with_expiration_get_test() {
  let db = database.start()

  let ack = process.new_subject()
  process.send(db, database.Set(commands.Set("foo", "bar", Some(10)), ack))
  let assert Ok(database.AcknowledgedReply) = process.receive(ack, 1000)

  process.sleep(50)

  let val = process.new_subject()
  process.send(db, database.Get(commands.Get("foo"), val))
  should.equal(process.receive(val, 1000), Ok(database.ValueReply(None)))
}
