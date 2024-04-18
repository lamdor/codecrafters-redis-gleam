import gleam/erlang/process.{type Subject}
import gleam/otp/actor
import gleam/dict.{type Dict}
import gleam/option.{type Option}

pub type Message {
  Set(key: String, value: String, reply: Subject(Acknowledged))
  Get(key: String, reply: Subject(Value))
}

pub type Acknowledged {
  Acknowledged
}

pub type Value {
  Value(Option(String))
}

type State =
  Dict(String, String)

fn loop(msg: Message, db: State) -> actor.Next(Message, State) {
  case msg {
    Set(k, v, r) -> {
      let db = dict.insert(db, k, v)
      process.send(r, Acknowledged)
      actor.continue(db)
    }
    Get(k, r) -> {
      let v =
        dict.get(db, k)
        |> option.from_result
        |> Value
      process.send(r, v)
      actor.continue(db)
    }
  }
}

pub fn start() -> process.Subject(Message) {
  let assert Ok(subj) = actor.start(dict.new(), loop)
  subj
}
