import gleam/erlang
import gleam/erlang/process.{type Subject}
import gleam/otp/actor
import gleam/dict.{type Dict}
import gleam/option.{type Option, None, Some}
import redis/commands

pub type Message {
  Set(cmd: commands.Command, reply: Subject(AcknowledgedReply))
  Get(cmd: commands.Command, reply: Subject(ValueReply))
}

pub type AcknowledgedReply {
  AcknowledgedReply
}

pub type ValueReply {
  ValueReply(Option(String))
}

type Value {
  Value(val: String, expiration: Option(Int))
}

type State =
  Dict(String, Value)

fn loop(msg: Message, db: State) -> actor.Next(Message, State) {
  case msg {
    Set(commands.Set(k, v, e), r) -> {
      let expiration = add_expiration_time(e)
      let db = dict.insert(db, k, Value(v, expiration))
      process.send(r, AcknowledgedReply)
      actor.continue(db)
    }
    Get(commands.Get(k), r) -> {
      let v =
        dict.get(db, k)
        |> option.from_result
        |> filter_expired_value
        |> ValueReply
      process.send(r, v)
      actor.continue(db)
    }
    _ ->
      // should it crash? or just ignore invalid commands
      actor.continue(db)
  }
}

fn filter_expired_value(v: Option(Value)) -> Option(String) {
  case v {
    Some(Value(v, None)) -> Some(v)
    Some(Value(v, Some(e))) ->
      case e > system_time_ms() {
        True -> Some(v)
        False -> None
      }
    None -> None
  }
}

fn add_expiration_time(e: Option(Int)) -> Option(Int) {
  option.map(e, fn(e) { e + system_time_ms() })
}

fn system_time_ms() -> Int {
  erlang.system_time(erlang.Millisecond)
}

pub fn start() -> process.Subject(Message) {
  let assert Ok(subj) = actor.start(dict.new(), loop)
  subj
}
