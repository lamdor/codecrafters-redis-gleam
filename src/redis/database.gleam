import gleam/erlang/process.{type Subject}
import gleam/otp/actor
import gleam/dict.{type Dict}
import gleam/option.{type Option}
import redis/commands

pub type Message {
  Set(cmd: commands.Command, reply: Subject(Acknowledged))
  Get(cmd: commands.Command, reply: Subject(Value))
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
    Set(commands.Set(k, v, _), r) -> {
      let db = dict.insert(db, k, v)
      process.send(r, Acknowledged)
      actor.continue(db)
    }
    Get(commands.Get(k), r) -> {
      let v =
        dict.get(db, k)
        |> option.from_result
        |> Value
      process.send(r, v)
      actor.continue(db)
    }
    _ ->
      // should it crash? or just ignore invalid commands
      actor.continue(db)
  }
}

pub fn start() -> process.Subject(Message) {
  let assert Ok(subj) = actor.start(dict.new(), loop)
  subj
}
